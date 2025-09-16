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
    always @(posedge clk_50MHz) begin
        clk_vga <= ~clk_vga;
    end

    // Sincronização do seletor sw com o clock VGA
    reg [1:0] sw_sync;
    reg [1:0] sw_sync2; // Estágio adicional para melhor sincronização
    
    always @(posedge clk_vga or posedge vga_reset) begin
        if (vga_reset) begin
            sw_sync2 <= sw;  // No reset, captura o valor atual das chaves
            sw_sync <= sw;   // em vez de forçar para 00
        end else begin
            sw_sync2 <= sw;
            sw_sync <= sw_sync2;
        end
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
    parameter FATOR = 2;
    
    // Cálculo dos parâmetros ampliados baseado no seletor sw sincronizado
    wire [9:0] IMG_W_AMP;
    wire [9:0] IMG_H_AMP;
    
    assign IMG_W_AMP = (sw_sync == 2'b00) ? IMG_W * FATOR : 
                      (sw_sync == 2'b01) ? IMG_W / FATOR : IMG_W;
    
    assign IMG_H_AMP = (sw_sync == 2'b00) ? IMG_H * FATOR : 
                      (sw_sync == 2'b01) ? IMG_H / FATOR : IMG_H;

    // Registros para os offsets
    reg [9:0] x_offset_reg;
    reg [9:0] y_offset_reg;
    
    always @(posedge clk_vga) begin
        x_offset_reg <= (640 - IMG_W_AMP) / 2;
        y_offset_reg <= (480 - IMG_H_AMP) / 2;
    end

    // verifica se está dentro da área da imagem AMPLIADA
    wire in_image = (next_x >= x_offset_reg && next_x < x_offset_reg + IMG_W_AMP) &&
                    (next_y >= y_offset_reg && next_y < y_offset_reg + IMG_H_AMP);

    // endereço da RAM (para leitura durante display)
    reg [18:0] addr_reg;
    always @(posedge clk_vga) begin
        if (in_image)
            addr_reg <= (next_y - y_offset_reg) * IMG_W_AMP + (next_x - x_offset_reg);
        else
            addr_reg <= 0;
    end

    // framebuffer RAM
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

    // Detector de mudança no seletor para reiniciar o processo de cópia
    reg [1:0] sw_prev;
    wire sw_changed;
    
    always @(posedge clk_vga) begin
        sw_prev <= sw_sync;
    end
    
    assign sw_changed = (sw_sync != sw_prev);

    // copiador ROM → RAM com ampliação
    wire [18:0] wr_addr;
    wire [7:0] wr_data;
    wire wr_en;
    wire copy_done;
    
    rom_to_ram copier (
        .clk(clk_vga),
        .reset(vga_reset || sw_changed), // Reinicia quando houver reset OU mudança no seletor
        .seletor(sw_sync),
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
