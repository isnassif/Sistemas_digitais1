module decimacao #(
    parameter LARGURA    = 4,
    parameter ALTURA     = 4,
    parameter FATOR      = 2,
    parameter NEW_LARG   = LARGURA / FATOR,
    parameter NEW_ALTURA = ALTURA / FATOR
)(
    input  wire clk,
    input  wire rst,
	 output wire[6:0] seg0,
	 output wire[6:0] seg1,
	 output wire[6:0] seg2,
	 output wire[6:0] seg3
);

    reg [7:0] memoria_entrada [0:LARGURA*ALTURA-1];
    reg [7:0] memoria_saida   [0:NEW_LARG*NEW_ALTURA-1];
    integer k;
    reg [10:0] linha, coluna;

    // Inicialização da memória de entrada
    initial begin
        memoria_entrada[0]  = 8'd1;
        memoria_entrada[1]  = 8'd2;
        memoria_entrada[2]  = 8'd3;
        memoria_entrada[3]  = 8'd4;
        memoria_entrada[4]  = 8'd5;
        memoria_entrada[5]  = 8'd6;
        memoria_entrada[6]  = 8'd7;
        memoria_entrada[7]  = 8'd8;
        memoria_entrada[8]  = 8'd9;
        memoria_entrada[9]  = 8'd10;
        memoria_entrada[10] = 8'd11;
        memoria_entrada[11] = 8'd12;
        memoria_entrada[12] = 8'd13;
        memoria_entrada[13] = 8'd14;
        memoria_entrada[14] = 8'd15;
        memoria_entrada[15] = 8'd16;
		  for (k = 0; k < NEW_LARG*NEW_ALTURA; k = k+1) begin
				memoria_saida[k] = 8'd0;
		  end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            linha  <= 0;
            coluna <= 0;
        end else begin
            // Só pega pixel quando linha e coluna são múltiplos de FATOR
            if ((linha % FATOR == 0) && (coluna % FATOR == 0)) begin
                memoria_saida[(linha / FATOR) * NEW_LARG + (coluna / FATOR)] 
                    <= memoria_entrada[linha * LARGURA + coluna];
            end

            // Avança na varredura
            if (coluna == LARGURA-1) begin
                coluna <= 0;
                if (linha == ALTURA-1)
                    linha <= 0;
                else
                    linha <= linha + 1;
            end else begin
                coluna <= coluna + 1;
            end
        end
    end



	 
	 decodificador_7seg(.binario(memoria_saida[0][3:0]), .seg(seg0));
	 decodificador_7seg(.binario(memoria_saida[1][3:0]),.seg(seg1));
	 decodificador_7seg(.binario(memoria_saida[2][3:0]), .seg(seg2));
	 decodificador_7seg(.binario(memoria_saida[3][3:0]), .seg(seg3));
endmodule
