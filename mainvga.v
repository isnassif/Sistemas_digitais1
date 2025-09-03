module main ( 
    input vga_reset,
    input clk_50MHz,
    input [7:0] pixel_color,
    input [8:0] next_x,
    input [8:0] next_y,
    input [9:0] SW,
    output [9:0] LEDR,
    output hsyncm,
    output vsyncm,
    output [7:0] redm,
    output [7:0] greenm,
    output [7:0] bluem,
	 output blank,
	 output sync,
	 output clks
);
	
	reg clk_vga = 0;
	
	always@(posedge clk_50MHz) begin
	
		clk_vga <= ~clk_vga;
	end	
	
	vga_driver draw  ( 
						  .clock(clk_vga),        // 25 MHz PLL
                    .reset(vga_reset),      // Active high reset, manipulated by instantiating module
                    .color_in(SW[7:0]), // Pixel color (RRRGGGBB) for pixel being drawn
                    .hsync(hsyncm),         // All of the connections to the VGA screen below
                    .vsync(vsyncm),
                    .red(redm),
                    .green(greenm),
                    .blue(bluem),
                    .sync(sync),
                    .clk(clks),
                    .blank(blank)
);

endmodule


