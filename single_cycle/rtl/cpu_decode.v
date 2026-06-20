// cpu_decode.v — Layer 1+2: Fetch + Decode wired together
module cpu_decode (
    input  wire clk,
    input  wire rst_n,
    output wire [31:0] pc,
    output wire [31:0] instr,
    // expose decoded info so we can watch it
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data,
    output wire [31:0] imm,
    output wire        reg_write,
    output wire        alu_src
);
    // ---------- FETCH (Layer 1) ----------
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

    // ---------- DECODE (Layer 2) ----------
    // slice the instruction fields
    wire [6:0] opcode = instr[6:0];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];
    wire [4:0] rd     = instr[11:7];

    // control unit reads the opcode
    wire mem_read, mem_write, branch;
    wire [1:0] imm_type;
    control u_ctrl (
        .opcode(opcode), .reg_write(reg_write), .alu_src(alu_src),
        .mem_read(mem_read), .mem_write(mem_write),
        .branch(branch), .imm_type(imm_type)
    );

    // register file reads rs1 and rs2 (write port unused for now)
    regfile u_rf (
        .clk(clk), .we(1'b0),
        .ra1(rs1), .ra2(rs2), .wa(5'd0), .wd(32'd0),
        .rd1(rs1_data), .rd2(rs2_data)
    );

    // immediate generator extracts the constant
    immgen u_imm (
        .instr(instr), .imm_type({1'b0, imm_type}), .imm(imm)
    );
endmodule
