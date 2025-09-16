module rom_to_ram (
    input clk,
    input reset,
    input [1:0] seletor,// 00: replicação, 01: decimação, 10: vizinho, 11: média
    output reg saida,
    output reg [18:0] rom_addr,
    input [7:0] rom_data,
    output reg [18:0] ram_wraddr,
    output reg [7:0] ram_data,
    output reg ram_wren,
    output reg done
);

    reg [1:0] state;
    parameter REPLICACAO = 2'b00,
              DECIMACAO  = 2'b01;
              
    // Fios para conectar aos módulos
    wire [18:0] rom_addr_rep;
    wire [18:0] ram_wraddr_rep;
    wire [7:0] ram_data_rep;
    wire ram_wren_rep;
    wire done_rep;
     
    wire [18:0] rom_addr_dec;
    wire [18:0] ram_wraddr_dec;
    wire [7:0] ram_data_dec;
    wire done_dec;
    
    // Instância do módulo de replicação
    rep_pixel rep_inst(
        .clk(clk),
        .reset(reset),
        .rom_addr(rom_addr_rep),
        .rom_data(rom_data),
        .ram_wraddr(ram_wraddr_rep),
        .ram_data(ram_data_rep),
        .ram_wren(ram_wren_rep),
        .done(done_rep)
    );
     
    // Instância do módulo de decimação
    decimacao dec_inst(
        .clk(clk),
        .rst(reset),
        .pixel_rom(rom_data),
        .rom_addr(rom_addr_dec),
        .addr_ram_vga(ram_wraddr_dec),
        .pixel_saida(ram_data_dec),
        .done(done_dec)
    );
     
    wire ram_wren_dec_wire;
    assign ram_wren_dec_wire = ~done_dec;

    // Inicialização
    initial begin
        state <= REPLICACAO;
        saida <= 1'b0;
        rom_addr <= 0;
        ram_wraddr <= 0;
        ram_data <= 0;
        ram_wren <= 0;
        done <= 0;
    end

    // Máquina de estados
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= REPLICACAO;
            saida <= 1'b0;
            rom_addr <= 0;
            ram_wraddr <= 0;
            ram_data <= 0;
            ram_wren <= 0;
            done <= 0;
        end else begin
            case(state)
                REPLICACAO: begin
                    rom_addr <= rom_addr_rep;
                    ram_wraddr <= ram_wraddr_rep;
                    ram_data <= ram_data_rep;
                    ram_wren <= ram_wren_rep;
                    done <= done_rep;
                    
                    if (seletor == 2'b01) begin
                        state <= DECIMACAO;
                    end
                end
                
                DECIMACAO: begin
                    rom_addr <= rom_addr_dec;
                    ram_wraddr <= ram_wraddr_dec;
                    ram_data <= ram_data_dec;
                    ram_wren <= ram_wren_dec_wire;
                    done <= done_dec;
                    
                    if (seletor == 2'b00) begin
                        state <= REPLICACAO;
                    end
                end
                
                default: begin
                    state <= REPLICACAO;
                end
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

    always @(posedge clk or posedge reset) begin
        if (reset) begin
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

    always @(posedge clk or posedge rst) begin
        if (rst) begin
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
