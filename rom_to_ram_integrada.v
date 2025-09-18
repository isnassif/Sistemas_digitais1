module rom_to_ram (
    input clk,
    input reset,                // reset top-level (ativo baixo)
    input [3:0] seletor,        // 0000: original, 0001: replicação, 0010: decimação, 0011: zoom_nn
    output reg saida,
    output reg [18:0] rom_addr,
    input [7:0] rom_data,
    output reg [18:0] ram_wraddr,
    output reg [7:0] ram_data,
    output reg ram_wren,
    output reg done
);

    // Estados da máquina
    reg [3:0] state;
    parameter ST_ORIGINAL   = 4'b0000,
              ST_REPLICACAO = 4'b0001,
              ST_DECIMACAO  = 4'b0010,
              ST_ZOOMNN     = 4'b0011,
              ST_RESET_OR   = 4'b0100,
              ST_RESET_REP  = 4'b0101,
              ST_RESET_DEC  = 4'b0110,
              ST_RESET_ZNN  = 4'b0111,
              ST_RESET      = 4'b1000;

    // Fios dos submódulos
    wire [18:0] rom_addr_rep;
    wire [18:0] ram_wraddr_rep;
    wire [7:0]  ram_data_rep;
    wire        ram_wren_rep;
    wire        done_rep;
     
    wire [18:0] rom_addr_dec;
    wire [18:0] ram_wraddr_dec;
    wire [7:0]  ram_data_dec;
    wire        done_dec;

    wire [18:0] rom_addr_zoom;
    wire [18:0] ram_wraddr_zoom;
    wire [7:0]  ram_data_zoom;
    wire        ram_wren_zoom;
    wire        done_zoom;

    // Resets dedicados para cada submódulo (active-low)
    reg reset_rep;
    reg reset_dec;
    reg reset_zoom;

    // Instâncias dos submódulos
    rep_pixel rep_inst(
        .clk(clk),
        .reset(reset_rep),
        .rom_addr(rom_addr_rep),
        .rom_data(rom_data),
        .ram_wraddr(ram_wraddr_rep),
        .ram_data(ram_data_rep),
        .ram_wren(ram_wren_rep),
        .done(done_rep)
    );
     
    decimacao dec_inst(
        .clk(clk),
        .rst(reset_dec),
        .pixel_rom(rom_data),
        .rom_addr(rom_addr_dec),
        .addr_ram_vga(ram_wraddr_dec),
        .pixel_saida(ram_data_dec),
        .done(done_dec)
    );

    zoom_nn zoom_inst(
        .clk(clk),
        .reset(reset_zoom),
        .rom_addr(rom_addr_zoom),
        .rom_data(rom_data),
        .ram_wraddr(ram_wraddr_zoom),
        .ram_data(ram_data_zoom),
        .ram_wren(ram_wren_zoom),
        .done(done_zoom)
    );

    initial begin
        state <= ST_ORIGINAL;
        saida <= 1'b0;
        rom_addr <= 0;
        ram_wraddr <= 0;
        ram_data <= 0;
        ram_wren <= 0;
        done <= 0;
        reset_rep <= 1'b0;
        reset_dec <= 1'b0;
        reset_zoom <= 1'b0;
    end

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            // Reset top-level: força todos os submódulos em reset
            state <= ST_RESET;
            saida <= 1'b0;
            rom_addr <= 0;
            ram_wraddr <= 0;
            ram_data <= 0;
            ram_wren <= 0;
            done <= 0;
            reset_rep <= 1'b0;
            reset_dec <= 1'b0;
            reset_zoom <= 1'b0;
        end else begin
            case(state)

                // --- Reset geral do topo ---
                ST_RESET: begin
                    reset_rep  <= 1'b0;
                    reset_dec  <= 1'b0;
                    reset_zoom <= 1'b0;
                    rom_addr   <= 0;
                    ram_wraddr <= 0;
                    ram_data   <= 0;
                    ram_wren   <= 0;
                    done       <= 0;
                    state <= ST_ORIGINAL;
                end

                // --- Reset do ORIGINAL (intermediário) ---
                ST_RESET_OR: begin
                    reset_rep  <= 1'b1;
                    reset_dec  <= 1'b1;
                    reset_zoom <= 1'b1;
                    rom_addr   <= 0;
                    ram_wraddr <= 0;
                    ram_data   <= 0;
                    ram_wren   <= 0;
                    done       <= 0;
                    state <= ST_ORIGINAL;
                end

                // --- Reset específico dos submódulos (pulso de 1 ciclo) ---
                ST_RESET_REP: begin
                    reset_rep  <= 1'b0; // ativa reset
                    reset_dec  <= 1'b1;
                    reset_zoom <= 1'b1;
                    rom_addr   <= 0;
                    ram_wraddr <= 0;
                    ram_data   <= 0;
                    ram_wren   <= 0;
                    done       <= 0;
                    state <= ST_REPLICACAO;
                end

                ST_RESET_DEC: begin
                    reset_rep  <= 1'b1;
                    reset_dec  <= 1'b0;
                    reset_zoom <= 1'b1;
                    rom_addr   <= 0;
                    ram_wraddr <= 0;
                    ram_data   <= 0;
                    ram_wren   <= 0;
                    done       <= 0;
                    state <= ST_DECIMACAO;
                end

                ST_RESET_ZNN: begin
                    reset_rep  <= 1'b1;
                    reset_dec  <= 1'b1;
                    reset_zoom <= 1'b0;
                    rom_addr   <= 0;
                    ram_wraddr <= 0;
                    ram_data   <= 0;
                    ram_wren   <= 0;
                    done       <= 0;
                    state <= ST_ZOOMNN;
                end

                // --- Estado intermediário ORIGINAL ---
                ST_ORIGINAL: begin
                    reset_rep  <= 1'b1;
                    reset_dec  <= 1'b1;
                    reset_zoom <= 1'b1;
                    rom_addr   <= 0;
                    ram_wraddr <= 0;
                    ram_data   <= 0;
                    ram_wren   <= 0;
                    done       <= 0;

                    // seleciona o próximo módulo
                    case(seletor)
                        4'b0001: state <= ST_RESET_REP;
                        4'b0010: state <= ST_RESET_DEC;
                        4'b0011: state <= ST_RESET_ZNN;
                        default: state <= ST_ORIGINAL;
                    endcase
                end

                // --- Operação Replicação ---
                ST_REPLICACAO: begin
                    reset_rep  <= 1'b1;
                    reset_dec  <= 1'b1;
                    reset_zoom <= 1'b1;
                    rom_addr   <= rom_addr_rep;
                    ram_wraddr <= ram_wraddr_rep;
                    ram_data   <= ram_data_rep;
                    ram_wren   <= ram_wren_rep;
                    done       <= done_rep;

                    // só muda se o seletor mudar
                    if (seletor == 4'b0000) begin
								state <= ST_RESET_OR;
						  end
                end

                // --- Operação Decimacao ---
                ST_DECIMACAO: begin
                    reset_rep  <= 1'b1;
                    reset_dec  <= 1'b1;
                    reset_zoom <= 1'b1;
                    rom_addr   <= rom_addr_dec;
                    ram_wraddr <= ram_wraddr_dec;
                    ram_data   <= ram_data_dec;
                    ram_wren   <= 1'b1; // assume que sempre escreve
                    done       <= done_dec;

                    if (seletor == 4'b0000) begin
								state <= ST_RESET_OR;
						  end
                end

                // --- Operação ZoomNN ---
                ST_ZOOMNN: begin
                    reset_rep  <= 1'b1;
                    reset_dec  <= 1'b1;
                    reset_zoom <= 1'b1;
                    rom_addr   <= rom_addr_zoom;
                    ram_wraddr <= ram_wraddr_zoom;
                    ram_data   <= ram_data_zoom;
                    ram_wren   <= ram_wren_zoom;
                    done       <= done_zoom;

                    if (seletor == 4'b0000) begin
								state <= ST_RESET_OR;
						  end
                end

                default: state <= ST_ORIGINAL;

            endcase
        end
    end

endmodule
