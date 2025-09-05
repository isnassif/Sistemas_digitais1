module datapath (
     input clk,
	  input rst, 
	  input wire [7:0] pixel_entrada, // carrega os valores do pixel que sai da rom
	  input wire entrada_valida,
	  input wire [1:0] opcode,
	  input wire enable_cnt, // sinal pra iniciar o contador 
	  input wire captura_pixel, // sinal pra guardar o pixel, no algoritmo rep_pixel
	  input wire [1:0] selec_mux, // controla o que vai sair
	  
	  
	  output reg [7:0] pixel_saida, // manda o pixel processado pro vga
	  output reg saida_valida, // avisa ao vga que o pixel_saida e valido
	  
	  
	  // saidas para a logica de decimacao
	  output wire x_par,
	  output wire y_par,
	  
	  
	  
	  output wire x_fim,
	  output wire y_fim
	  
	  
	  
);  



     reg [8:0] cnt_x;
	  reg [7:0] cnt_y;
	  reg [7:0] px_guardadorep;
	  reg [9:0] acumulador;
	  reg [7:0] janela00;
	  reg [7:0] janela01;
	  reg [7:0] janela10;
	  reg [7:0] janela11;



	  wire [7:0] px_de_cima
	  wire [7:0] resultado_da_ula;
     wire [7:0] entrada_A;
     wire [7:0] entrada_B;
     wire [3:0] opcode_ula; 
	  wire [9:0] soma_10bits;
	  wire [7:0] resultado_10bits;
		
		
	  assign resultado_8bits = (soma_10bits > 255) ? 8'd255 : soma_10bits[7:0]; // tratamento de overflow, sem ele vai dar problema de largura 
	  
	  bufffer_ram line_buffer (
	          .clk(clk),
				 .wr_en(entrada_valida), // escrita
				 .data_entrada(pixel_entrada), // fonte
				 .wr_addr(cnt_x), // endereço da coluna
				 .rd_addr(cnt_x), // endereço da coluna
				 .data_saida(px_de_cima) // resultado
);

	  mux8_1 mux (
	       .d0(pixel_entrada),
			 .d1(px_guardadorep),
			 .d2(resultado_8bits),
			 .d3(8'h00),
			 .d4(janela00),
			 .d5(janela01),
			 .d6(janela10),
			 .d7(janela11),
			 .sel(selec_mux),
			 .z(pixel_saida)
);
	  
	  
	  
	  
	  ula ula (
	      .A(entrada_A),
			.B(entrada_B),
			.ALU_Sel(opcode_ula), // Sinal de controle vindo do Controller
         .ALU_Out(resultado_da_ula)   // Fio com o resultado
);
	  
	  
	  
	  always @(posedge clk) begin
	        if (rst) begin  // inicializacao dos contadores
			     cnt_x <= 9'h00;
				  cnt_y <= 8'h00;
				  px_guardadorep <= 8'h00;
				  acumulador <= 10'h000;
				  
				  pixel_saida <= 8'h00;
				  entrada_valida <= 1'b0;
				  saida_valida <= 1'b0;
				  
			 end else begin
			     if (enable_cnt) begin
				     if (cnt_x == 319) begin // comeca a contabilizar cnt_y
					     cnt_x <= 9'b0;
						  cnt_y <= cnt_y + 1;
					  end else begin
					      cnt_x <= cnt_x + 1; // contabiliza cnt_x
							end
				  end
				  // garante que os registradores da janela2x2 sempre contenham os 4 pixels, prontos para serem usados na ula
				  if (entrada_valida) begin
				     if (captura_pixel) begin
					     px_guardadorep <= pixel_entrada;
					  end else begin
					      janela11 <= pixel_entrada; // pega P(x-1,y-1)
							janela10 <= px_de_cima; // pega P(x,y-1)
							janela01 <= janela11; // o da direita desliza para a esquerda
							janela00 <= janela10; // o de cima a direita desliza para a esquerda
							end
				  end
     end
				  
				  
    assign x_par = cnt_x[0];
	 assign y_par = cnt_y[0];
	 
	 
	 assign x_fim = (cnt_x == 319);
	 assign y_fim =(cnt_y == 239);
	 
	 
	 
	 // logica da ula especializada
	 
	 wire [7:0] saida_decimacao;
	 wire [7:0] saida_rep;
	 wire [7:0] saida_media;
	 wire [7:0] saida_zoomin
	 
	 
	 
	 assign saida_decimacao = pixel_entrada;
	 assign saida_rep = px_guardadorep;
	 assign saida_media = (janela00 + janela01 + janela10 + janela11) >> 2;
	 assign saida_zoomin = (janela00 + janela01 + janela10 + janela11);
	 
	 always @(*) begin
       case (selec_mux) // controla o mux
        2'b00:  pixel_saida = saida_decimacao;
        2'b01:  pixel_saida = saida_media;
        2'b10:  pixel_saida = saida_rep;
        2'b11:  pixel_saida = saida_zoomin; // Para o Vizinho Próximo
        default: pixel_saida = 8'h00;
      endcase
    end
endmodule
	  
	  
	  
	  
	  
	  
	  