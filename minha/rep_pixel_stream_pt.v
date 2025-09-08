module rep_pixel_stream_pt (
    input wire clk,                                 // Clock principal do sistema. Este é o "pulso" que sincroniza todas as operações.
    input wire rst,                                 // Reset síncrono. Quando em '1', ele zera todas as contagens e volta o módulo para um estado conhecido.
     
    // --- Entradas do fluxo de dados ---
    // Estes sinais trazem os dados da imagem para dentro deste módulo.
    // Eles vêm de uma fonte externa, como a saída do seu line buffer principal,
    // ou diretamente de um dispositivo de captura de imagem no FPGA.
    input wire [7:0] i_pixel_entrada,               // O pixel de imagem atual. No seu caso, é um byte (8 bits).
    input wire i_pixel_entrada_valido,              // Sinal de controle: Indica que o 'i_pixel_entrada' contém um dado válido AGORA.
    input wire i_linha_entrada_valida,              // Sinal de controle: Indica que toda uma linha de pixels já foi enviada pela entrada.
                                                        // Este sinal é crucial para saber quando começar a processar a próxima linha de entrada.
     
    // --- Saídas do fluxo de dados ---
    // Estes sinais enviam os pixels processados para fora deste módulo,
    // tipicamente para o próximo módulo no pipeline, que neste caso seria o módulo VGA.
    output reg [7:0] o_pixel_saida,                 // O pixel de imagem que foi replicado (horizontal e verticalmente).
    output reg o_pixel_saida_valido,                // Sinal de controle: Indica que o 'o_pixel_saida' contém um dado válido AGORA.
    output reg o_linha_saida_valida                 // Sinal de controle: Indica que uma linha COMPLETA de pixels replicados foi enviada para a saída.
);

    // --- Parâmetros Configuráveis ---
    // Estes parâmetros permitem que o módulo seja flexível e usado com diferentes resoluções e fatores de zoom.
    parameter FATOR = 2;                            // O fator de zoom. Ex: Se FATOR=2, um pixel original se torna um bloco 2x2 na saída.
    // ***** IMPORTANTE: RESOLUCAO_H_ORIGINAL *****
    // Este parâmetro DEVE ser definido com a RESOLUÇÃO HORIZONTAL da IMAGEM DE ENTRADA.
    // Por exemplo, se sua imagem original é 640x480, RESOLUCAO_H_ORIGINAL = 640.
    // Se for 320x240, RESOLUCAO_H_ORIGINAL = 320.
    // Isso garante que os buffers e contadores tenham o tamanho correto.
    parameter RESOLUCAO_H_ORIGINAL = 640; // Defina aqui a largura da sua imagem de entrada.
    parameter RESOLUCAO_H_AMPLIADA = RESOLUCAO_H_ORIGINAL * FATOR; // A resolução HORIZONTAL da IMAGEM DE SAÍDA, calculada automaticamente.

    // --- Buffer de Linha (Line Buffer) ---
    // Este é o "coração" para o processamento linha a linha. Ele armazena uma linha inteira de pixels da imagem original.
    // Ao armazenar uma linha completa, podemos "reler" os mesmos pixels várias vezes para a replicação vertical.
    // O tamanho do buffer é definido por RESOLUCAO_H_ORIGINAL.
    reg [7:0] buffer_linha [RESOLUCAO_H_ORIGINAL-1:0];

    // --- Ponteiros (Contadores) para o Buffer de Linha ---
    // Controlam onde estamos lendo e escrevendo dentro do 'buffer_linha'.
    // Precisam ter bits suficientes para endereçar todos os pixels da linha original.
    // Se RESOLUCAO_H_ORIGINAL for até 1024, 10 bits são suficientes (2^10 = 1024).
    reg [9:0] ponteiro_escrita_linha;               // Indica o próximo local LIVRE no 'buffer_linha' para escrever um pixel de entrada.
    reg [9:0] ponteiro_leitura_linha;               // Indica o pixel do 'buffer_linha' que será lido AGORA para a saída.

    // --- Contadores de Replicação ---
    // Controlam quantas vezes um pixel ou uma linha inteira são repetidos.
    // Usam 'FATOR-1' bits porque contam de 0 até FATOR-1.
    reg [FATOR-1:0] contador_rep_horiz;             // Conta as repetições de um ÚNICO pixel na direção HORIZONTAL.
    reg [FATOR-1:0] contador_rep_vert;             // Conta quantas vezes uma LINHA inteira já foi repetida na direção VERTICAL.

    reg [1:0] estado;
    localparam ESTADO_ESCRITA         = 2'd0; // Estado 0: Recebendo a linha de entrada e enchendo o 'buffer_linha'.
    localparam ESTADO_REPLICACAO     = 2'd1; // Estado 1: Lendo do 'buffer_linha' e gerando pixels replicados na saída.
    localparam ESTADO_REPLICACAO_LINHA = 2'd2; // Estado 2: Estado intermediário para continuar replicando a mesma linha verticalmente.

    always @(posedge clk) begin

        if (rst) begin

            ponteiro_escrita_linha <= 0;
            ponteiro_leitura_linha <= 0;
            contador_rep_horiz <= 0;
            contador_rep_vert <= 0;
            estado <= ESTADO_ESCRITA; 
            o_pixel_saida_valido <= 0;  
            o_linha_saida_valida <= 0;
        end else begin
            // --- Lógica de Operação Normal ---
            // Por padrão, assumimos que não há saída válida neste ciclo de clock.
            // Os sinais de validação só serão ligados se dados válidos forem produzidos.
            o_pixel_saida_valido <= 0;
            o_linha_saida_valida <= 0;

            // --- Transições de Estado e Lógica de Processamento ---
            case (estado)
                // --- Estado: ESTADO_ESCRITA ---
                // Objetivo: Encher o 'buffer_linha' com os pixels da linha de entrada.
                ESTADO_ESCRITA: begin
                    // Se um pixel válido chegou na entrada...
                    if (i_pixel_entrada_valido) begin
                        // ...armazena ele no buffer.
                        buffer_linha[ponteiro_escrita_linha] <= i_pixel_entrada;
                        // Move o ponteiro de escrita para o próximo espaço.
                        ponteiro_escrita_linha <= ponteiro_escrita_linha + 1;

                        // Checagem para saber se a linha inteira foi preenchida.
                        // O último índice válido é RESOLUCAO_H_ORIGINAL - 1. Se o ponteiro ATUAL for o último índice,
                        // significa que acabamos de escrever no último espaço.
                        if (ponteiro_escrita_linha == RESOLUCAO_H_ORIGINAL - 1) begin
                            // Se a linha está completa:
                            // 1. Mudar para o estado de REPLICAÇÃO.
                            estado <= ESTADO_REPLICACAO;
                            // 2. Resetar o ponteiro de leitura para o início do buffer (para ler a linha que acabamos de armazenar).
                            ponteiro_leitura_linha <= 0;
                        end
                    end
                end

                // --- Estado: ESTADO_REPLICACAO ---
                // Objetivo: Ler do 'buffer_linha' e emitir pixels replicados na saída.
                ESTADO_REPLICACAO: begin
                    // Primeira parte: Gerar as repetições HORIZONTAIS do pixel atual.
                    if (contador_rep_horiz < FATOR) begin
                        // Envia o pixel lido do buffer como saída.
                        o_pixel_saida <= buffer_linha[ponteiro_leitura_linha];
                        // Sinaliza que este pixel de saída é válido.
                        o_pixel_saida_valido <= 1;
                        // Conta mais uma repetição horizontal.
                        contador_rep_horiz <= contador_rep_horiz + 1;
                    end else begin
                        // Se já repetimos o pixel o número 'FATOR' de vezes horizontalmente:
                        // Segunda parte: Avançar para o próximo pixel na linha.
                        // Reseta o contador de repetição horizontal para o próximo pixel.
                        contador_rep_horiz <= 0;
                        // Move o ponteiro de leitura para o próximo pixel no buffer.
                        ponteiro_leitura_linha <= ponteiro_leitura_linha + 1;

                        // Checagem para saber se chegamos ao FIM da linha que estamos lendo do buffer.

                        if (ponteiro_leitura_linha == RESOLUCAO_H_ORIGINAL - 1) begin
                            // Se completamos a leitura e replicação de todos os pixels da linha original:
                            // 1. Resetar o ponteiro de leitura para o início do buffer (para poder reler a mesma linha).

                            ponteiro_leitura_linha <= 0;

                            // 2. Resetar o contador horizontal, pois começaremos a processar um novo pixel na próxima iteração (dentro da mesma linha replicada).
                            contador_rep_horiz <= 0;
                            // 3. Contar que completamos mais uma replicação VERTICAL da linha.
                            contador_rep_vert <= contador_rep_vert + 1;
                            
                            // Checagem para saber se JÁ COMPLETAMOS TODAS as repetições verticais necessárias.
                            // Se FATOR=2, precisamos de 2 linhas de saída. Contamos 0 e 1. Então, quando 'contador_rep_vert' atinge 'FATOR-1' (ou seja, 1), terminamos.
                            if (contador_rep_vert == FATOR - 1) begin
                                // Se terminamos TODAS as repetições verticais para esta linha:
                                // 1. Voltar para o estado de ESCRITA para receber a PRÓXIMA linha de entrada.
                                estado <= ESTADO_ESCRITA;
                                // 2. Resetar o ponteiro de escrita para o início do buffer para a nova linha.
                                ponteiro_escrita_linha <= 0;
                                // 3. Resetar o contador vertical para 0 para a próxima linha.
                                contador_rep_vert <= 0;
                                // 4. Sinalizar que uma LINHA COMPLETA de pixels REPLICADOS foi enviada para a saída.
                                o_linha_saida_valida <= 1;
                            end else begin
                                // Se ainda NÃO completamos todas as repetições verticais:
                                // Mudar para o estado ESTADO_REPLICACAO_LINHA.
                                // No próximo clock, voltaremos para ESTADO_REPLICACAO para ler o MESMO pixel do buffer novamente.
                                estado <= ESTADO_REPLICACAO_LINHA;
                            end
                        end
                    end
                end

                // --- Estado: ESTADO_REPLICACAO_LINHA ---
                // Este estado serve apenas para "ganhar" um ciclo de clock.
                // Ele permite que a lógica de transição (que verifica 'contador_rep_vert')
                // ocorra antes de voltarmos ao estado ESTADO_REPLICACAO para processar o próximo pixel da MESMA linha.
                ESTADO_REPLICACAO_LINHA: begin
                    // Simplesmente volta para o estado de REPLICAÇÃO.
                    estado <= ESTADO_REPLICACAO;
                end
            endcase
        end
    end
endmodule
