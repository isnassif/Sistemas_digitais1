module vga_controller(
	 input vga_reset,
    input clk_50MHz,
    input [9:0] SW,
	 input x,
	 input y,
	 input z,
	 input h,
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
)



    reg clk_vga = 0;
	 
	 
    always @(posedge clk_50MHz) begin
        clk_vga <= ~clk_vga;
    end
	 
	 
	 vga_driver draw (
        .clock(clk_vga),
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
	 
	 
	 
	 wire [18:0] address;
    assign address = next_y * 640 + next_x;
	 
	 wire [7:0] c;
	 
	 
	 mem rom_image (
        .address(address),
        .clock(clk_vga),
        .q(c)
    );
	 
	 
	 // --- Sinal de validade do pixel (sempre 1 aqui, pois ROM responde todo clock) ---
    wire pixel_rom_valido = 1'b1;

    // --- Saída da ALU (pixel processado) ---
    wire [7:0] c_proc;
    wire pixel_proc_valido;

    // --- Instância da ALU ---
    alu arithmetic (
        .clk(clk_vga),
        .rst(vga_reset),
        .mode(SW[3:0]),         // algoritmo escolhido via switches
        .pixel_in(c),       // pixel vindo da ROM
        .pixel_in_valido(pixel_rom_valido),
        .pixel_out(c_proc),     // pixel já processado
        .pixel_out_valido(pixel_proc_valido)
    );
	 
	 
	 

	 
	 
	 
endmodule
