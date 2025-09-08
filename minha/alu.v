module alu (
    input wire clk,
    input wire rst,
    input wire [3:0] mode,          // algoritmo escolhido
    input wire [7:0] pixel_in,      // pixel vindo do VGA controller (ROM ou line buffer)
    input wire pixel_in_valido,     // indica que pixel_in é válido
    output reg [7:0] pixel_out,     // pixel processado
    output reg pixel_out_valido     // indica que pixel_out é válido
);
    always @(posedge clk) begin
        if (rst) begin
            pixel_out <= 8'd0;
            pixel_out_valido <= 1'b0;
        end else begin
            case (mode)
                4'b0010: begin
                    // Replicação de pixel
                    pixel_out <= pixel_in;      // aqui você pode instanciar seu rep_pixel_stream_pt
                    pixel_out_valido <= pixel_in_valido;
                end
                4'b0001: begin
                    // Decimação (exemplo simplificado)
                    pixel_out <= pixel_in >> 1;
                    pixel_out_valido <= pixel_in_valido;
                end
                default: begin
                    pixel_out <= pixel_in;      // passa direto (imagem original)
                    pixel_out_valido <= pixel_in_valido;
                end
            endcase
        end
    end
endmodule
