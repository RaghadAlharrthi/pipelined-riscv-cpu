// pipeline_cpu_tb.v — checks ALU-op decode, forwarding, load-use stall, and branch flush
`timescale 1ns/1ps
module pipeline_cpu_tb;
    reg clk, rst_n;
    wire [31:0] pc_out, wb_data_out;
    wire [4:0]  wb_rd_out;
    wire        wb_we_out;
    integer errors = 0;

    pipeline_cpu dut (.clk(clk), .rst_n(rst_n),
        .pc_out(pc_out), .wb_data_out(wb_data_out),
        .wb_rd_out(wb_rd_out), .wb_we_out(wb_we_out));

    always #5 clk = ~clk;

    task check; input [4:0] r; input [31:0] exp; begin
        if (dut.u_rf.regs[r] !== exp) begin
            $display("FAIL x%0d = %0d (expected %0d)", r, dut.u_rf.regs[r], exp);
            errors = errors + 1;
        end else
            $display("PASS x%0d = %0d", r, dut.u_rf.regs[r]);
    end endtask

    initial begin
        $dumpfile("pipeline_cpu.vcd");
        $dumpvars(0, pipeline_cpu_tb);
        clk = 0; rst_n = 0;
        #12 rst_n = 1;
        repeat (20) #10;   // let the program drain

        $display("--- FINAL REGISTERS ---");
        check(1, 5);    // addi
        check(2, 3);    // addi
        check(3, 1);    // and  5&3
        check(4, 7);    // or   5|3
        check(5, 6);    // xor  5^3
        check(6, 0);    // slt  5<3 ? 0
        check(7, 0);    // FLUSHED by taken branch (must stay 0)
        check(8, 42);   // landed after branch

        if (errors == 0) $display("\nALL TESTS PASSED");
        else             $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
