module regfile_tb;
    reg         clk, we;
    reg  [4:0]  ra1, ra2, wa;
    reg  [31:0] wd;
    wire [31:0] rd1, rd2;

    regfile dut (.clk(clk), .we(we), .ra1(ra1), .ra2(ra2),
                 .wa(wa), .wd(wd), .rd1(rd1), .rd2(rd2));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("regfile.vcd");
        $dumpvars(0, regfile_tb);
        clk = 0; we = 0; ra1 = 0; ra2 = 0; wa = 0; wd = 0;
        #10;

        // write 100 into locker x5
        wa = 5'd5;  wd = 32'd100; we = 1; #10;

        // write 200 into locker x6
        wa = 5'd6;  wd = 32'd200; we = 1; #10;

        // stop writing, now read x5 and x6 at the same time
        we = 0; ra1 = 5'd5; ra2 = 5'd6; #10;

        // try to write 999 into x0 — should be IGNORED (x0 stays 0)
        wa = 5'd0; wd = 32'd999; we = 1; #10;
        we = 0; ra1 = 5'd0; ra2 = 5'd5; #10;   // read x0 (must be 0) and x5

        $finish;
    end

    initial $monitor("time=%0t we=%b wa=%0d wd=%0d | ra1=%0d->rd1=%0d  ra2=%0d->rd2=%0d",
                     $time, we, wa, wd, ra1, rd1, ra2, rd2);
endmodule
