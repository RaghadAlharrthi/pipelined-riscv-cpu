module control_tb;
    reg  [6:0] opcode;
    wire reg_write, alu_src, mem_read, mem_write, branch;
    wire [1:0] imm_type;

    control dut (.opcode(opcode), .reg_write(reg_write), .alu_src(alu_src),
                 .mem_read(mem_read), .mem_write(mem_write),
                 .branch(branch), .imm_type(imm_type));

    initial begin
        $dumpfile("control.vcd");
        $dumpvars(0, control_tb);

        opcode = 7'b0110011; #10;   // R-type
        $display("R-type : reg_write=%b alu_src=%b mem_read=%b mem_write=%b branch=%b",
                 reg_write, alu_src, mem_read, mem_write, branch);

        opcode = 7'b0010011; #10;   // I-type (addi)
        $display("addi   : reg_write=%b alu_src=%b mem_read=%b mem_write=%b branch=%b",
                 reg_write, alu_src, mem_read, mem_write, branch);

        opcode = 7'b0000011; #10;   // Load
        $display("load   : reg_write=%b alu_src=%b mem_read=%b mem_write=%b branch=%b",
                 reg_write, alu_src, mem_read, mem_write, branch);

        opcode = 7'b0100011; #10;   // Store
        $display("store  : reg_write=%b alu_src=%b mem_read=%b mem_write=%b branch=%b",
                 reg_write, alu_src, mem_read, mem_write, branch);

        opcode = 7'b1100011; #10;   // Branch
        $display("branch : reg_write=%b alu_src=%b mem_read=%b mem_write=%b branch=%b",
                 reg_write, alu_src, mem_read, mem_write, branch);

        $finish;
    end
endmodule
