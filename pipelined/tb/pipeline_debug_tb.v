module pipeline_debug_tb;
    reg clk, rst_n;
    wire [31:0] pc_out, wb_data_out;
    wire [4:0]  wb_rd_out;
    wire        wb_we_out;

    pipeline_cpu dut (.clk(clk), .rst_n(rst_n),
        .pc_out(pc_out), .wb_data_out(wb_data_out),
        .wb_rd_out(wb_rd_out), .wb_we_out(wb_we_out));

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0;
        #10 rst_n = 1;
        repeat (10) begin
            #10;
            $display("t=%0t EX_rs1=%0d EX_rs1_data=%0d fwd_a=%b ex_a=%0d | MEM_rd=%0d MEM_we=%b MEM_alu=%0d",
                $time, dut.EX_rs1, dut.EX_rs1_data, dut.forward_a, dut.ex_a,
                dut.MEM_rd, dut.MEM_reg_write, dut.MEM_alu_result);
        end
        $finish;
    end
endmodule
