module main (
    input vga_reset,
    input clk_50MHz,
    input [2:0] sw,
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
    reg [2:0] sw_sync, sw_sync2;
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
	wire [9:0] IMG_W_AMP = (sw_sync == 3'b000) ? IMG_W*FATOR :   // replicação
                       (sw_sync == 3'b001) ? IMG_W/FATOR :   // decimação
                       (sw_sync == 3'b010) ? IMG_W*FATOR :   // zoom_nn (2x)
                       IMG_W;                               // default

	wire [9:0] IMG_H_AMP = (sw_sync == 3'b000) ? IMG_H*FATOR:   // replicação
                       (sw_sync == 3'b001) ? IMG_H/FATOR :   // decimação
                       (sw_sync == 3'b010) ? IMG_H*FATOR :   // zoom_nn (2x)
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
