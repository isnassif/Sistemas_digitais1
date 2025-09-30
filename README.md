# Problema 1 – Zoom Digital: Redimensionamento de Imagens com FPGA em Verilog

<h2>Descrição do Projeto</h2>
<p>
Esse projeto tem o objetivo de implementar um coprocessador gráfico para realizar, em tempo real, redimensionamento de imagens gerando sobre elas efeitos de Zoom-In e Zoom-Out. Esse processo foi feito utilizando o kit de desenvolvimento DE1-SoC, que contém um coprocessador Cyclone V. O sistema aplica técnicas que buscam variar o dimensionamento de imagens em escala de cinza, com representação de pixels em 8 bits, e exibe o resultado via saída VGA. O ambiente de desenvolvimento utilizado foi o Intel Quartus Prime Lite 23.1, e a linguagem de descrição de hardware usada foi o Verilog.

    


</p>
<p>O coprocessador gráfico conseguiu fazer o redimensionamento de imagens a partir dos seguintes algoritmos:</p>
<p>a) Replicação de pixel(Zoom-In)</p>
<p>b) Vizinho mais próximo(Zoom-In)</p>
<p>c) Decimação(Zoom-Out)</p>
<p>d) Média de blocos(Zoom-Out)</p>
<p>Vale lembrar que esses algoritmos devem garantir que o redimensionamento da imagem possa ocorrer em 2x.</p>

