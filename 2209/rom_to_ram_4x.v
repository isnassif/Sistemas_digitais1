module rom_to_ram (
    input clk,
    input reset,                // reset top-level (ativo baixo)
    input [3:0] seletor,        // 00: replicação, 01: decimação, 10: zoom_nn, 11: cópia direta
    output reg saida,
    output reg [18:0] rom_addr,
    input [7:0] rom_data,
    output reg [18:0] ram_wraddr,
    output reg [7:0] ram_data,
    output reg ram_wren,
    output reg done
);

    // Estados da máquina
    reg [3:0] state; // Aumentado para 3 bits para acomodar mais estados
    parameter ST_RESET       = 4'b0111,
              ST_REPLICACAO  = 4'b0000,
              ST_DECIMACAO   = 4'b0001,
              ST_ZOOMNN      = 4'b0010,
				  ST_MEDIA       = 4'b0011,
              ST_COPIA_DIRETA = 4'b0100,
              ST_REPLICACAO4  = 4'b1000,
              ST_DECIMACAO4 = 4'b1001,
              ST_ZOOMNN4 = 4'b1010,
              ST_MED4 = 4'b1011;
    // Fios dos submódulos
    wire [18:0] rom_addr_rep;
    wire [18:0] ram_wraddr_rep;
    wire [7:0]  ram_data_rep;
    wire        ram_wren_rep;
    wire        done_rep;
	 
	 wire [18:0] rom_addr_rep4;
    wire [18:0] ram_wraddr_rep4;
    wire [7:0]  ram_data_rep4;
    wire        ram_wren_rep4;
    wire        done_rep4;
     
    wire [18:0] rom_addr_dec;
    wire [18:0] ram_wraddr_dec;
    wire [7:0]  ram_data_dec;
    wire        done_dec;
	 
	 
    wire [18:0] rom_addr_dec4;
    wire [18:0] ram_wraddr_dec4;
    wire [7:0]  ram_data_dec4;
    wire        done_dec4;

    wire [18:0] rom_addr_zoom;
    wire [18:0] ram_wraddr_zoom;
    wire [7:0]  ram_data_zoom;
    wire        ram_wren_zoom;
    wire        done_zoom;
	 
	 wire [18:0] rom_addr_zoom4;
    wire [18:0] ram_wraddr_zoom4;
    wire [7:0]  ram_data_zoom4;
    wire        ram_wren_zoom4;
    wire        done_zoom4;

    wire [18:0] rom_addr_copia;
    wire [18:0] ram_wraddr_copia;
    wire [7:0]  ram_data_copia;
    wire        ram_wren_copia;
    wire        done_copia;
	 
	 wire [18:0] rom_addr_med;
    wire [18:0] ram_wraddr_med;
    wire [7:0]  ram_data_med;
    wire        ram_wren_med;
    wire        done_med;

    // Resets dedicados para cada submódulo (active-low)
    reg reset_rep;
    reg reset_rep4;
    reg reset_dec;
    reg reset_dec4;
    reg reset_zoom;
    reg reset_zoom4;
    reg reset_copia;
	 reg reset_med;

    // Instâncias dos submódulos
    rep_pixel rep_inst(
        .clk(clk),
        .reset(reset_rep),
		  .fator(2),
        .rom_addr(rom_addr_rep),
        .rom_data(rom_data),
        .ram_wraddr(ram_wraddr_rep),
        .ram_data(ram_data_rep),
        .ram_wren(ram_wren_rep),
        .done(done_rep)
    );
	 
	 
	  rep_pixel rep_inst4(
        .clk(clk),
        .reset(reset_rep4),
        .fator(4),
        .rom_addr(rom_addr_rep4),
        .rom_data(rom_data),
        .ram_wraddr(ram_wraddr_rep4),
        .ram_data(ram_data_rep4),
        .ram_wren(ram_wren_rep4),
        .done(done_rep4)
    ); 
	  
	 
	  
	  
    decimacao dec_inst(
        .clk(clk),
        .rst(reset_dec),
        .pixel_rom(rom_data),
        .rom_addr(rom_addr_dec),
        .addr_ram_vga(ram_wraddr_dec),
        .pixel_saida(ram_data_dec),
        .done(done_dec)
    );

    zoom_nn zoom_inst(
        .clk(clk),
        .reset(reset_zoom),
        .rom_addr(rom_addr_zoom),
        .rom_data(rom_data),
        .ram_wraddr(ram_wraddr_zoom),
        .ram_data(ram_data_zoom),
        .ram_wren(ram_wren_zoom),
        .done(done_zoom)
    );

    copia_direta copia_inst(
        .clk(clk),
        .reset(reset_copia),
        .rom_addr(rom_addr_copia),
        .rom_data(rom_data),
        .ram_wraddr(ram_wraddr_copia),
        .ram_data(ram_data_copia),
        .ram_wren(ram_wren_copia),
        .done(done_copia)
    );
	 
	 media_blocos med_inst(
        .clk(clk),
        .reset(reset_med),
        .pixel_rom(rom_data),
        .rom_addr(rom_addr_med),
        .ram_wraddr(ram_wraddr_med),
        .pixel_saida(ram_data_med),
        .done(done_med)
    );

    initial begin
        state <= ST_RESET;
        saida <= 1'b0;
        rom_addr <= 0;
        ram_wraddr <= 0;
        ram_data <= 0;
        ram_wren <= 0;
        done <= 0;
        reset_rep <= 1'b0;
		  reset_rep4 <= 1'b0;
        reset_dec <= 1'b0;
		  reset_dec4 <= 1'b0;
        reset_zoom <= 1'b0;
		  reset_zoom4 <= 1'b0;
        reset_copia <= 1'b0;
		  reset_med <= 1'b0;
    end

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            state <= ST_RESET;
            saida <= 1'b0;
            rom_addr <= 0;
            ram_wraddr <= 0;
            ram_data <= 0;
            ram_wren <= 0;
            done <= 0;
            reset_rep <= 1'b0;
		      reset_rep4 <= 1'b0;
            reset_dec <= 1'b0;
		      reset_dec4 <= 1'b0;
            reset_zoom <= 1'b0;
		      reset_zoom4 <= 1'b0;
            reset_copia <= 1'b0;
		      reset_med <= 1'b0;
        end else begin
            case(state)

                // Estado RESET: reseta tudo antes de qualquer operação
                ST_RESET: begin
                    reset_rep <= 1'b0;
		              reset_rep4 <= 1'b0;
                    reset_dec <= 1'b0;
		              reset_dec4 <= 1'b0;
                    reset_zoom <= 1'b0;
		              reset_zoom4 <= 1'b0;
                    reset_copia <= 1'b0;
		              reset_med <= 1'b0;
                    rom_addr    <= 0;
                    ram_wraddr  <= 0;
                    ram_data    <= 0;
                    ram_wren    <= 0;
                    done        <= 0;

                    // Escolhe próximo estado baseado no seletor
                    case(seletor)
                        4'b0000: state <= ST_REPLICACAO;
                        4'b0001: state <= ST_DECIMACAO;
                        4'b0010: state <= ST_ZOOMNN;
								4'b0011: state <= ST_MEDIA;
                        4'b0100: state <= ST_COPIA_DIRETA;
								4'b1000: state <= ST_REPLICACAO4;
                        default: state <= ST_RESET;
                    endcase
                end

                ST_REPLICACAO: begin
                    reset_rep   <= 1'b1;
						  reset_rep4   <= 1'b0;
                    reset_dec   <= 1'b0;
						  reset_dec4   <= 1'b0;
                    reset_zoom  <= 1'b0;
						  reset_zoom4  <= 1'b0;
                    reset_copia <= 1'b0;
				  		  reset_med <= 1'b0;
                    rom_addr    <= rom_addr_rep;
                    ram_wraddr  <= ram_wraddr_rep;
                    ram_data    <= ram_data_rep;
                    ram_wren    <= ram_wren_rep;
                    done        <= done_rep;

                    if (seletor != 4'b0000) state <= ST_RESET;
                end
					 
					 ST_REPLICACAO4: begin
                    reset_rep   <= 1'b0;
						  reset_rep4   <= 1'b1;
                    reset_dec   <= 1'b0;
						  reset_dec4   <= 1'b0;
                    reset_zoom  <= 1'b0;
						  reset_zoom4  <= 1'b0;
                    reset_copia <= 1'b0;
				  		  reset_med <= 1'b0;
                    rom_addr    <= rom_addr_rep4;
                    ram_wraddr  <= ram_wraddr_rep4;
                    ram_data    <= ram_data_rep4;
                    ram_wren    <= ram_wren_rep4;
                    done        <= done_rep4;

                    if (seletor != 4'b1000) state <= ST_RESET;
                end

                ST_DECIMACAO: begin
                    reset_rep   <= 1'b1;
						  reset_rep4   <= 1'b0;
                    reset_dec   <= 1'b1;
						  reset_dec4   <= 1'b0;
                    reset_zoom  <= 1'b0;
						  reset_zoom4  <= 1'b0;
                    reset_copia <= 1'b0;
				  		  reset_med <= 1'b0;
                    rom_addr    <= rom_addr_dec;
                    ram_wraddr  <= ram_wraddr_dec;
                    ram_data    <= ram_data_dec;
                    ram_wren    <= ~done_dec; // continua escrevendo até terminar
                    done        <= done_dec;

                    if (seletor != 4'b0001) state <= ST_RESET;
                end

                ST_ZOOMNN: begin
                    reset_rep   <= 1'b0;
						  reset_rep4   <= 1'b0;
                    reset_dec   <= 1'b0;
						  reset_dec4   <= 1'b0;
                    reset_zoom  <= 1'b1;
						  reset_zoom4  <= 1'b0;
                    reset_copia <= 1'b0;
				  		  reset_med <= 1'b0;
                    rom_addr    <= rom_addr_zoom;
                    ram_wraddr  <= ram_wraddr_zoom;
                    ram_data    <= ram_data_zoom;
                    ram_wren    <= ram_wren_zoom;
                    done        <= done_zoom;

                    if (seletor != 4'b0010) state <= ST_RESET;
                end
					 
					 ST_MEDIA: begin
                    reset_rep   <= 1'b0;
						  reset_rep4   <= 1'b0;
                    reset_dec   <= 1'b0;
						  reset_dec4   <= 1'b0;
                    reset_zoom  <= 1'b0;
						  reset_zoom4  <= 1'b0;
                    reset_copia <= 1'b0;
				  		  reset_med <= 1'b1;
                    rom_addr <= rom_addr_med; 
						  ram_wraddr <= ram_wraddr_med; 
						  ram_data <= ram_data_med; 
						  ram_wren <= ~done_med; 
						  done <= done_med;
                    if (seletor != 4'b0011) state <= ST_RESET;
                end

                ST_COPIA_DIRETA: begin
                    reset_rep   <= 1'b0;
				  		  reset_med <= 1'b0;  
						  reset_dec   <= 1'b0;
                    reset_zoom  <= 1'b0;
                    reset_copia <= 1'b1;
                    rom_addr    <= rom_addr_copia;
                    ram_wraddr  <= ram_wraddr_copia;
                    ram_data    <= ram_data_copia;
                    ram_wren    <= ram_wren_copia;
                    done        <= done_copia;

                    if (seletor != 4'b0100) state <= ST_RESET;
                end

                default: state <= ST_RESET;

            endcase
        end
    end

endmodule

// Módulo de cópia direta (imagem original)
module copia_direta (
    input clk,
    input reset,
    output reg [18:0] rom_addr,
    input [7:0] rom_data,
    output reg [18:0] ram_wraddr,
    output reg [7:0] ram_data,
    output reg ram_wren,
    output reg done
);

    parameter TOTAL_PIXELS = 160*120; // pixels da ROM

    reg [18:0] counter;
    reg [7:0] rom_data_reg;

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            counter <= 0;
            rom_addr <= 0;
            ram_wraddr <= 0;
            ram_data <= 0;
            ram_wren <= 0;
            done <= 0;
            rom_data_reg <= 0;
        end else begin
            rom_data_reg <= rom_data; // pega dado com 1 ciclo de atraso

            if (counter < TOTAL_PIXELS) begin
                rom_addr   <= counter;
                ram_wraddr <= counter;
                ram_data   <= rom_data_reg;
                ram_wren   <= 1;
                counter    <= counter + 1;
            end else begin
                ram_wren <= 0;
                done <= 1;
            end
        end
    end
endmodule

// Módulo de replicação de pixel
module rep_pixel(
    input clk,
    input reset,
	 input [2:0] fator,
    output reg [18:0] rom_addr,
    input [7:0] rom_data,
    output reg [18:0] ram_wraddr,
    output reg [7:0] ram_data,
    output reg ram_wren,
    output reg done
);

    
    parameter LARGURA = 160;
    parameter ALTURA = 120;
    wire [11:0] NEW_LARG = LARGURA * fator;
    wire [11:0] NEW_ALTURA = ALTURA * fator;

    reg [10:0] linha, coluna, di, dj;
    reg [7:0] rom_data_reg;

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            rom_addr <= 0;
            ram_wraddr <= 0;
            ram_data <= 0;
            ram_wren <= 0;
            done <= 0;
            linha <= 0;
            coluna <= 0;
            di <= 0;
            dj <= 0;
            rom_data_reg <= 0;
        end else begin
            // Registra o dado da ROM com 1 ciclo de atraso
            rom_data_reg <= rom_data;
            
            if (!done) begin
                // Calcula endereço da ROM (pixel original)
                rom_addr <= linha * LARGURA + coluna;
                
                // Calcula endereço da RAM (pixel ampliado)
                ram_wraddr <= (linha * fator + di) * NEW_LARG + (coluna * fator + dj);
                
                // Dado a ser escrito na RAM (mesmo pixel repetido)
                ram_data <= rom_data_reg;
                ram_wren <= 1;
                
                // Lógica de avanço nos contadores
                if (dj == fator - 1) begin
                    dj <= 0;
                    if (di == fator - 1) begin
                        di <= 0;
                        if (coluna == LARGURA - 1) begin
                            coluna <= 0;
                            if (linha == ALTURA - 1) begin
                                linha <= 0;
                                done <= 1;
                                ram_wren <= 0;
                            end else begin
                                linha <= linha + 1;
                            end
                        end else begin
                            coluna <= coluna + 1;
                        end
                    end else begin
                        di <= di + 1;
                    end
                end else begin
                    dj <= dj + 1;
                end
            end else begin
                ram_wren <= 0;
            end
        end
    end

endmodule
    

// Módulo de decimação
module decimacao #(
    parameter FATOR = 2,
    parameter LARGURA = 160,
    parameter ALTURA = 120,
    parameter NEW_LARG = LARGURA / FATOR,
    parameter NEW_ALTURA = ALTURA / FATOR
)(
    input clk,
    input rst,
    input [7:0] pixel_rom,
    output reg [18:0] rom_addr,
    output reg [18:0] addr_ram_vga,
    output reg [7:0] pixel_saida,
    output reg done
);
    
    reg [10:0] x_in, y_in;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            rom_addr <= 0;
            addr_ram_vga <= 0;
            x_in <= 0;
            y_in <= 0;
            done <= 0;
            pixel_saida <= 0;
        end else if (~done) begin
            // Endereço da ROM (entrada 160x120)
            rom_addr <= y_in * LARGURA + x_in;

            // Mapeia para saída decimada (80x60)
            pixel_saida <= pixel_rom;
            addr_ram_vga <= (y_in / FATOR) * NEW_LARG + (x_in / FATOR);

            // Avança coordenadas da ROM, pulando FATOR em X
            if (x_in >= LARGURA - FATOR) begin
                x_in <= 0;
                if (y_in >= ALTURA - FATOR) begin
                    y_in <= 0;
                    done <= 1;
                end else begin
                    y_in <= y_in + FATOR;
                end
            end else begin
                x_in <= x_in + FATOR;
            end
        end
    end
endmodule

module zoom_nn #(
    parameter LARGURA = 160,
    parameter ALTURA  = 120,
    parameter FATOR   = 2
)(
    input clk,
    input reset,
    output reg [18:0] rom_addr,
    input [7:0] rom_data,
    output reg [18:0] ram_wraddr,
    output reg [7:0] ram_data,
    output reg ram_wren,
    output reg done
	 
);
    parameter NEW_LARG = LARGURA * FATOR;

    reg [7:0] rom_data_reg;
    reg [10:0] linha, coluna, di, dj;

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            linha <= 0; coluna <= 0; di <= 0; dj <= 0;
            rom_addr <= 0; ram_wraddr <= 0;
            rom_data_reg <= 0; ram_data <= 0;
            ram_wren <= 0; done <= 0;
        end else begin
            rom_data_reg <= rom_data;

            if (!done) begin
                ram_wren <= 1;
                ram_data <= rom_data_reg;

                // O endereço da ROM só avança quando começamos um novo pixel da fonte.
                if (di == 0 && dj == 0) begin
                    rom_addr <= linha * LARGURA + coluna;
                end
                
                ram_wraddr <= (linha * FATOR + di) * NEW_LARG + (coluna * FATOR + dj);

                // lógica de contadores
                if (dj == FATOR - 1) begin
                    dj <= 0;
                    if (di == FATOR - 1) begin
                        di <= 0;
                        if (coluna == LARGURA - 1) begin
                            coluna <= 0;
                            if (linha == ALTURA - 1) begin
                                linha <= 0;
                                done <= 1;
                            end else begin
                                linha <= linha + 1;
                            end
                        end else begin
                            coluna <= coluna + 1;
                        end
                    end else begin
                        di <= di + 1;
                    end
                end else begin
                    dj <= dj + 1;
                end
            end else begin
                ram_wren <= 0;
            end
        end
    end
endmodule

module media_blocos #(
    parameter FATOR = 2,
    parameter LARGURA = 160,
    parameter ALTURA = 120,
    parameter NEW_LARG = LARGURA / FATOR,
    parameter NEW_ALTURA = ALTURA / FATOR
)(
    input clk,
    input reset,
    input [7:0] pixel_rom,
    output reg [18:0] rom_addr,
    output reg [18:0] ram_wraddr,
    output reg [7:0] pixel_saida,
    output reg done
);

    reg [10:0] bloco_x, bloco_y;
    reg [3:0] sub_x, sub_y;
    reg [15:0] soma_pixels;
    reg [3:0] pixel_count;
    reg [1:0] estado;
    localparam IDLE = 2'b00, READ_BLOCK = 2'b01, CALC_AVERAGE = 2'b10, WRITE_OUTPUT = 2'b11;
    reg [7:0] pixel_rom_reg;

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            rom_addr <= 0; ram_wraddr <= 0; pixel_saida <= 0; done <= 0;
            bloco_x <= 0; bloco_y <= 0; sub_x <= 0; sub_y <= 0;
            soma_pixels <= 0; pixel_count <= 0; estado <= IDLE; pixel_rom_reg <= 0;
        end else begin
            pixel_rom_reg <= pixel_rom;

            case(estado)
                IDLE: begin
                    soma_pixels <= 0; pixel_count <= 0; sub_x <= 0; sub_y <= 0; estado <= READ_BLOCK;
                end

                READ_BLOCK: begin
                    rom_addr <= (bloco_y*FATOR + sub_y)*LARGURA + (bloco_x*FATOR + sub_x);
                    if (pixel_count > 0) soma_pixels <= soma_pixels + pixel_rom_reg;
                    pixel_count <= pixel_count + 1;

                    if (sub_x >= FATOR-1) begin
                        sub_x <= 0;
                        if (sub_y >= FATOR-1) estado <= CALC_AVERAGE; else sub_y <= sub_y+1;
                    end else sub_x <= sub_x+1;
                end

                CALC_AVERAGE: begin
                    soma_pixels <= soma_pixels + pixel_rom_reg;
                    estado <= WRITE_OUTPUT;
                end

                WRITE_OUTPUT: begin
                    if (FATOR == 2) pixel_saida <= soma_pixels >> 2;
                    else pixel_saida <= soma_pixels / (FATOR*FATOR);

                    ram_wraddr <= bloco_y*NEW_LARG + bloco_x;

                    if (bloco_x >= NEW_LARG-1) begin
                        bloco_x <= 0;
                        if (bloco_y >= NEW_ALTURA-1) begin
                            bloco_y <= 0; done <= 1;
                        end else bloco_y <= bloco_y + 1;
                    end else bloco_x <= bloco_x + 1;

                    soma_pixels <= 0; pixel_count <= 0; sub_x <= 0; sub_y <= 0; estado <= READ_BLOCK;
                end
            endcase
        end
    end

endmodule
