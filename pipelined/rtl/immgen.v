// immgen.v — Immediate Generator: extracts & sign-extends immediates
module immgen (
    input  wire [31:0] instr,      // the full 32-bit instruction
    input  wire [2:0]  imm_type,   // which format: 0=I,1=S,2=B,3=U,4=J
    output reg  [31:0] imm          // the reconstructed 32-bit immediate
);
    always @(*) begin
        case (imm_type)
            // I-type (e.g. addi, loads): imm is bits [31:20]
            3'd0: imm = {{20{instr[31]}}, instr[31:20]};

            // S-type (stores): imm split across [31:25] and [11:7]
            3'd1: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            // B-type (branches): imm scattered, lowest bit always 0
            3'd2: imm = {{19{instr[31]}}, instr[31], instr[7],
                         instr[30:25], instr[11:8], 1'b0};

            // U-type (lui, auipc): imm is the upper 20 bits, shifted
            3'd3: imm = {instr[31:12], 12'b0};

            // J-type (jal): imm scattered, lowest bit always 0
            3'd4: imm = {{11{instr[31]}}, instr[31], instr[19:12],
                         instr[20], instr[30:21], 1'b0};

            default: imm = 32'd0;
        endcase
    end
endmodule
