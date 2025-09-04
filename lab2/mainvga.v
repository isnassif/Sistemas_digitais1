module main ( 
    input vga_reset,
    input clk_50MHz,
    input [9:0] SW,
    output [9:0] LEDR,
	output [9:0] next_x,
    output[9:0] next_y,
    output hsyncm,
    output vsyncm,
    output [7:0] redm,
    output [7:0] greenm,
    output [7:0] bluem,
	output blank,
	output sync,
	output clks
);
	wire fio = next_y*640 +next_x;
	wire [7:0] c;
	
	reg clk_vga = 0;
	
	always@(posedge clk_50MHz) begin	
		clk_vga <= ~clk_vga;
	end	
	
	vga_driver draw  ( 
					.clock(clk_vga),        // 25 MHz PLL
                    .reset(vga_reset),      // Active high reset, manipulated by instantiating module
                    .color_in(color), // Pixel color (RRRGGGBB) for pixel being drawn
                    .hsync(hsyncm),         // All of the connections to the VGA screen below
                    .vsync(vsyncm),
                    .red(redm),
					.next_x(next_x),
					.next_y(next_y),
                    .green(greenm),
                    .blue(bluem),
                    .sync(sync),
                    .clk(clks),
                    .blank(blank)
);

	memory draw(
		.adress(fio),
		.clock(clk_vga),
		.q(c)
		
	);
	
	wire [7:0] color;
	assign color = (next_x[3] == 1'b1) ? 8'b11100000 : SW;

endmodule

