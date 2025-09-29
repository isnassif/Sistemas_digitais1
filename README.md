# Problema 1 – Zoom Digital: Redimensionamento de Imagens com FPGA em Verilog

<h2>Descrição do Projeto</h2>
<p>
Esse projeto tem o objetivo de implementar um coprocessador gráfico para realizar, em tempo real, redimensionamento de imagens gerando sobre elas efeitos de Zoom-In e Zoom-Out. Esse processo foi feito utilizando o kit de desenvolvimento DE1-SoC, que contém um coprocessador Cyclone V. O sistema aplica técnicas que buscam variar o dimensionamento de imagens em escala de cinza, com representação de pixels em 8 bits, e exibe o resultado via saída VGA. O ambiente de desenvolvimento utilizado foi o Intel Quartus Prime Lite 23.1, e a linguagem de descrição de hardware usada foi o Verilog.



O coprocessador gráfico conseguiu fazer o redimensionamento de imagens a partir dos seguintes algoritmos:
a) Replicação de pixel(Zoom-In)
b) Vizinho mais próximo(Zoom-In)
c) Decimação(Zoom-Out)
d) Média de blocos(Zoom-Out)
Vale lembrar que esses algoritmos devem garantir que o redimensionamento da imagem possa ocorrer em 2x.




<h2 id="arquitetura">Arquitetura e Caminho de Dados</h2>

<p>
    O sistema segue o princípio de <strong>separação de funções</strong>, dividindo o design em <strong>Unidade de Controle</strong> (Control Path) e <strong>Datapath</strong>. Essa abordagem modular facilita a validação isolada de cada componente e permite que ferramentas de síntese otimizem cada parte de forma eficiente. Nesse tópico será abordada a arquitetura adotada no desenvolvimento do protótipo.
</p>

<h3>Componentes Principais</h3>
<ul>
    <li>
        <strong>Unidade de Controle (<code>rom_to_ram</code>)</strong>:  
        FSM hierárquica que gerencia o fluxo do sistema. Com base nas entradas do usuário e nos sinais de status (<code>done</code>) dos submódulos, gera sinais de controle para ativar aceleradores de hardware, gerar endereços para a ROM e controlar escrita no Framebuffer.
    </li>
    <li>
        <strong>Framebuffer (RAM Dual-Port)</strong>:  
        Permite que processamento e exibição de vídeo ocorram de forma independente. Uma porta é usada para escrita pelo Datapath e outra para leitura pelo driver VGA, garantindo operação contínua a 25 MHz sem conflitos.
    </li>
    <li>
        <strong>Memória ROM</strong>:  
        Armazena a imagem original de 160x120 pixels em escala de cinza. A Unidade de Controle lê os pixels sequencialmente e fornece aos módulos de algoritmo para processamento.
    </li>
    <li>
        <strong>Módulos de Algoritmo</strong>:  
        Circuits dedicados (<code>rep_pixel</code>, <code>copia_direta</code>, <code>zoom</code>, <code>media_blocos</code>) que processam pixels de forma paralela e otimizada. Alguns módulos operam em um ciclo, enquanto outros têm FSM interna para cálculos mais complexos, garantido mais eficiência na execução das operações.
    </li>
</ul>

<h3>Datapath e Fluxo de Execução</h3>
<ol>
    <li>
        <strong>Sequência de Leitura, Processamento e Escrita</strong>
        <ul>
            <li>No estado <code>ST_RESET</code>, a Unidade de Controle lê a seleção do usuário e configura o Datapath.</li>
            <li>A FSM transita pelos estados operacionais, lendo pixels da ROM, enviando-os ao acelerador de hardware e escrevendo os resultados no Framebuffer.</li>
            <li>Cada módulo de algoritmo processa os dados com máxima eficiência, garantindo alta performance mesmo em operações complexas.</li>
        </ul>
    </li>
    <li>
        <strong>Exibição Paralela e Contínua</strong>
        <ul>
            <li>O driver VGA lê continuamente o Framebuffer pela porta de leitura, exibindo pixels a 25 MHz.</li>
            <li>O uso da RAM de porta dupla garante que o processamento de uma nova imagem ocorra em paralelo à exibição da imagem anterior, sem interrupções.</li>
        </ul>
    </li>
</ol>

<h3>Visão Geral do Fluxo</h3>
<p>
    O diagrama abaixo ilustra a interação entre a Unidade de Controle (<code>rom_to_ram</code>), os módulos de algoritmo, as memórias (ROM e Framebuffer) e o driver VGA, mostrando o caminho de dados e o fluxo de execução do sistema.
</p>

  ![Diagrama da Arquitetura Geral](diagramas/arquiteturageral.png)


<h2 id="control">Unidade de Controle</h2>
<p>
A Unidade de Controle, é implementada no módulo control_unity e funciona como o elemento principal do projeto, ela é responsável por coordenar todo o fluxo do sistema, começando pela instanciação de todos os componentes principais, como as memórias ROM e RAM e a ALU, coordenação e geração do clock utilizado, sincronismo das chaves utilizadas, ativação dos algoritmos de redimensionamento e escrita ordenada no Framebuffer, com um resultado final exibido pelo driver VGA, a seguir, será explicado de forma detalhada e minunciosa o funcionamento de cada um dos componentes do módulo.
</p>

