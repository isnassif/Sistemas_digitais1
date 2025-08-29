module rep_pixel#(
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
    integer ii, jj; // índices para replicação
    reg [7:0] pixel; // <<< DECLARADO AQUI (fora do loop)

    // carregar entrada
    initial begin
        $readmemh("entrada.mem", memoria_entrada);

        // replicação explícita de pixels
        for (i=0; i<ALTURA; i=i+1) begin
            for (j=0; j<LARGURA; j=j+1) begin
                // pega o pixel original
                pixel = memoria_entrada[i*LARGURA + j];

                // replica em bloco FATORxFATOR
                for (ii=0; ii<FATOR; ii=ii+1) begin
                    for (jj=0; jj<FATOR; jj=jj+1) begin
                        memoria_saida[(i*FATOR + ii)*NEW_LARG + (j*FATOR + jj)] = pixel;
                    end
                end
            end
        end
    end

endmodule