Sumário
=================
- [Arquitetura e Caminho de Dados](#arquitetura-e-caminho-de-dados)
- [DataPath e Fluxo de Execução](#datapath-e-fluxo-de-execução)
- [Unidade de Controle](#unidade-de-controle)
- [Módulo VGA](#módulo-vga)



## Arquitetura e Caminho de Dados

<p>
    O sistema segue o princípio de <strong>separação de funções</strong>, com uma hierarquia de controle clara e um <em>datapath</em> dedicado para as operações de imagem. O módulo de topo <code>control_unity</code> integra todos os componentes, enquanto a <code>ULA</code> atua como uma unidade de controle especializada, gerenciando o fluxo de dados entre as memórias e os aceleradores de hardware (módulos de algoritmo). Essa abordagem modular facilita a validação isolada de cada componente e permite que ferramentas de síntese otimizem cada parte de forma eficiente. Nesse tópico será abordada a arquitetura adotada no desenvolvimento do protótipo.
</p>

<h3>Componentes Principais</h3>
<ul>
    <li>
        <strong>ULA (<code>ULA</code>)</strong>:  
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
        <strong>Módulos dos Algoritmos</strong>:  
        Circuitos dedicados (<code>rep_pixel</code>, <code>copia_direta</code>, <code>zoom</code>, <code>media_blocos</code>) que processam pixels de forma paralela e otimizada. Alguns módulos operam em um ciclo, enquanto outros têm FSM interna para cálculos mais complexos, garantido mais eficiência na execução das operações.
    </li>
</ul>

## DataPath e fluxo de execução
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
O diagrama abaixo ilustra a arquitetura completa do sistema, orquestrada pelo módulo de topo <code>control_unity</code>. Ele detalha a interação entre a Unidade Lógica e Aritmética (<code>ULA</code>), responsável pelo processamento da imagem, as memórias on-chip (<code>ROM</code> de origem e <code>Framebuffer RAM</code> dual-port) e o <code>VGA Driver</code>, que gera o sinal de vídeo final para o monitor.
</p>

  ![Diagrama da Arquitetura Geral](diagramas/arquiteturgeral.png)


## Unidade de Controle
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
    Os algoritmos para redimensionamento de imagens são o conjunto de técnicas utilizadas para alterar a dimensão da imagem em formato matricial, ou seja, pixels organizados em linhas e colunas. Cada pixel armazena a informação do nível de cinza em 8 bits. Ao aplicar operações sobre esses pixels, é possível reduzir, ampliar ou transformar a imagem de acordo com a necessidade.

É importante destacar que a imagem original fica armazenada na ROM, garantindo que o processo de redimensionamento sempre parta da fonte original. A imagem resultante de cada operação é então gravada na RAM, preservando a saída final de cada algoritmo.

Os algoritmos recebem como parâmetro um valor chamado fator, que pode ser definido como 2 ou 4, dependendo do nível de redução ou ampliação desejado pelo usuário.
</p>
<h2>Replicação de pixel(Zoom-In)</h2>
<h3> <strong>Funcionamento geral</strong></h3>
<p>
    A replicação de pixel é um algoritmo de redimensionamento matricial que aumenta as dimensões da matriz. Quando aplicada a uma imagem (vista como uma matriz de pixels), o efeito é equivalente a um zoom-in. Na replicação de pixel criamos novos pixels a partir dos pixels já fornecidos, cada pixel é replicado neste método fator vezes linha e coluna, conseguindo dessa forma uma imagem ampliada. De maneira geral, essa operação de replicação é feita inicialmente de maneira horizontal(linhas replicadas) e depois verticalmente(colunas replicadas).
</p>
<h3> <strong>Código</strong></h3>
<p>
    No projeto, esse algoritmo é feito no módulo chamado <strong>rep_pixel</strong>. Para cada pixel lido da ROM, ele escreve o mesmo valor várias vezes na RAM, de acordo com o fator de ampliação. Importante ressaltar que essa replicação segue a lógica do algoritmo original, na qual as linhas são replicadas primeiro para depois ser a vez das colunas. O cálculo do endereço de saída da ROM para a RAM é:
</p>
<p>ram_wraddr = (linha * fator + di) * NEW_LARG + (coluna * fator + dj)</p>
<p>Assim, cada pixel é replicado <strong>fator x fator</strong> vezes, gerando uma imagem ampliada.</p>

<h2>Decimação(Zoom-Out)</h2>
<h3> <strong>Funcionamento geral</strong></h3>
<p>
    A decimação é um algoritmo de redimensionamento matricial que reduz as dimensões da matriz original. Quando aplicada a uma imagem (vista como uma matriz de pixels), o efeito é equivalente a um zoom-out. O princípio da decimação é o descarte de pixels. O algoritmo percorre a imagem, armazena um pixel de referência e, em seguida, só considera para armazenamento os pixels localizados a uma distância definida pelo <strong>fator</strong>, tanto no eixo horizontal quanto no vertical.
</p>
<p>
    Dessa forma, a imagem resultante possui uma resolução menor, mantendo apenas parte das informações da original. 
</p>
<h3> <strong>Código</strong></h3>
<p>
    No projeto, esse algoritmo é feito no módulo chamado <strong>decimacao</strong>. Esse módulo, quando acionado, percorre a matriz de pixels da ROM (imagem original) de fator em fator, salvando os pixels restantes em uma nova matriz (RAM). O cálculo do endereço de saída da ROM para a RAM é:
</p>
<p>addr_ram_vga = (y_in / fator) * NEW_LARG + (x_in / fator)</p>
<p>Assim, a saída gera uma imagem reduzida com dimensões: NEW_LARG x NEW_ALTURA.</p>


<h2>Média de blocos(Zoom-Out)</h2>
<h3> <strong>Funcionamento geral</strong></h3>
<p>
    A média de blocos é um algoritmo de redimensionamento matricial que reduz as dimensões da matriz original. Quando aplicada a uma imagem (vista como uma matriz de pixels), o efeito é equivalente a um zoom-out. Diferente da decimação, que apenas descarta pixels, a média de blocos divide a imagem em submatrizes de dimensão fator × fator. Para cada submatriz, o algoritmo calcula a média dos valores de seus elementos e substitui todo o bloco por um único pixel com esse valor médio.

Esse processo preserva melhor a informação visual da imagem original, já que considera todos os pixels do bloco ao invés de apenas alguns deles.
</p>
<h3> <strong>Código</strong></h3>
<p>
    No projeto, esse algoritmo é feito no módulo chamado <strong>med_blocos</strong>.Esse módulo percorre a matriz de pixels da ROM (imagem original) de fator em fator, salvando os pixels restantes em uma nova matriz (RAM). O cálculo do endereço de saída da ROM para a RAM é:
</p>
<p>addr_ram_vga = (y_in / fator) * NEW_LARG + (x_in / fator)</p>
<p>Assim, a saída gera uma imagem reduzida com dimensões: NEW_LARG x NEW_ALTURA.</p>



## Módulo VGA

<p>
    O <code>vga_driver</code> é responsável por exibir o framebuffer digital da FPGA no padrão VGA analógico. Ele gera quadros de 640x480 pixels a 60 Hz usando clock de 25 MHz, convertendo os valores de 8 bits do framebuffer para sinais RGB via DAC externo da DE1-SoC.
</p>

<h3>Temporização e Sincronismo</h3>
<p>A temporização VGA é implementada por contadores síncronos:</p>
<ul>
    <li><strong>Horizontal:</strong> <code>h_count</code> varre 0–799 pixels, incluindo área visível (640 pixels), front/back porch e pulso HSYNC.</li>
    <li><strong>Vertical:</strong> <code>v_count</code> varre 0–524 linhas, incluindo área visível (480 linhas), front/back porch e pulso VSYNC.</li>
</ul>

<h3>Escala, Centralização e Leitura do Framebuffer</h3>
<p>
    Para exibir a imagem processada (geralmente 160x120 pixels) em uma tela de 640x480 pixels, o <code>vga_driver</code> realiza:
</p>
<ul>
    <li>
        <strong>Cálculo da Escala (Zoom 4x):</strong> Cada pixel da imagem original gera 4x4 pixels na tela VGA, obtendo as coordenadas na imagem de 160x120 dividindo <code>h_count</code> e <code>v_count</code> da tela por 4.
    </li>
    <li>
        <strong>Centralização:</strong> A imagem resultante é centralizada se tiver dimensões menores que 640x480, calculando offsets para posicionamento adequado.
    </li>
    <li>
        <strong>Leitura e Exibição:</strong> Os contadores ajustados calculam o endereço linear do framebuffer. A Block RAM entrega o pixel (<code>color_in</code>) com 1 ciclo de latência. O pixel é enviado ao DAC e exibido. O <i>blanking</i> garante preto durante porches e pulsos de sincronismo, mantendo a saída contínua e correta.
    </li>
</ul>
