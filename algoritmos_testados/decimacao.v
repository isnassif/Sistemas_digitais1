module decimacao #(
    parameter LARGURA    = 80,
    parameter ALTURA     = 60,
    parameter FATOR      = 2,
    parameter NEW_LARG   = LARGURA / FATOR,
    parameter NEW_ALTURA = ALTURA  / FATOR
)();

    // memória de entrada e saída
    reg [7:0] memoria_entrada [0:LARGURA*ALTURA-1];
    reg [7:0] memoria_saida   [0:NEW_LARG*NEW_ALTURA-1];

    integer linha, coluna, k;

    // inicialização
    initial begin
        $readmemh("entrada.mem", memoria_entrada);

        // inicializa saída
        for (k = 0; k < NEW_LARG*NEW_ALTURA; k = k + 1)
            memoria_saida[k] = 0;

        // varredura e decimação
        for (linha = 0; linha < ALTURA; linha = linha + FATOR) begin
            for (coluna = 0; coluna < LARGURA; coluna = coluna + FATOR) begin
                memoria_saida[(linha/FATOR)*NEW_LARG + (coluna/FATOR)] =
                    memoria_entrada[linha*LARGURA + coluna];
            end
        end
    end

endmodule