<h3>Funções Principais</h3>
<ul>
  <li><strong>Geração e Distribuição de Clocks:</strong>  
      Através da ferramente "IP catalog", disponível na IDE Quartus (utiliada para o desenvolvimento do projeto), foi criado um PLL para fornecer um clock estável aos blocos de memória, o que fornece uma valor preciso para os módulos principais.</li>
  <li><strong>Sincronização de Entradas:</strong>  
      As chaves sw são sincronizadas em registradores para evitar metastabilidade. Esses sinais determinam o modo de operação (replicação, decimação, zoom por vizinho mais próximo ou cópia direta).</li>
  <li><strong>Centralização e Endereçamento:</strong>  
      Calcula dinamicamente x_offset e y_offset, sinais do vga_driver, para centralizar a imagem na tela de 640×480, utilizada para desenvolvimento do projeto, esses sinais, geram o endereço do Framebuffer para cada pixel válido.</li>
  <li><strong>Controle da FSM:</strong>  
      A FSM do módulo de controle coordena a leitura de pixels da ROM, aciona o módulo de algoritmo selecionado e controla os sinais de escrita na RAM, permitindo com que o projeto funcione da melhor forma.</li>
</ul>

<h3>Fluxo Operacional</h3>
<p>
    Nessa seção, falaremos sobre toda a parte operacional do funcionamento da Unidade de Controle, que segue uma sequência bem definida de etapas. Inicialmente, assim que o sinal vga_reset é acionado, o sistema entra no estado de RESET. Nesse momento, são realizados os ajustes iniciais, incluindo a configuração dos fatores de escala de acordo com a opção escolhida pelo usuário por meio das chaves de entrada. Com a configuração concluída, o sistema passa para a fase de leitura sequencial da ROM. Aqui, o endereço rom_addr é continuamente incrementado, percorrendo toda a imagem original armazenada, que possui resolução de 160×120 pixels. Cada pixel lido é então encaminhado para o módulo de algoritmo responsável pelo redimensionamento.
</p>

<p>
    A etapa de redimensionamento é basicamente é o processamento do pixel pelo algoritmo selecionado, vale ressaltar que a escolha do modo de operação depende do código de controle gerado a partir das chaves. Assim, o pixel pode ser replicado, reduzido, interpolado ou simplesmente copiado de forma direta - Por exemplo, no modo de replicação ×2, cada pixel proveniente da ROM é expandido em quatro pixels consecutivos que serão gravados no framebuffer- Após o processamento, leitura e aplicação dos algoritmos, ocorre a escrita na RAM dual-port, que funciona como framebuffer. A posição de memória correta é calculada a partir do registrador de endereço addr_reg, levando em conta tanto a ampliação ou redução da imagem quanto os deslocamentos necessários para centralização. O sinal de controle ram_wren garante que a escrita ocorra apenas em ciclos válidos, evitando sobreposição ou perda de dados.
</p>

<p>
    A unidade de controle também controla o módulo vga_drive, que será explicado posteriormente. Esse fluxo coordenado garante que cada etapa — desde a leitura da ROM até a exibição final pelo VGA — seja sincronizada e controlada pela Unidade de Controle, assegurando o funcionamento estável do sistema.
</p>

<h2>Exemplo de Operação</h2>
<p>
    Para que o funcionamento fique ainda mais claro, vamos para um exemplo prático. Suponha que o usuário configure as chaves de entrada em 0000, selecionando o modo de replicação ×2. Se isso acontecer, a Unidade de Controle ajusta automaticamente os parâmetros de escala, definindo IMG_W_AMP = 320 e IMG_H_AMP = 240. Em seguida, são calculados os deslocamentos x_offset = 160 e y_offset = 120, garantindo que a imagem seja centralizada na resolução de saída de 640×480. Durante o processamento, cada pixel lido da ROM é replicado em quatro posições consecutivas da RAM, produzindo uma imagem ampliada sem perda de continuidade. O driver VGA, por sua vez, lê esses dados do framebuffer e exibe na tela uma imagem com resolução de 320×240 pixels, devidamente posicionada no centro do display de 640×480.
</p>




<div>
  <h2 id="ula">Unidade Lógica e Aritmética (ULA)</h2>
  <p>
    A ULA do coprocessador é a responsável por aplicar os algoritmos sobre a imagem, a partir da escolha feita no OpCode. Nesse tópico ocorrerá um aprofundamento acerca dos algoritmos os quais foram utilizados para resolução do projeto. 
  </p>
<div>
  <h2 id="ula">Algoritmos para redimensionamento de imagens</h2>
  <p>
    Os algoritmos para redimensionamento de imagens são o conjunto de técnicas utilizadas para alterar a dimensão da imagem em formato matricial, ou seja, pixels organizados em linhas e colunas.
</p>
<p>
    Cada pixel guarda a informação do nível de cinza em 8 bits e ao aplicar operações sobre eles podemos reduzir, ampliar ou transformar a imagem.
</p>
