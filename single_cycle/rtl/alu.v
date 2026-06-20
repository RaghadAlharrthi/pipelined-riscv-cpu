// alu.v — Arithmetic Logic Unit for RV32I
module alu (
    input  wire [31:0] a,          // first operand
    input  wire [31:0] b,          // second operand
    input  wire [3:0]  alu_op,     // which operation to perform
    output reg  [31:0] result,     // the answer
    output wire        zero        // 1 if result == 0 (used by branches later)
);
    always @(*) begin              // combinational: recompute whenever inputs change
        case (alu_op)
            4'd0: result = a + b;                         // ADD
            4'd1: result = a - b;                         // SUB
            4'd2: result = a & b;                         // AND
            4'd3: result = a | b;                         // OR
            4'd4: result = a ^ b;                         // XOR
            4'd5: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;  // SLT
            4'd6: result = a << b[4:0];                   // shift left
            4'd7: result = a >> b[4:0];                   // shift right
            default: result = 32'd0;
        endcase
    end

    assign zero = (result == 32'd0);   // flag: is the result zero?
endmodule
