// alu_control.v — picks the ALU operation from opcode + funct3 + funct7[5]
// ALU op encoding (must match alu.v):
//   0 ADD  1 SUB  2 AND  3 OR  4 XOR  5 SLT  6 SLL  7 SRL
module alu_control (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire       funct7_5,   // instr[30] — distinguishes add/sub, srl/sra
    output reg  [3:0] alu_op
);
    localparam OP_ADD=4'd0, OP_SUB=4'd1, OP_AND=4'd2, OP_OR=4'd3,
               OP_XOR=4'd4, OP_SLT=4'd5, OP_SLL=4'd6, OP_SRL=4'd7;

    always @(*) begin
        case (opcode)
            // R-type: full funct3 decode; funct7[5] selects sub / shift-right type
            7'b0110011: begin
                case (funct3)
                    3'b000: alu_op = funct7_5 ? OP_SUB : OP_ADD; // add / sub
                    3'b111: alu_op = OP_AND;
                    3'b110: alu_op = OP_OR;
                    3'b100: alu_op = OP_XOR;
                    3'b010: alu_op = OP_SLT;
                    3'b001: alu_op = OP_SLL;
                    3'b101: alu_op = OP_SRL;          // srl (sra not yet modelled)
                    default: alu_op = OP_ADD;
                endcase
            end
            // I-type ALU (addi, andi, ori, xori, slti, slli, srli)
            7'b0010011: begin
                case (funct3)
                    3'b000: alu_op = OP_ADD;          // addi
                    3'b111: alu_op = OP_AND;
                    3'b110: alu_op = OP_OR;
                    3'b100: alu_op = OP_XOR;
                    3'b010: alu_op = OP_SLT;
                    3'b001: alu_op = OP_SLL;
                    3'b101: alu_op = OP_SRL;
                    default: alu_op = OP_ADD;
                endcase
            end
            // loads / stores: ALU computes base+offset address
            7'b0000011, 7'b0100011: alu_op = OP_ADD;
            // branches: ALU not used for the comparison (done in EX directly)
            7'b1100011: alu_op = OP_SUB;
            default:    alu_op = OP_ADD;
        endcase
    end
endmodule
