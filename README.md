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
    O sistema segue o princípio de <strong>separação de funções</strong>, dividindo o design em <strong>Unidade de Controle</strong> (Control Path) e <strong>Datapath</strong>. Essa abordagem modular facilita a validação isolada de cada componente e permite que ferramentas de síntese otimizem cada parte de forma eficiente.
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
        Circuits dedicados (<code>rep_pixel</code>, <code>copia_direta</code>, <code>zoom</code>, <code>media_blocos</code>) que processam pixels de forma paralela e otimizada. Alguns módulos operam em um ciclo, enquanto outros têm FSM interna para cálculos mais complexos, mantendo o pipeline contínuo e eficiente.
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





<div>
  <h2 id="ula">Unidade Lógica e Aritmética (ULA)</h2>
  <p>
    A ULA do coprocessador é a responsável por aplicar os algoritmos sobre a imagem, a partir da escolha feita no OpCode. Nesse tópico ocorrerá um aprofundamento acerca dos algoritmos os quais foram utilizados para resolução do projeto. 
  </p>

