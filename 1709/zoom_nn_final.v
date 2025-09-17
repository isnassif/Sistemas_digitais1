module zoom_nn #(
    parameter LARGURA = 160,
    parameter ALTURA  = 120,
    parameter FATOR   = 2
)(
    input clk,
    input reset,
    output reg [18:0] rom_addr,
    input [7:0] rom_data,
    output reg [18:0] ram_wraddr,
    output reg [7:0] ram_data,
    output reg ram_wren,
    output reg done
	 
);
    parameter NEW_LARG = LARGURA * FATOR;

    reg [7:0] rom_data_reg;
    reg [10:0] linha, coluna, di, dj;

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            linha <= 0; coluna <= 0; di <= 0; dj <= 0;
            rom_addr <= 0; ram_wraddr <= 0;
            rom_data_reg <= 0; ram_data <= 0;
            ram_wren <= 0; done <= 0;
        end else begin
            rom_data_reg <= rom_data;

            if (!done) begin
                ram_wren <= 1;
                ram_data <= rom_data_reg;

                // O endereço da ROM só avança quando começamos um novo pixel da fonte.
                if (di == 0 && dj == 0) begin
                    rom_addr <= linha * LARGURA + coluna;
                end
                
                ram_wraddr <= (linha * FATOR + di) * NEW_LARG + (coluna * FATOR + dj);

                // lógica de contadores
                if (dj == FATOR - 1) begin
                    dj <= 0;
                    if (di == FATOR - 1) begin
                        di <= 0;
                        if (coluna == LARGURA - 1) begin
                            coluna <= 0;
                            if (linha == ALTURA - 1) begin
                                linha <= 0;
                                done <= 1;
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

module copia #(
    parameter LARGURA = 160,
    parameter ALTURA  = 120,
    parameter FATOR   = 1, 

    parameter NEW_LARG   = LARGURA,
    parameter NEW_ALTURA = ALTURA,

    parameter LARGURA_ADDR = 15 
)(
    input clk,
    input reset,
    output reg [LARGURA_ADDR-1:0] rom_addr,
    input [7:0] rom_data,
    output reg [LARGURA_ADDR-1:0] ram_wraddr,
    output reg [7:0] ram_data,
    output reg ram_wren,
    output reg done
);

    

    reg [LARGURA_ADDR-1:0] contador;
    reg [7:0] rom_data_reg;

    localparam TOTAL_PIXELS = LARGURA * ALTURA;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            contador <= 0;
            rom_data_reg <= 0;
            ram_wren <= 1'b0;
            done <= 1'b0;
            ram_data <= 0;
            rom_addr <= 0;
            ram_wraddr <= 0;
        end else begin
            rom_data_reg <= rom_data;
            rom_addr   <= contador;
            ram_wraddr <= contador;

            if (!done) begin
                ram_wren <= 1'b1;
                ram_data <= rom_data_reg;

                if (contador == TOTAL_PIXELS - 1) begin
                    done <= 1'b1;
                    ram_wren <= 1'b0;
                end else begin
                    contador <= contador + 1;
                end
            end else begin
                ram_wren <= 1'b0;
            end
        end
    end

endmodule
