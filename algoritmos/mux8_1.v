module mux8_1 (
	 input wire [7:0] d0,
    input wire [7:0] d1,
    input wire [7:0] d2,
    input wire [7:0] d3,
    input wire [7:0] d4,
    input wire [7:0] d5,
    input wire [7:0] d6,
    input wire [7:0] d7,

    input wire [2:0] sel,

    output reg [7:0] z
);

    
    always @(*) begin
        case (sel)
            3'b000: z = d0;
            3'b001: z = d1;
            3'b010: z = d2;
				3'b011: z = d3;
				3'b100: z = d4;
				3'b101: z = d5;
				3'b110: z = d6;
				3'b111: z = d7;
				
            default: z = 8'h00; 
        endcase
    end

endmodule




);