module rom_to_ram (
    input clk,
    input reset,                // reset top-level (ativo baixo)
    input [1:0] seletor,        // 00: replicação, 01: decimação, 10: zoom_nn
    output reg saida,
    output reg [18:0] rom_addr,
    input [7:0] rom_data,
    output reg [18:0] ram_wraddr,
    output reg [7:0] ram_data,
    output reg ram_wren,
    output reg done
);

    // Estados da máquina
    reg [1:0] state;
    parameter ST_RESET      = 2'b00,
              ST_REPLICACAO = 2'b01,
              ST_DECIMACAO  = 2'b10,
              ST_ZOOMNN     = 2'b11;

    // Fios dos submódulos
    wire [18:0] rom_addr_rep;
    wire [18:0] ram_wraddr_rep;
    wire [7:0]  ram_data_rep;
    wire        ram_wren_rep;
    wire        done_rep;
     
    wire [18:0] rom_addr_dec;
    wire [18:0] ram_wraddr_dec;
    wire [7:0]  ram_data_dec;
    wire        done_dec;

    wire [18:0] rom_addr_zoom;
    wire [18:0] ram_wraddr_zoom;
    wire [7:0]  ram_data_zoom;
    wire        ram_wren_zoom;
    wire        done_zoom;

    // Resets dedicados para cada submódulo (active-low)
    reg reset_rep;
    reg reset_dec;
    reg reset_zoom;

    // Instâncias dos submódulos
    rep_pixel rep_inst(
        .clk(clk),
        .reset(reset_rep),
        .rom_addr(rom_addr_rep),
        .rom_data(rom_data),
        .ram_wraddr(ram_wraddr_rep),
        .ram_data(ram_data_rep),
        .ram_wren(ram_wren_rep),
        .done(done_rep)
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

    initial begin
        state <= ST_RESET;
        saida <= 1'b0;
        rom_addr <= 0;
        ram_wraddr <= 0;
        ram_data <= 0;
        ram_wren <= 0;
        done <= 0;
        reset_rep <= 1'b0;
        reset_dec <= 1'b0;
        reset_zoom <= 1'b0;
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
            reset_dec <= 1'b0;
            reset_zoom <= 1'b0;
        end else begin
            case(state)

                // Estado RESET: reseta tudo antes de qualquer operação
                ST_RESET: begin
                    reset_rep  <= 1'b0;
                    reset_dec  <= 1'b0;
                    reset_zoom <= 1'b0;
                    rom_addr   <= 0;
                    ram_wraddr <= 0;
                    ram_data   <= 0;
                    ram_wren   <= 0;
                    done       <= 0;

                    // Escolhe próximo estado baseado no seletor
                    case(seletor)
                        2'b00: state <= ST_REPLICACAO;
                        2'b01: state <= ST_DECIMACAO;
                        2'b10: state <= ST_ZOOMNN;
                        default: state <= ST_RESET;
                    endcase
                end

                ST_REPLICACAO: begin
                    reset_rep  <= 1'b1;
                    reset_dec  <= 1'b0;
                    reset_zoom <= 1'b0;
                    rom_addr   <= rom_addr_rep;
                    ram_wraddr <= ram_wraddr_rep;
                    ram_data   <= ram_data_rep;
                    ram_wren   <= ram_wren_rep;
                    done       <= done_rep;

                    if (seletor != 2'b00) state <= ST_RESET;
                end

                ST_DECIMACAO: begin
                    reset_rep  <= 1'b0;
                    reset_dec  <= 1'b1;
                    reset_zoom <= 1'b0;
                    rom_addr   <= rom_addr_dec;
                    ram_wraddr <= ram_wraddr_dec;
                    ram_data   <= ram_data_dec;
                    ram_wren   <= ~done_dec; // continua escrevendo até terminar
                    done       <= done_dec;

                    if (seletor != 2'b01) state <= ST_RESET;
                end

                ST_ZOOMNN: begin
                    reset_rep  <= 1'b0;
                    reset_dec  <= 1'b0;
                    reset_zoom <= 1'b1;
                    rom_addr   <= rom_addr_zoom;
                    ram_wraddr <= ram_wraddr_zoom;
                    ram_data   <= ram_data_zoom;
                    ram_wren   <= ram_wren_zoom;
                    done       <= done_zoom;

                    if (seletor != 2'b10) state <= ST_RESET;
                end

                default: state <= ST_RESET;

            endcase
        end
    end

endmodule


// Módulo de replicação de pixel
module rep_pixel(
    input clk,
    input reset,
    output reg [18:0] rom_addr,
    input [7:0] rom_data,
    output reg [18:0] ram_wraddr,
    output reg [7:0] ram_data,
    output reg ram_wren,
    output reg done
);

    parameter FATOR = 2;
    parameter LARGURA = 160;
    parameter ALTURA = 120;
    parameter NEW_LARG = FATOR * LARGURA;
    parameter NEW_ALTURA = FATOR * ALTURA;

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
                ram_wraddr <= (linha * FATOR + di) * NEW_LARG + (coluna * FATOR + dj);
                
                // Dado a ser escrito na RAM (mesmo pixel repetido)
                ram_data <= rom_data_reg;
                ram_wren <= 1;
                
                // Lógica de avanço nos contadores
                if (dj == FATOR - 1) begin
                    dj <= 0;
                    if (di == FATOR - 1) begin
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


module main (
    input vga_reset,
    input clk_50MHz,
    input [1:0] sw,
    output [9:0] next_x,
    output [9:0] next_y,
    output hsyncm,
    output vsyncm,
    output [7:0] redm,
    output [7:0] greenm,
    output [7:0] bluem,
    output blank,
    output sync,
    output clks
);

    // Clock VGA (25 MHz)
    reg clk_vga = 0;
    always @(posedge clk_50MHz) clk_vga <= ~clk_vga;

    // Sincronização das chaves
    reg [1:0] sw_sync, sw_sync2;
    always @(posedge clk_vga or posedge vga_reset) begin
        if (vga_reset) begin
            sw_sync <= sw;
            sw_sync2 <= sw;
        end else begin
            sw_sync2 <= sw;
            sw_sync <= sw_sync2;
        end
    end

    // parâmetros da imagem ORIGINAL
    parameter IMG_W = 160;
    parameter IMG_H = 120;
    parameter FATOR = 2;

    // Parâmetros ampliados baseados no seletor
	wire [9:0] IMG_W_AMP = (sw_sync == 2'b00) ? IMG_W*FATOR :   // replicação
                       (sw_sync == 2'b01) ? IMG_W/FATOR :   // decimação
                       (sw_sync == 2'b10) ? IMG_W*FATOR :   // zoom_nn (2x)
                       IMG_W;                               // default

	wire [9:0] IMG_H_AMP = (sw_sync == 2'b00) ? IMG_H*FATOR :   // replicação
                       (sw_sync == 2'b01) ? IMG_H/FATOR :   // decimação
                       (sw_sync == 2'b10) ? IMG_H*FATOR :   // zoom_nn (2x)
                       IMG_H;                               // default

    // Offsets
    reg [9:0] x_offset_reg, y_offset_reg;
    always @(posedge clk_vga) begin
        x_offset_reg <= (640 - IMG_W_AMP)/2;
        y_offset_reg <= (480 - IMG_H_AMP)/2;
    end

    wire in_image = (next_x >= x_offset_reg && next_x < x_offset_reg + IMG_W_AMP) &&
                    (next_y >= y_offset_reg && next_y < y_offset_reg + IMG_H_AMP);

    // Endereço da RAM
    reg [18:0] addr_reg;
    always @(posedge clk_vga) begin
        if (in_image)
            addr_reg <= (next_y - y_offset_reg) * IMG_W_AMP + (next_x - x_offset_reg);
        else
            addr_reg <= 0;
    end

    // framebuffer RAM
    wire [7:0] c;
    wire [18:0] wr_addr;
    wire [7:0] wr_data;
    wire wr_en;
    wire copy_done;

    ram2port framebuffer (
        .clock(clk_vga),
        .data(wr_data),
        .rdaddress(addr_reg),
        .wraddress(wr_addr),
        .wren(wr_en),
        .q(c)
    );

    // ROM
    wire [7:0] rom_pixel;
    wire [18:0] rom_addr;

    mem rom_image (
        .address(rom_addr),
        .clock(clk_vga),
        .q(rom_pixel)
    );

    // copiador ROM → RAM
    rom_to_ram copier (
        .clk(clk_vga),
        .reset(vga_reset), // aqui só depende do reset físico
        .seletor(sw_sync),
        .rom_addr(rom_addr),
        .rom_data(rom_pixel),
        .ram_wraddr(wr_addr),
        .ram_data(wr_data),
        .ram_wren(wr_en),
        .done(copy_done)
    );

    // color_in para VGA
    wire [7:0] color_in = (in_image) ? c : 8'd0;

    // VGA driver
    vga_driver draw (
        .clock(clk_vga),
        .reset(vga_reset),
        .color_in(color_in),
        .next_x(next_x),
        .next_y(next_y),
        .hsync(hsyncm),
        .vsync(vsyncm),
        .sync(sync),
        .clk(clks),
        .blank(blank),
        .red(redm),
        .green(greenm),
        .blue(bluem)
    );

endmodule
