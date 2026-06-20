module cpu_fetch_tb;
    reg clk, rst_n;
    wire [31:0] pc, instr;

    cpu_fetch dut (.clk(clk), .rst_n(rst_n), .pc(pc), .instr(instr));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("cpu_fetch.vcd");
        $dumpvars(0, cpu_fetch_tb);
        clk = 0; rst_n = 0;
        #10 rst_n = 1;

        // run for a few cycles, watch PC advance and instructions fetch
        repeat (5) begin
            #10 $display("PC=%0d  instr=%b", pc, instr);
        end

        $finish;
    end
endmodule
