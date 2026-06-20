module immgen_tb;
    reg  [31:0] instr;
    reg  [2:0]  imm_type;
    wire [31:0] imm;

    immgen dut (.instr(instr), .imm_type(imm_type), .imm(imm));

    initial begin
        $dumpfile("immgen.vcd");
        $dumpvars(0, immgen_tb);

        // a real "addi x1, x0, 5" instruction (I-type). imm field = 5.
        // encoding: imm=000000000101, rs1=00000, f3=000, rd=00001, op=0010011
        instr = 32'b000000000101_00000_000_00001_0010011;
        imm_type = 3'd0;  #10;
        $display("I-type imm (expect 5):   %0d", $signed(imm));

        // a NEGATIVE I-type immediate: imm = -1 (all ones in 12 bits)
        instr = 32'b111111111111_00000_000_00001_0010011;
        imm_type = 3'd0;  #10;
        $display("I-type imm (expect -1):  %0d", $signed(imm));

        $finish;
    end
endmodule
