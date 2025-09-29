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
    A arquitetura do sistema foi fundamentada no princípio de <strong>separação de funções</strong>, dividindo o design em uma <strong>Unidade de Controle</strong> (Control Path) e uma <strong>Unidade de Processamento de Dados</strong> (Datapath). Essa abordagem modular não só simplifica a validação de cada componente de forma isolada, mas também permite que as ferramentas de síntese (EDA Tools) otimizem cada parte de forma mais eficiente. Nesse tópico será abordada a arquitetura adotada no desenvolvimento do protótipo.
</p>

<h3>Componentes Principais e Princípios de Design</h3>
<ul>
    <li>
        <strong>Unidade de Controle (<code>rom_to_ram</code>):</strong> Implementada como uma Máquina de Estados Finitos (FSM) hierárquica, atua como o cérebro do sistema. Ela não processa os pixels diretamente; em vez disso, sua função é ditar o fluxo de execução. Com base na entrada do usuário e nos sinais de status (<code>done</code>) dos submódulos, a FSM transita entre estados (<code>ST_RESET</code>, <code>ST_REPLICACAO</code>, etc.). Em cada estado, ela gera os sinais de controle que:
        <ol>
            <li>Ativam o módulo de algoritmo (acelerador de hardware) apropriado.</li>
            <li>Geram os endereços para a memória ROM.</li>
            <li>Controlam os sinais de escrita (<code>wren</code>) e o endereço (<code>wr_addr</code>) para o Framebuffer.</li>
        </ol>
        Essa estrutura representa um design de controle síncrono clássico, onde o estado atual dita as ações do ciclo de clock corrente.
    </li>
    <li>
        <strong>Framebuffer (RAM Dual-Port):</strong>
  <p>
    Em sistemas que trabalham com vídeo em hardware, um desafio comum é como lidar com a diferença de ritmo entre quem gera os pixels e quem precisa exibi-los. O Framebuffer é a nossa solução para isso. Basicamente, funciona assim:
  </p>
  <ul>
    <li>
      <strong>Quem gera os pixels:</strong> É o módulo de controle (<code>rom_to_ram</code>), que processa e produz os pixels. Ele faz isso em um ritmo que varia bastante, às vezes mandando vários pixels de uma vez, às vezes esperando.
    </li>
    <li>
      <strong>Quem exibe os pixels:</strong> É o driver VGA. Ele precisa de um pixel a cada <code>40&nbsp;ns</code>, sem falha, numa taxa fixa de <code>25&nbsp;MHz</code>. Ele não espera.
    </li>
  </ul>
  <p>
    Se usássemos uma RAM comum (de porta única), o módulo de controle e o driver VGA iriam competir pelo acesso à memória. Para evitar essa disputa e garantir que o processamento e a exibição de vídeo ocorram de forma independente e sem problemas, usamos uma <strong>RAM de porta dupla (BRAM)</strong> na FPGA. Com duas portas separadas, uma para escrever e outra para ler, os dois conseguem trabalhar sem se atrapalhar.
  </p>
</li>
<li>
 <strong>Memória ROM:</strong>
 <p> A Memória ROM(Read-Only Memory) é responsável por armazenar a imagem orginal de 160x120 em escala de cinza de 8 bits. Ela funciona como a fonte de dados para todos os módulos de algoritmo. Os pixels são lidos sequencialmente, endereço por endereço, pela Unidade de Controle (`rom_to_ram`) e alimentados aos aceleradores de hardware para processamento. É crucial que o acesso à ROM seja rápido e que a latência de leitura (geralmente um ciclo de clock) seja considerada no design do Datapath para garantir o fluxo contínuo de dados.
