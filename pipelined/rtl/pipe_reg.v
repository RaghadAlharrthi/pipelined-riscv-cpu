// pipe_reg.v — a generic pipeline register (the "divider" between stages)
// Carries WIDTH bits of data from one stage to the next on each clock.
module pipe_reg #(
    parameter WIDTH = 32
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire              en,      // 1 = update, 0 = stall (hold value)
    input  wire              clear,   // 1 = flush (wipe to 0 / NOP)
    input  wire [WIDTH-1:0]  d,       // data in (from current stage)
    output reg  [WIDTH-1:0]  q         // data out (to next stage)
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)      q <= {WIDTH{1'b0}};   // reset: clear
        else if (clear)  q <= {WIDTH{1'b0}};   // flush: wipe to NOP
        else if (en)     q <= d;               // normal: pass data forward
        // if en==0 and not clearing: HOLD (stall) — q keeps its value
    end
endmodule
