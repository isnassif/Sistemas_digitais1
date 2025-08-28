module decimacao #(
    parameter LARGURA    = 4,
    parameter ALTURA     = 4,
    parameter FATOR      = 2,
    parameter NEW_LARG   = LARGURA / FATOR,
    parameter NEW_ALTURA = ALTURA  / FATOR
)(
    input  wire clk,
    input  wire rst,
	 output wire[6:0] seg0,
	 output wire[6:0] seg1,
	 output wire[6:0] seg2,
	 output wire[6:0] seg3

);

    reg [7:0]  memoria_entrada [0:LARGURA*ALTURA-1];
    reg [7:0]  memoria_saida   [0:NEW_LARG*NEW_ALTURA-1];

    reg [10:0] linha, coluna;   // âncora do bloco
    reg [10:0] di, dj;          // offsets dentro do bloco
    reg [15:0] soma;

    integer k;

    // inicialização (apenas simulação)
    initial begin
        memoria_entrada[0]=1;  memoria_entrada[1]=2;  memoria_entrada[2]=3;  memoria_entrada[3]=4;
        memoria_entrada[4]=5;  memoria_entrada[5]=6;  memoria_entrada[6]=7;  memoria_entrada[7]=8;
        memoria_entrada[8]=9;  memoria_entrada[9]=10; memoria_entrada[10]=11; memoria_entrada[11]=12;
        memoria_entrada[12]=13; memoria_entrada[13]=14; memoria_entrada[14]=15; memoria_entrada[15]=16;
    end

    // pixel atual (combinacional) e soma futura já incluindo esse pixel
    wire [7:0]  pixel_cur   = memoria_entrada[(linha+di)*LARGURA + (coluna+dj)];
    wire [15:0] soma_next   = soma + pixel_cur;
    localparam  DIV = FATOR*FATOR;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            linha  <= 0; 
				coluna <= 0;
            di <= 0; 
				dj <= 0;
            soma <= 0;
        end else begin
            // último elemento do bloco?
            if (di == FATOR-1 && dj == FATOR-1) begin
                // grava média do bloco (usa soma_next que já inclui o último pixel)
                memoria_saida[(linha/FATOR)*NEW_LARG + (coluna/FATOR)] <= soma_next / DIV;
                soma <= 0;
                di <= 0; 
					 dj <= 0;

                // avança âncora do próximo bloco (pula por FATOR e respeita borda)
                if (coluna == LARGURA - FATOR) begin
                    coluna <= 0;
                    if (linha == ALTURA - FATOR)
                        linha <= 0;
                    else
                        linha <= linha + FATOR;
                end else begin
                    coluna <= coluna + FATOR;
                end
            end else begin
                // acumula e avança dentro do bloco
                soma <= soma_next;
                if (dj == FATOR-1) begin
                    dj <= 0;
                    di <= di + 1;
                end else begin
                    dj <= dj + 1;
                end
            end
        end
    end
	 decodificador_7seg(.binario(memoria_saida[0][3:0]), .seg(seg0));
	 decodificador_7seg(.binario(memoria_saida[1][3:0]),.seg(seg1));
	 decodificador_7seg(.binario(memoria_saida[2][3:0]), .seg(seg2));
	 decodificador_7seg(.binario(memoria_saida[3][3:0]), .seg(seg3));


endmodule