</li>   </p>


 <li>
  <strong>Módulos de Algoritmo:</strong>
  <p>
    No "coração" do Datapath, cada módulo de algoritmo (como <code>rep_pixel</code>, <code>copia_direta</code>, <code>zoom</code> e <code>media_blocos</code>) atua como um <strong>acelerador de hardware dedicado</strong>. Esses módulos não são instruções de software, mas circuitos digitais customizados projetados para executar suas funções específicas com máxima eficiência.
  </p>
  <ul>
    <li>
      <strong>Execução paralela e otimizada:</strong> Cada módulo processa pixels ou blocos de pixels diretamente em hardware, explorando paralelismo e reduzindo a quantidade de ciclos necessária em comparação a uma CPU de propósito geral.
    </li>
    <li>
      <strong>Controle interno:</strong> Alguns módulos, como o <code>rep_pixel</code>, produzem resultados em um único ciclo. Outros, como o <code>media_blocos</code>, possuem sua própria FSM interna para sequenciar leituras, cálculos e escrita, levando múltiplos ciclos, mas ainda de forma altamente otimizada.
    </li>
  </ul>
  <p>
    Essa abordagem garante que operações mais complexas, como calcular a média de um bloco de pixels, sejam executadas com ordens de magnitude mais rapidez do que em software, mantendo o pipeline de processamento de vídeo contínuo e eficiente.
  </p>
</li>


<h3>Datapath e Fluxo de Execução</h3>
<p>
A interação entre a Unidade de Controle e o Datapath define o fluxo de execução do nosso coprocessador de imagem. Podemos descrever isso em duas partes principais: a <strong>sequência de operações</strong> para processar a imagem e o <strong>processo de exibição paralelo</strong>.
</p>
<ol>
<li>
<strong>Sequência de Leitura, Processamento e Escrita (Controlada pela FSM):</strong>
<ul>
<li><strong>Configuração:</strong> No estado <code>ST_RESET</code>, a Unidade de Controle (Control Path) lê a seleção do usuário e configura o Datapath, direcionando os sinais de controle e dados para o módulo de algoritmo correto (e seu fator específico).</li>
<li><strong>Ciclo Operacional:</strong> A FSM avança para um estado de operação. Para cada pixel ou bloco de pixels a ser processado:
<ul>
<li>A Unidade de Controle emite um <code>rom_addr</code>.</li>
<li>O <code>rom_data</code> correspondente é lido da ROM (com um ciclo de latência) e alimentado ao acelerador de hardware ativo (Datapath).</li>
<li>O acelerador processa o dado. Alguns módulos podem levar um ciclo (como <code>rep_pixel</code>), outros podem ter uma FSM interna e levar múltiplos ciclos (como <code>media_blocos</code> para processar um bloco completo).</li>
<li>O resultado (pixel processado) é então capturado pela Unidade de Controle, que emite os sinais <code>wr_addr</code>, <code>wr_data</code>, e <code>wren</code> para escrevê-lo no Framebuffer.</li>
</ul>
</li>
</ul>
Essa sequência se repete até que toda a imagem seja processada e escrita na RAM.
</li>
<li>
<strong>Exibição Paralela e Contínua (Desacoplamento por Framebuffer):</strong>
<ul>
<li>De forma <strong>completamente paralela e independente</strong> ao fluxo de processamento descrito acima, o Driver VGA (outro componente do Datapath) executa seu próprio ciclo de leitura.</li>
<li>Ele gera continuamente endereços para a segunda porta do Framebuffer e exibe os pixels lá armazenados. Essa operação é ininterrupta e ocorre a uma taxa fixa de 25 MHz.</li>
<li>Essa independência, garantida pelo Framebuffer de porta dupla, permite que o sistema processe uma nova imagem enquanto a imagem previamente processada continua sendo exibida,  garantindo uma saída de vídeo sem interrupções para o usuário.</li>
</ul>
</li>
</ol>

<h3>Visão Geral do Fluxo</h3>
<p>
O diagrama abaixo ilustra todo o fluxo descrito anteriormente, mostrando a interação entre a Unidade de Controle (<code>rom_to_ram</code>), os módulos de algoritmo, as memórias (ROM e Framebuffer) e o Driver VGA. Ele funciona como uma síntese gráfica da arquitetura e do caminho de dados apresentados.
</p>

  ![Diagrama da Arquitetura Geral](diagramas/arquiteturageral.png)





<div>
  <h2 id="ula">Unidade Lógica e Aritmética (ULA)</h2>
  <p>
    A ULA do coprocessador é a responsável por aplicar os algoritmos sobre a imagem, a partir da escolha feita no OpCode. Nesse tópico ocorrerá um aprofundamento acerca dos algoritmos os quais foram utilizados para resolução do projeto. 
  </p>

