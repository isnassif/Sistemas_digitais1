module rom_to_ram (
    input clk,
    input reset,
    output reg [18:0] rom_addr,
    input [7:0] rom_data,
    output reg [18:0] ram_wraddr,
    output reg [7:0] ram_data,
    output reg ram_wren,
    output reg done
);

    parameter TOTAL_PIXELS = 160*120; // 307200

    reg [18:0] counter;

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            counter <= 0;
            rom_addr <= 0;
            ram_wraddr <= 0;
            ram_data <= 0;
            ram_wren <= 0;
            done <= 0;
        end
        else begin
            if (counter < TOTAL_PIXELS) begin
                // Copia um pixel por ciclo
                rom_addr <= counter;
                ram_wraddr <= counter;
                ram_data <= rom_data;
                ram_wren <= 1;
                counter <= counter + 1;
            end
            else begin
                ram_wren <= 0;
                done <= 1; // cópia finalizada
            end
        end
    end

endmodule
