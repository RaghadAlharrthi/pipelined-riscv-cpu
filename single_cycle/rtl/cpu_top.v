// cpu_top.v — Complete single-cycle CPU (Fetch+Decode+Execute+Writeback)
module cpu_top (
    input  wire clk,
    input  wire rst_n,
    output wire [31:0] pc,
    output wire [31:0] instr,
    output wire [31:0] wb_data,     // value written back this cycle
    output wire [4:0]  rd,
    output wire        reg_write
);
    // ---------- FETCH ----------
    reg [31:0] pc_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) pc_reg <= 32'd0;
        else        pc_reg <= pc_reg + 32'd4;
    end
    assign pc = pc_reg;

    reg [31:0] imem [0:15];
    initial begin
        imem[0] = 32'b000000000101_00000_000_00001_0010011; // addi x1,x0,5
        imem[1] = 32'b000000000111_00000_000_00010_0010011; // addi x2,x0,7
        imem[2] = 32'b0000000_00010_00001_000_00011_0110011; // add x3,x1,x2
        imem[3] = 32'b000000000001_00011_000_00100_0010011; // addi x4,x3,1
        imem[4] = 32'd0;
    end
    assign instr = imem[pc_reg[31:2]];

    // ---------- DECODE ----------
    wire [6:0] opcode = instr[6:0];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];
    assign     rd     = instr[11:7];
    wire       funct7_5 = instr[30];

    wire alu_src, mem_read, mem_write, branch;
    wire [1:0] imm_type;
    control u_ctrl (
        .opcode(opcode), .reg_write(reg_write), .alu_src(alu_src),
        .mem_read(mem_read), .mem_write(mem_write),
        .branch(branch), .imm_type(imm_type)
    );

    wire [31:0] rs1_data, rs2_data;
    regfile u_rf (
        .clk(clk),
        .we(reg_write),          // <-- WRITEBACK: enable writing
        .ra1(rs1), .ra2(rs2),
        .wa(rd),                 // <-- write to the destination register
        .wd(wb_data),            // <-- write the result back
        .rd1(rs1_data), .rd2(rs2_data)
    );

    wire [31:0] imm;
    immgen u_imm (.instr(instr), .imm_type({1'b0, imm_type}), .imm(imm));

    // ---------- EXECUTE ----------
    wire [31:0] alu_b = alu_src ? imm : rs2_data;
    wire [3:0]  alu_op = (opcode == 7'b0110011 && funct7_5) ? 4'd1 : 4'd0;
    wire [31:0] alu_result;
    wire        alu_zero;
    alu u_alu (.a(rs1_data), .b(alu_b), .alu_op(alu_op),
               .result(alu_result), .zero(alu_zero));

    // ---------- WRITEBACK ----------
    assign wb_data = alu_result;   // result flows back to the register file
endmodule
