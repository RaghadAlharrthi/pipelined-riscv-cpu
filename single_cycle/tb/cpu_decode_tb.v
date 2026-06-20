module cpu_decode_tb;
    reg clk, rst_n;
    wire [31:0] pc, instr, rs1_data, rs2_data, imm;
    wire reg_write, alu_src;

    cpu_decode dut (.clk(clk), .rst_n(rst_n), .pc(pc), .instr(instr),
        .rs1_data(rs1_data), .rs2_data(rs2_data), .imm(imm),
        .reg_write(reg_write), .alu_src(alu_src));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("cpu_decode.vcd");
        $dumpvars(0, cpu_decode_tb);
        clk = 0; rst_n = 0;
        #10 rst_n = 1;
        repeat (4) begin
            #10 $display("PC=%0d | imm=%0d reg_write=%b alu_src=%b rs1_data=%0d rs2_data=%0d",
                         pc, $signed(imm), reg_write, alu_src, rs1_data, rs2_data);
        end
        $finish;
    end
endmodule
