module pipeline_cpu_tb;
    reg clk, rst_n;
    wire [31:0] pc_out, wb_data_out;
    wire [4:0]  wb_rd_out;
    wire        wb_we_out;

    pipeline_cpu dut (.clk(clk), .rst_n(rst_n),
        .pc_out(pc_out), .wb_data_out(wb_data_out),
        .wb_rd_out(wb_rd_out), .wb_we_out(wb_we_out));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("pipeline_cpu.vcd");
        $dumpvars(0, pipeline_cpu_tb);
        clk = 0; rst_n = 0;
        #10 rst_n = 1;
        repeat (14) #10;

        $display("--- FINAL REGISTERS ---");
        $display("x1 = %0d (expect 100)", dut.u_rf.regs[1]);
        $display("x2 = %0d (expect 200)", dut.u_rf.regs[2]);
        $display("x3 = %0d (expect 5)",   dut.u_rf.regs[3]);
        $display("x4 = %0d (expect 205)", dut.u_rf.regs[4]);
        $finish;
    end
endmodule
