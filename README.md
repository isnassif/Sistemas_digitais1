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
    A arquitetura do sistema foi fundamentada no princípio de <strong>separação de funções</strong>, dividindo o design em uma <strong>Unidade de Controle</strong> (Control Path) e uma <strong>Unidade de Processamento de Dados</strong> (Datapath). Essa abordagem modular não só simplifica a validação de cada componente de forma isolada, mas também permite que as ferramentas de síntese (EDA Tools) otimizem cada parte de forma mais eficiente. A coordenação global é realizada pela Unidade de Controle, que emite sinais para configurar o datapath e sequenciar as operações micro a micro.
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

  ![Diagrama da Arquitetura Geral](diagramas/arquiteturageral.png)



<div>
  <h2 id="ula">Unidade Lógica e Aritmética (ULA)</h2>
  <p>
    A ULA do coprocessador é a responsável por aplicar os algoritmos sobre a imagem, a partir da escolha feita no OpCode. Nesse tópico ocorrerá um aprofundamento acerca dos algoritmos os quais foram utilizados para resolução do projeto. 
  </p>

