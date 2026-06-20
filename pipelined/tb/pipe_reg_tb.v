module pipe_reg_tb;
    reg clk, rst_n, en, clear;
    reg  [7:0] d;
    wire [7:0] q;

    pipe_reg #(.WIDTH(8)) dut (.clk(clk), .rst_n(rst_n),
        .en(en), .clear(clear), .d(d), .q(q));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("pipe_reg.vcd"); $dumpvars(0, pipe_reg_tb);
        clk=0; rst_n=0; en=1; clear=0; d=0;
        #10 rst_n=1;

        d=8'd11; en=1; clear=0; #10;  $display("normal: d=11 -> q=%0d (expect 11)", q);
        d=8'd22; en=0; clear=0; #10;  $display("stall:  d=22 en=0 -> q=%0d (expect still 11)", q);
        d=8'd33; en=1; clear=0; #10;  $display("normal: d=33 -> q=%0d (expect 33)", q);
        d=8'd44; en=1; clear=1; #10;  $display("flush:  clear=1 -> q=%0d (expect 0)", q);
        $finish;
    end
endmodule
