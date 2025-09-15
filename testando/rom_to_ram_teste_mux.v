module rom_to_ram (
    input clk,
    input reset,
    input [1:0] seletor, // 00: replicação, 01: decimação, 10: vizinho, 11: média
    output reg [18:0] rom_addr,
    input [7:0] rom_data,
    output reg [18:0] ram_wraddr,
    output reg [7:0] ram_data,
    output reg ram_wren,
    output reg done
);

    // Fios para conectar ao módulo de replicação
    wire [18:0] rom_addr_rep;
    wire [18:0] ram_wraddr_rep;
    wire [7:0] ram_data_rep;
    wire ram_wren_rep;
    wire done_rep;
    
    // Instância do módulo de replicação
    rep_pixel rep_inst(
        .clk(clk),
        .reset(reset),
        .rom_addr(rom_addr_rep),
        .rom_data(rom_data),       // Conecta diretamente à entrada
        .ram_wraddr(ram_wraddr_rep),
        .ram_data(ram_data_rep),
        .ram_wren(ram_wren_rep),
        .done(done_rep)
    );
    
    // Multiplexador - por enquanto só temos replicação
    always @(*) begin
        case(seletor)
            2'b00: begin  // REPLICAÇÃO
                rom_addr = rom_addr_rep;
                ram_wraddr = ram_wraddr_rep;
                ram_data = ram_data_rep;
                ram_wren = ram_wren_rep;
                done = done_rep;
            end
            default: begin  // Default também para replicação
                rom_addr = rom_addr_rep;
                ram_wraddr = ram_wraddr_rep;
                ram_data = ram_data_rep;
                ram_wren = ram_wren_rep;
                done = done_rep;
            end
        endcase
    end

endmodule

// Módulo de replicação de pixel
module rep_pixel(
    input clk,
    input reset,
    output reg [18:0] rom_addr,
    input [7:0] rom_data,          // Remove seletor daqui
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
                                ram_wren <= 0; // Finaliza escrita
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
                ram_wren <= 0; // Mantém wren desativado após conclusão
            end
        end
    end

endmodule
