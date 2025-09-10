module main ( 
    input vga_reset,
    input clk_50MHz,
    input [9:0] SW,
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

    // --------------------------------------------------------
    // Clock VGA (25 MHz)
    // --------------------------------------------------------
    reg clk_vga = 0;
    always @(posedge clk_50MHz) begin
        clk_vga <= ~clk_vga;
    end

    // --------------------------------------------------------
    // VGA Driver
    // --------------------------------------------------------
    wire [7:0] c; // pixel do framebuffer (RAM)
    wire [18:0] address; // endereço calculado pelo VGA

    vga_driver draw (
        .clock(~clk_vga),
        .reset(vga_reset),
        .color_in(c),
        .hsync(hsyncm),
        .vsync(vsyncm),
        .red(redm),
        .green(greenm),
        .blue(bluem),
        .next_x(next_x),
        .next_y(next_y),
        .sync(sync),
        .clk(clks),
        .blank(blank)
    );

    assign address = next_y * 640 + next_x;

    // --------------------------------------------------------
    // ROM (imagem original - gerada pelo IP Catalog)
    // --------------------------------------------------------
    wire [7:0] rom_pixel;
    wire [18:0] rom_addr;

    mem rom_image (
        .address(rom_addr),
        .clock(clk_vga),
        .q(rom_pixel)
    );

    // --------------------------------------------------------
    // RAM (framebuffer - gerada pelo IP Catalog)
    // --------------------------------------------------------
    wire [18:0] wr_addr;
    wire [7:0] wr_data;
    wire wr_en;

    ram2port framebuffer (
        .clock(clk_vga),
        .data(wr_data),
        .rdaddress(address), // VGA lê daqui
        .wraddress(wr_addr), // copiador escreve
        .wren(wr_en),
        .q(c)
    );

    // --------------------------------------------------------
    // Copiador ROM → RAM
    // --------------------------------------------------------
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

endmodule
