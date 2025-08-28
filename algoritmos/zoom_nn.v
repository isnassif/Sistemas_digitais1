module zoom_nn#(
    parameter LARGURA   = 2,
    parameter ALTURA    = 2,
    parameter FATOR     = 2,
    parameter NEW_LARG  = LARGURA * FATOR,
    parameter NEW_ALTURA= ALTURA  * FATOR
)(
    input  wire clk,
    input  wire rst,

    output reg [7:0] memoria_saida [0:NEW_LARG*NEW_ALTURA-1]
);

    reg [7:0] memoria_entrada [0:LARGURA*ALTURA-1];
  
    integer i, j;
    integer orig_i, orig_j;

    initial begin
        memoria_entrada[0] = 8'd1;
        memoria_entrada[1] = 8'd2;
        memoria_entrada[2] = 8'd3;
        memoria_entrada[3] = 8'd4;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i=0; i<NEW_LARG*NEW_ALTURA; i=i+1)
                memoria_saida[i] <= 0;
        end else begin
            for (i = 0; i < NEW_ALTURA; i = i + 1) begin
                for (j = 0; j < NEW_LARG; j = j + 1) begin
                    orig_i = i * ALTURA / NEW_ALTURA;
                    orig_j = j * LARGURA  / NEW_LARG;

                    memoria_saida[i*NEW_LARG + j] <= memoria_entrada[orig_i*LARGURA + orig_j];
                end
            end
        end
    end

endmodule
