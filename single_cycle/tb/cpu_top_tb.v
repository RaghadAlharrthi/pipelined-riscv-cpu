module cpu_top_tb;
    reg clk, rst_n;
    wire [31:0] pc, instr, wb_data;
    wire [4:0] rd;
    wire reg_write;

    cpu_top dut (.clk(clk), .rst_n(rst_n), .pc(pc), .instr(instr),
        .wb_data(wb_data), .rd(rd), .reg_write(reg_write));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("cpu_top.vcd");
        $dumpvars(0, cpu_top_tb);
        clk = 0; rst_n = 0;
        #10 rst_n = 1;
        repeat (5) begin
            #10 $display("PC=%0d | wrote x%0d = %0d", pc, rd, wb_data);
        end

        // show final register values
        $display("--- FINAL REGISTERS ---");
        $display("x1 = %0d (expect 5)",  dut.u_rf.regs[1]);
        $display("x2 = %0d (expect 7)",  dut.u_rf.regs[2]);
        $display("x3 = %0d (expect 12)", dut.u_rf.regs[3]);
        $display("x4 = %0d (expect 13)", dut.u_rf.regs[4]);
        $finish;
    end
endmodule
