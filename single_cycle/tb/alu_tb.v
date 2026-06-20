module alu_tb;
    reg  [31:0] a, b;
    reg  [3:0]  alu_op;
    wire [31:0] result;
    wire        zero;

    alu dut (.a(a), .b(b), .alu_op(alu_op), .result(result), .zero(zero));

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);

        a = 32'd10; b = 32'd3;

        alu_op = 4'd0; #10; $display("ADD: 10 + 3  = %0d  (zero=%b)", result, zero);
        alu_op = 4'd1; #10; $display("SUB: 10 - 3  = %0d  (zero=%b)", result, zero);
        alu_op = 4'd2; #10; $display("AND: 10 & 3  = %0d", result);
        alu_op = 4'd3; #10; $display("OR:  10 | 3  = %0d", result);
        alu_op = 4'd4; #10; $display("XOR: 10 ^ 3  = %0d", result);
        alu_op = 4'd5; #10; $display("SLT: 10 < 3  = %0d", result);
        alu_op = 4'd6; #10; $display("SLL: 10 << 3 = %0d", result);
        alu_op = 4'd7; #10; $display("SRL: 10 >> 3 = %0d", result);

        // test the zero flag: 5 - 5 = 0
        a = 32'd5; b = 32'd5; alu_op = 4'd1; #10;
        $display("SUB: 5 - 5   = %0d  (zero=%b)  <-- zero flag should be 1", result, zero);

        $finish;
    end
endmodule
