// regfile.v — 32 x 32-bit register file, 2 read ports, 1 write port
module regfile (
    input  wire        clk,
    input  wire        we,          // write enable
    input  wire [4:0]  ra1,         // read address 1 (which locker to read)
    input  wire [4:0]  ra2,         // read address 2
    input  wire [4:0]  wa,          // write address (which locker to write)
    input  wire [31:0] wd,          // write data
    output wire [31:0] rd1,         // read data 1
    output wire [31:0] rd2          // read data 2
);
    // the 32 lockers, each 32 bits wide
    reg [31:0] regs [0:31];

    // WRITE: on the clock edge, if enabled and not writing to x0
    always @(posedge clk) begin
        if (we && wa != 5'd0)
            regs[wa] <= wd;
    end

    // READ: combinational (instant). x0 always reads as 0.
    assign rd1 = (ra1 == 5'd0) ? 32'd0 : regs[ra1];
    assign rd2 = (ra2 == 5'd0) ? 32'd0 : regs[ra2];
endmodule
