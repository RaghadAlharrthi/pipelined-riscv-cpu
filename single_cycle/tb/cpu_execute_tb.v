module cpu_execute_tb;
    reg clk, rst_n;
    wire [31:0] pc, instr, alu_result;
    wire reg_write;
    wire [4:0] rd;

    cpu_execute dut (.clk(clk), .rst_n(rst_n), .pc(pc), .instr(instr),
        .alu_result(alu_result), .reg_write(reg_write), .rd(rd));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("cpu_execute.vcd");
        $dumpvars(0, cpu_execute_tb);
        clk = 0; rst_n = 0;
        #10 rst_n = 1;
        repeat (4) begin
            #10 $display("PC=%0d | rd=x%0d  alu_result=%0d  reg_write=%b",
                         pc, rd, alu_result, reg_write);
        end
        $finish;
    end
endmodule
