module rep_pixel #(
    parameter FATOR   = 2,
    parameter NEW_LARG    = FATOR * LARGURA,
    parameter NEW_ALTURA  = FATOR * ALTURA
)(
    input  wire clk,
    input  wire rst,
    input LARGURA,
    input ALTURA,
    input [7:0]pixel_rom,
    output[18:0]addr_rom,
    output [7:0]pixel_saida
);


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
