module rep_pixel #(
    parameter LARGURA = 2,
    parameter ALTURA  = 2,
    parameter FATOR   = 2,
    parameter NEW_LARG    = FATOR * LARGURA,
    parameter NEW_ALTURA  = FATOR * ALTURA
)(
    input  wire clk,
    input  wire rst,

    output wire [7:0] saida_0,  output wire [7:0] saida_1,
    output wire [7:0] saida_2,  output wire [7:0] saida_3,
    output wire [7:0] saida_4,  output wire [7:0] saida_5,
    output wire [7:0] saida_6,  output wire [7:0] saida_7,
    output wire [7:0] saida_8,  output wire [7:0] saida_9,
    output wire [7:0] saida_10, output wire [7:0] saida_11,
    output wire [7:0] saida_12, output wire [7:0] saida_13,
    output wire [7:0] saida_14, output wire [7:0] saida_15
);

    reg [7:0] memoria_entrada [0:LARGURA*ALTURA-1];
    reg [7:0] memoria_saida   [0:NEW_LARG*NEW_ALTURA-1];

    reg [10:0] linha, coluna, di, dj;

    wire [7:0] pixel = memoria_entrada[linha*LARGURA + coluna];
    wire [10:0] addr  = (linha*FATOR + di)*NEW_LARG + (coluna*FATOR + dj);

    initial begin
        memoria_entrada[0] = 8'd1;
        memoria_entrada[1] = 8'd2;
        memoria_entrada[2] = 8'd3;
        memoria_entrada[3] = 8'd4;
    end

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

    assign saida_0  = memoria_saida[0];
    assign saida_1  = memoria_saida[1];
    assign saida_2  = memoria_saida[2];
    assign saida_3  = memoria_saida[3];
    assign saida_4  = memoria_saida[4];
    assign saida_5  = memoria_saida[5];
    assign saida_6  = memoria_saida[6];
    assign saida_7  = memoria_saida[7];
    assign saida_8  = memoria_saida[8];
    assign saida_9  = memoria_saida[9];
    assign saida_10 = memoria_saida[10];
    assign saida_11 = memoria_saida[11];
    assign saida_12 = memoria_saida[12];
    assign saida_13 = memoria_saida[13];
    assign saida_14 = memoria_saida[14];
    assign saida_15 = memoria_saida[15];
endmodule
