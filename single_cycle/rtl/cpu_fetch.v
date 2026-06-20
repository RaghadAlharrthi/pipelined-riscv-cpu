// cpu_fetch.v — Layer 1: Program Counter + Instruction Memory
module cpu_fetch (
    input  wire        clk,
    input  wire        rst_n,
    output wire [31:0] pc,          // current instruction address
    output wire [31:0] instr        // the fetched instruction
);
    // --- Program Counter: a register holding the address ---
    reg [31:0] pc_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc_reg <= 32'd0;        // start at address 0
        else
            pc_reg <= pc_reg + 32'd4;   // advance to next instruction
    end
    assign pc = pc_reg;

    // --- Instruction Memory: holds the program ---
    reg [31:0] imem [0:15];         // 16 instructions of space

    // load a tiny test program into memory at startup
    initial begin
        // addi x1, x0, 5    -> x1 = 5
        imem[0] = 32'b000000000101_00000_000_00001_0010011;
        // addi x2, x0, 7    -> x2 = 7
        imem[1] = 32'b000000000111_00000_000_00010_0010011;
        // add  x3, x1, x2   -> x3 = x1 + x2 = 12
        imem[2] = 32'b0000000_00010_00001_000_00011_0110011;
        // addi x4, x3, 1    -> x4 = x3 + 1 = 13
        imem[3] = 32'b000000000001_00011_000_00100_0010011;
        imem[4] = 32'd0;            // padding
    end

    // fetch: instruction at address pc (divide by 4 to get the index)
    assign instr = imem[pc_reg[31:2]];
endmodule
