// hazard.v — detects load-use hazard, generates stall signal
module hazard (
    input  wire        ex_mem_read,  // is the instr in EX a load?
    input  wire [4:0]  ex_rd,        // dest reg of the load in EX
    input  wire [4:0]  id_rs1,       // source regs of instr in ID
    input  wire [4:0]  id_rs2,
    output reg         stall          // 1 = freeze pipeline one cycle
);
    always @(*) begin
        // load in EX, and the ID instruction needs its result -> stall
        if (ex_mem_read && ex_rd != 0 &&
            (ex_rd == id_rs1 || ex_rd == id_rs2))
            stall = 1'b1;
        else
            stall = 1'b0;
    end
endmodule
