module rep_pixel #(
    parameter LARGURA = 2,
    parameter ALTURA  = 2,
    parameter FATOR   = 2,
    parameter NEW_LARG    = FATOR * LARGURA,
    parameter NEW_ALTURA  = FATOR * ALTURA
)(
    input  wire clk,
    input  wire rst,
    input pixel_rom,
    output[18:0]addr_rom
);

    reg [7:0] memoria_entrada [0:LARGURA*ALTURA-1];
    reg [7:0] memoria_saida   [0:NEW_LARG*NEW_ALTURA-1];

    reg [10:0] linha, coluna, di, dj;
    addr_rom = linha*LARGURA + coluna;
    wire [7:0] pixel = pixel_rom;
    wire [10:0] addr  = (linha*FATOR + di)*NEW_LARG + (coluna*FATOR + dj);


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            linha  <= 0; coluna <= 0; di <= 0; dj <= 0;
        end else begin
            memoria_saida[addr] <= pixel;

            if (dj == FATOR-1) begin
                dj <= 0;
                if (di == FATOR-1) begin
                    di <= 0;
                    if (coluna == LARGURA-1) begin
                        coluna <= 0;
                        linha  <= (linha == ALTURA-1) ? 0 : (linha + 1);
                    end else begin
                        coluna <= coluna + 1;
                    end
                end else begin
                    di <= di + 1;
                end
            end else begin
                dj <= dj + 1;
            end
        end
    end

endmodule
