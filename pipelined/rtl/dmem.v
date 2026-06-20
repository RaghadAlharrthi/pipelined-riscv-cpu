// dmem.v — simple data memory for loads and stores
module dmem (
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    output wire [31:0] read_data
);
    reg [31:0] mem [0:63];   // 64 words of data memory

    // preload some test values
    integer i;
    initial begin
        for (i = 0; i < 64; i = i + 1) mem[i] = 32'd0;
        mem[0] = 32'd100;    // memory[0] = 100
        mem[1] = 32'd200;    // memory[1] = 200
    end

    // write on clock edge
    always @(posedge clk) begin
        if (mem_write) mem[addr[31:2]] <= write_data;
    end

    // read is combinational
    assign read_data = mem_read ? mem[addr[31:2]] : 32'd0;
endmodule
