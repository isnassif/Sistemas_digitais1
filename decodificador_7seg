module decodificador_7seg (
    input  wire [3:0] binario, // entrada binária 0-9
    output reg  [6:0] seg      // segmentos a-g
);
       always @(*) begin
        case (binario)
            4'd0: seg = 7'b0000001; // a b c d e f on, g off
            4'd1: seg = 7'b1001111; // b c on
            4'd2: seg = 7'b0010010; // a b d e g on
            4'd3: seg = 7'b0000110; // a b c d g on
            4'd4: seg = 7'b1001100; // b c f g on
            4'd5: seg = 7'b0100100; // a c d f g on
            4'd6: seg = 7'b0100000; // a c d e f g on
            4'd7: seg = 7'b0001111; // a b c on
            4'd8: seg = 7'b0000000; // todos acesos
            4'd9: seg = 7'b0000100; // a b c d f g on
            default: seg = 7'b1111111; // todos apagados
        endcase
    end
endmodule
