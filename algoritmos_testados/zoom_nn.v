module zoom_nn#(
    parameter LARGURA    = 160,
    parameter ALTURA     = 120,
    parameter FATOR      = 2,
    parameter NEW_LARG   = LARGURA * FATOR,
    parameter NEW_ALTURA = ALTURA  * FATOR
)();

    // memória de entrada e saída
    reg [7:0] memoria_entrada [0:LARGURA*ALTURA-1];
    reg [7:0] memoria_saida   [0:NEW_LARG*NEW_ALTURA-1];

    integer i, j;
    integer orig_i, orig_j;

    // carregar entrada
    initial begin
        $readmemh("entrada.mem", memoria_entrada);

        // zoom
        for (i=0; i<NEW_ALTURA; i=i+1) begin
            for (j=0; j<NEW_LARG; j=j+1) begin
                orig_i = i * ALTURA / NEW_ALTURA;
                orig_j = j * LARGURA / NEW_LARG;
                memoria_saida[i*NEW_LARG+j] = memoria_entrada[orig_i*LARGURA+orig_j];
            end
        end
    end

endmodule
