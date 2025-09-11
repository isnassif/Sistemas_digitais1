module main (
    input vga_reset,
    input clk_50MHz,
    output hsyncm,
    output vsyncm,
    output [7:0] redm,
    output [7:0] greenm,
    output [7:0] bluem,
    output blank,
    output sync,
    output clks,
	output [8:0] LEDS
);

    // Clock VGA (25 MHz)
    reg clk_vga = 0;
    always @(posedge clk_50MHz) begin
        clk_vga <= ~clk_vga;
    end

	
	// VGA driver
    wire [9:0] next_x;
    wire [9:0] next_y;

    vga_driver draw (
        .clock(clk_vga),
        .reset(vga_reset),
        .color_in(color_in),  // Atribuindo o sinal color_in
        .next_x(next_x),
        .next_y(next_y),
        .hsync(hsyncm),
        .vsync(vsyncm),
        .sync(sync),
        .clk(clks),
        .blank(blank),
        .red(redm),   // Atribuindo para os sinais de cor no vga_driver
        .green(greenm),
        .blue(bluem)
    );

    // parâmetros da imagem
    parameter IMG_W = 320;
    parameter IMG_H = 240;
	wire [18:0] addr_geral;
	wire done_rep;

	 
    // offsets para centralizar
    wire [9:0] x_offset = (640 - IMG_W)/2; // 160
    wire [9:0] y_offset = (480 - IMG_H)/2; // 120

    // verifica se está dentro da área da imagem
    wire in_image = (next_x >= x_offset && next_x < x_offset + IMG_W) &&
                    (next_y >= y_offset && next_y < y_offset + IMG_H);

    // endereço da RAM
    reg [18:0] addr_reg;
    always @(posedge clk_50MHz) begin
        if (in_image)
            addr_reg <= (next_y - y_offset) * IMG_W + (next_x - x_offset);
        else
            addr_reg <= 0; // fora da imagem → fundo preto
    end

    // framebuffer RAM
    wire [7:0] c;
    /*ram2port framebuffer (
        .clock(clk_vga),
        .data(wr_data),
        .rdaddress(addr_reg),
        .wraddress(wr_addr),
        .wren(wr_en),
        .q(c)
    );*/

    // ROM (imagem original)
    wire [7:0] rom_pixel;
    wire [18:0] rom_addr;

    mem rom_image (
        .address(out_addr),
        .clock(clk_vga),
        .q(rom_pixel)
    );
	  
	 ram1port r1port(
	   .address(addr_geral),
	   .clock(clk_50MHz),
	   .data(out_repixel),
	   .wren(~done_rep),
	   .q(c)
	 );
	 
	 wire[7:0] out_repixel;
	 wire[18:0] addr_ram_rep;
	 wire[18:0] out_addr;
	 
	 rep_pixel1(
		.clk(clk_vga),
		.rst(vga_reset),       // Defina como entrada se necessário
		.pixel_rom(rom_pixel),
		.addr_rom(rom_addr),
		.pixel_saida(out_repixel),
		.addr_ram_vga(addr_ram_rep),
		.saida_addr(out_addr),
		.done(done_rep)
	 );

    // copiador ROM → RAM
 /*   wire [18:0] wr_addr;
    wire [7:0] wr_data;
    wire wr_en;

    rom_to_ram copier (
        .clk(clk_vga),
        .reset(vga_reset),
        .rom_addr(rom_addr),
        .rom_data(rom_pixel),
        .ram_wraddr(wr_addr),
        .ram_data(wr_data),
        .ram_wren(wr_en),
        .done()
    );
	 
	 */
	
	 assign LEDS[7:0] = color_in[7:0];
	 assign LEDS[8] = done_rep;
	 assign addr_geral = (done_rep) ? addr_reg : addr_ram_rep;
    // Atribuindo o color_in para ser a cor do framebuffer ou preto fora da imagem
    wire [7:0] color_in;
    assign color_in = (in_image) ? c : 8'd0; // Se dentro da imagem, use cor da RAM, senão fundo preto

endmodule
