// forwarding.v — decides whether to forward ALU operands from later stages
module forwarding (
    input  wire [4:0] ex_rs1,        // source reg 1 needed in EX
    input  wire [4:0] ex_rs2,        // source reg 2 needed in EX
    input  wire [4:0] mem_rd,        // dest reg of instr in MEM stage
    input  wire       mem_reg_write, // does MEM-stage instr write a reg?
    input  wire [4:0] wb_rd,         // dest reg of instr in WB stage
    input  wire       wb_reg_write,  // does WB-stage instr write a reg?
    output reg  [1:0] forward_a,     // control for ALU input A
    output reg  [1:0] forward_b      // control for ALU input B
);
    // 2'b00 = use register file value (normal)
    // 2'b10 = forward from MEM stage (freshest)
    // 2'b01 = forward from WB stage
    always @(*) begin
        // ---- Forward A (for rs1) ----
        if (mem_reg_write && mem_rd != 0 && mem_rd == ex_rs1)
            forward_a = 2'b10;                 // MEM forward (priority)
        else if (wb_reg_write && wb_rd != 0 && wb_rd == ex_rs1)
            forward_a = 2'b01;                 // WB forward
        else
            forward_a = 2'b00;                 // no forward

        // ---- Forward B (for rs2) ----
        if (mem_reg_write && mem_rd != 0 && mem_rd == ex_rs2)
            forward_b = 2'b10;
        else if (wb_reg_write && wb_rd != 0 && wb_rd == ex_rs2)
            forward_b = 2'b01;
        else
            forward_b = 2'b00;
    end
endmodule
