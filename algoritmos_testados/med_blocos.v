module med_blocos #(
    parameter LARGURA    = 80,
    parameter ALTURA     = 60,
    parameter FATOR      = 2,
    parameter NEW_LARG   = LARGURA / FATOR,
    parameter NEW_ALTURA = ALTURA  / FATOR
)();

    // memória de entrada e saída
    reg [7:0] memoria_entrada [0:LARGURA*ALTURA-1];
    reg [7:0] memoria_saida   [0:NEW_LARG*NEW_ALTURA-1];

    integer linha, coluna;  // âncora do bloco
    integer di, dj;         // offsets dentro do bloco
    integer k;
    reg [15:0] soma;
    reg [7:0] pixel_cur;

    localparam DIV = FATOR*FATOR;

    // carregar entrada
    initial begin
        $readmemh("entrada.mem", memoria_entrada);

        // inicializa saída
        for (k = 0; k < NEW_LARG*NEW_ALTURA; k = k + 1)
            memoria_saida[k] = 0;

        // cálculo da média de blocos
        for (linha = 0; linha < ALTURA; linha = linha + FATOR) begin
            for (coluna = 0; coluna < LARGURA; coluna = coluna + FATOR) begin
                soma = 0;
                for (di = 0; di < FATOR; di = di + 1) begin
                    for (dj = 0; dj < FATOR; dj = dj + 1) begin
                        pixel_cur = memoria_entrada[(linha+di)*LARGURA + (coluna+dj)];
                        soma = soma + pixel_cur;
                    end
                end
                memoria_saida[(linha/FATOR)*NEW_LARG + (coluna/FATOR)] = soma / DIV;
            end
        end
    end

endmodule
