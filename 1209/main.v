module main (
    input vga_reset,
    input clk_50MHz,
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
    always @(posedge clk_50MHz) begin
        clk_vga <= ~clk_vga;
    end

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

    // parâmetros da imagem ORIGINAL
    parameter IMG_W = 160;
    parameter IMG_H = 120;
    
    // parâmetros da imagem AMPLIADA
    parameter FATOR = 2;
    parameter IMG_W_AMP = IMG_W * FATOR;  // 320
    parameter IMG_H_AMP = IMG_H * FATOR;  // 240

    // offsets para centralizar a imagem AMPLIADA
    wire [9:0] x_offset = (640 - IMG_W_AMP)/2; // (640-320)/2 = 160
    wire [9:0] y_offset = (480 - IMG_H_AMP)/2; // (480-240)/2 = 120

    // verifica se está dentro da área da imagem AMPLIADA
    wire in_image = (next_x >= x_offset && next_x < x_offset + IMG_W_AMP) &&
                    (next_y >= y_offset && next_y < y_offset + IMG_H_AMP);

    // endereço da RAM (para leitura durante display)
    reg [18:0] addr_reg;
    always @(posedge clk_vga) begin
        if (in_image)
            // Mapeia coordenadas da tela para endereços da RAM ampliada
            addr_reg <= (next_y - y_offset) * IMG_W_AMP + (next_x - x_offset);
        else
            addr_reg <= 0; // fora da imagem → fundo preto
    end

    // framebuffer RAM (agora com tamanho ampliado)
    wire [7:0] c;
    ram2port framebuffer (
        .clock(clk_vga),
        .data(wr_data),
        .rdaddress(addr_reg),
        .wraddress(wr_addr),
        .wren(wr_en),
        .q(c)
    );

    // ROM (imagem original)
    wire [7:0] rom_pixel;
    wire [18:0] rom_addr;

    mem rom_image (
        .address(rom_addr),
        .clock(clk_vga),
        .q(rom_pixel)
    );

    // copiador ROM → RAM com ampliação
    wire [18:0] wr_addr;
    wire [7:0] wr_data;
    wire wr_en;
    wire copy_done;

    rom_to_ram copier (
        .clk(clk_vga),
        .reset(vga_reset),
        .rom_addr(rom_addr),
        .rom_data(rom_pixel),
        .ram_wraddr(wr_addr),
        .ram_data(wr_data),
        .ram_wren(wr_en),
        .done(copy_done)
    );

    // Atribuindo o color_in para ser a cor do framebuffer ou preto fora da imagem
    wire [7:0] color_in;
    assign color_in = (in_image) ? c : 8'd0;

endmodule


module main (
    input vga_reset,
    input clk_50MHz,
    input switch,  // SW9 - pino F15 - controle de zoom (0 = original, 1 = zoom)
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
    always @(posedge clk_50MHz) begin
        clk_vga <= ~clk_vga;
    end

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

    // parâmetros da imagem ORIGINAL
    parameter IMG_W = 160;
    parameter IMG_H = 120;
    
    // parâmetros da imagem AMPLIADA
    parameter FATOR = 2;
    parameter IMG_W_AMP = IMG_W * FATOR;  // 320
    parameter IMG_H_AMP = IMG_H * FATOR;  // 240

    // offsets para centralizar a imagem
    wire [9:0] x_offset_original = (640 - IMG_W)/2;    // (640-160)/2 = 240
    wire [9:0] y_offset_original = (480 - IMG_H)/2;    // (480-120)/2 = 180
    
    wire [9:0] x_offset_zoom = (640 - IMG_W_AMP)/2;   // (640-320)/2 = 160
    wire [9:0] y_offset_zoom = (480 - IMG_H_AMP)/2;   // (480-240)/2 = 120

    // Seleção do modo baseado na chave
    wire [9:0] x_offset = switch ? x_offset_zoom : x_offset_original;
    wire [9:0] y_offset = switch ? y_offset_zoom : y_offset_original;
    wire [9:0] img_width = switch ? IMG_W_AMP : IMG_W;
    wire [9:0] img_height = switch ? IMG_H_AMP : IMG_H;

    // verifica se está dentro da área da imagem
    wire in_image = (next_x >= x_offset && next_x < x_offset + img_width) &&
                   (next_y >= y_offset && next_y < y_offset + img_height);

    // Cálculo das coordenadas relativas
    wire [9:0] rel_x = next_x - x_offset;
    wire [9:0] rel_y = next_y - y_offset;

    // endereço para RAM (modo zoom)
    reg [18:0] ram_addr_reg;
    
    // endereço para ROM (modo original)
    reg [18:0] rom_addr_reg;
    
    always @(posedge clk_vga) begin
        if (in_image) begin
            if (switch) begin
                // Modo zoom: calcula endereço da RAM (imagem ampliada 320x240)
                ram_addr_reg <= rel_y * IMG_W_AMP + rel_x;
                rom_addr_reg <= 0; // não usado neste modo
            end else begin
                // Modo original: calcula endereço da ROM (imagem original 160x120)
                // A imagem original ocupa apenas a área central, então mapeamos
                // as coordenadas relativas diretamente para a ROM
                ram_addr_reg <= 0; // não usado neste modo
                rom_addr_reg <= rel_y * IMG_W + rel_x;
            end
        end else begin
            ram_addr_reg <= 0;
            rom_addr_reg <= 0;
        end
    end

    // framebuffer RAM (tamanho ampliado 320x240)
    wire [7:0] ram_pixel;
    ram2port framebuffer (
        .clock(clk_vga),
        .data(wr_data),
        .wraddress(wr_addr),
        .wren(wr_en),
        .rdaddress(ram_addr_reg),
        .q(ram_pixel)
    );

    // ROM (imagem original 160x120)
    wire [7:0] rom_pixel;
    mem rom_image (
        .address(rom_addr_reg),
        .clock(clk_vga),
        .q(rom_pixel)
    );

    // copiador ROM → RAM com ampliação
    wire [18:0] wr_addr;
    wire [7:0] wr_data;
    wire wr_en;
    wire copy_done;

    rom_to_ram copier (
        .clk(clk_vga),
        .reset(vga_reset),
        .rom_addr(rom_addr),
        .rom_data(rom_pixel),
        .ram_wraddr(wr_addr),
        .ram_data(wr_data),
        .ram_wren(wr_en),
        .done(copy_done)
    );

    // Seleção da fonte de dados
    reg [7:0] pixel_output;
    
    always @(posedge clk_vga) begin
        if (in_image) begin
            if (switch) begin
                // Modo zoom: usa dados da RAM (imagem ampliada 320x240)
                pixel_output <= ram_pixel;
            end else begin
                // Modo original: usa dados diretamente da ROM (imagem original 160x120)
                pixel_output <= rom_pixel;
            end
        end else begin
            pixel_output <= 8'd0;
        end
    end

    // Atribuindo o color_in
    wire [7:0] color_in;
    assign color_in = pixel_output;

endmodule
