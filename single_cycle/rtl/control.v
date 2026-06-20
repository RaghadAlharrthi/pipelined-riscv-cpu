// control.v — main decoder: reads opcode, sets control signals
module control (
    input  wire [6:0] opcode,      // bottom 7 bits of the instruction
    output reg        reg_write,   // write result to a register?
    output reg        alu_src,     // 1 = use immediate, 0 = use register
    output reg        mem_read,    // reading data memory?
    output reg        mem_write,   // writing data memory?
    output reg        branch,      // is this a branch?
    output reg  [1:0] imm_type     // which immediate format
);
    always @(*) begin
        // safe defaults (everything off)
        reg_write = 0; alu_src = 0; mem_read = 0;
        mem_write = 0; branch = 0; imm_type = 2'd0;

        case (opcode)
            7'b0110011: begin   // R-type (add, sub, and, or...) reg-reg
                reg_write = 1; alu_src = 0;
            end
            7'b0010011: begin   // I-type ALU (addi, andi...) reg-immediate
                reg_write = 1; alu_src = 1; imm_type = 2'd0;
            end
            7'b0000011: begin   // Load (lw): reg = mem[reg + imm]
                reg_write = 1; alu_src = 1; mem_read = 1; imm_type = 2'd0;
            end
            7'b0100011: begin   // Store (sw): mem[reg + imm] = reg
                alu_src = 1; mem_write = 1; imm_type = 2'd1;
            end
            7'b1100011: begin   // Branch (beq...)
                branch = 1; alu_src = 0; imm_type = 2'd2;
            end
            default: begin
                // unknown opcode: keep everything off
            end
        endcase
    end
endmodule
