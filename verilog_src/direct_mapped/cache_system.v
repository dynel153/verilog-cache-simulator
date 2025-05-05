`timescale 1ns / 1ps

module cache_system (
    input clk,
    input [10:0] addr,
    output reg l1_hit,
    output reg l2_hit,
    output reg miss
);

    // Internal signals
    wire l1_result;
    wire l2_result;

    reg promote_l2_to_l1;
    reg [10:0] promoted_addr;

    // Instantiate L1 cache
    cache_direct l1 (
        .clk(clk),
        .addr(addr),
        .hit(l1_result)
    );

    // Instantiate L2 cache
    cache_directl2 l2 (
        .clk(clk),
        .addr(addr),
        .hit(l2_result)
    );

    always @(posedge clk) begin
        // Reset outputs
        l1_hit <= 0;
        l2_hit <= 0;
        miss <= 0;

        if (l1_result) begin
            l1_hit <= 1'b1;
        end else if (l2_result) begin
            l2_hit <= 1'b1;
            promoted_addr <= addr;  // promote from L2
        end else begin
            miss <= 1'b1;  // main memory access
        end
    end

endmodule
