module register_tb;
    reg         clk, rst_n, we;
    reg  [31:0] d;
    wire [31:0] q;

    register dut (.clk(clk), .rst_n(rst_n), .we(we), .d(d), .q(q));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("register.vcd");
        $dumpvars(0, register_tb);
        clk = 0; rst_n = 0; we = 0; d = 0;
        #10;
        rst_n = 1;
        d = 32'd25; we = 1; #10;
        d = 32'd99; we = 0; #10;
        d = 32'd99; we = 1; #10;
        d = 32'd7;  we = 1; #10;
        $finish;
    end

    initial $monitor("time=%0t rst_n=%b we=%b d=%0d q=%0d", $time, rst_n, we, d, q);
endmodule
