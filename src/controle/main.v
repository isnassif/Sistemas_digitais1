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

    // Sincroniza reset (ativo alto) Gerado pelo deepseek, talves seja necessário voltar pra lógica antica
    wire reset_sync;
    assign reset_sync = ~vga_reset;  // Converte para reset ativo alto

    // VGA driver
    wire [9:0] next_x;
    wire [9:0] next_y;
    wire [7:0] color_in;  // Declaração do sinal color_in
    
    vga_driver draw (
        .clock(clk_vga),
        .reset(reset_sync), // Em caso de erro, colocar esse parâmetro como o vga_reset
        .color_in(color_in),  // Conectado ao sinal color_in
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

    // endereço da RAM - sincronizado com clk_vga
    reg [18:0] addr_reg;
    always @(posedge clk_vga) begin
        if (in_image)
            addr_reg <= (next_y - y_offset) * IMG_W + (next_x - x_offset);
        // Fora da imagem, não atualizamos o addr_reg (mantém o último valor)
    end

    // ROM (imagem original)
    wire [7:0] rom_pixel;
    wire [18:0] rom_addr;

    mem rom_image (
        .address(out_addr),
        .clock(clk_vga),
        .q(rom_pixel)
    );
    
    // RAM - usando clock sincronizado
    wire [7:0] c;
    ram1port r1port(
        .address(addr_geral),
        .clock(clk_vga), // Passando o mesmo clok do vga (alteração)
        .data(out_repixel),
        .wren(~done_rep),
        .q(c)
    );
    
    // Módulo de repetição de pixel
    wire [7:0] out_repixel;
    wire [18:0] addr_ram_rep;
    wire [18:0] out_addr;
    
    rep_pixel1 rep_instance(
        .clk(clk_vga),
        .rst(reset_sync), // Não estamos utilizando o vga_reset
        .pixel_rom(rom_pixel),
        .addr_rom(rom_addr),
        .pixel_saida(out_repixel),
        .addr_ram_vga(addr_ram_rep),
        .saida_addr(out_addr),
        .done(done_rep)
    );

    // Sincronização do endereço de escrita
    reg [18:0] addr_ram_rep_sync;
    always @(posedge clk_vga) begin
        addr_ram_rep_sync <= addr_ram_rep;
    end
    
    assign addr_geral = (done_rep) ? addr_reg : addr_ram_rep_sync;

    // Atribuição da cor de entrada do VGA
    assign color_in = (in_image) ? c : 8'd0;

    // Debug com LEDs
    assign LEDS[7:0] = color_in[7:0];
    assign LEDS[8] = done_rep;

endmodule
