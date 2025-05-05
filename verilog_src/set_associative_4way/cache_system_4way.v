`timescale 1ns/1ps

module cache_system_4way #(
    parameter ADDR_WIDTH = 11,
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rst,
    input [ADDR_WIDTH-1:0] addr,
    input read,
    output reg [DATA_WIDTH-1:0] read_data,
    output reg l1_hit,
    output reg l2_hit
);

    // Internal wires
    wire l1_cache_hit, l2_cache_hit;
    wire [DATA_WIDTH-1:0] l1_data_out, l2_data_out;

    // Instantiate L1 4-way cache (small)
    cache_4way #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .CACHE_SIZE(256),  // Smaller L1
        .BLOCK_SIZE(16)
    ) l1 (
        .clk(clk),
        .rst(rst),
        .read(read),
        .addr(addr),
        .read_data(l1_data_out),
        .hit(l1_cache_hit)
    );

    // Instantiate L2 4-way cache (larger)
    cache_4wayl2 #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .CACHE_SIZE(512),  // Larger L2
        .BLOCK_SIZE(32)
    ) l2 (
        .clk(clk),
        .rst(rst),
        .read(read),
        .addr(addr),
        .read_data(l2_data_out),
        .hit(l2_cache_hit)
    );

    // Main logic for hierarchy
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_data <= 0;
            l1_hit <= 0;
            l2_hit <= 0;
        end else if (read) begin
            l1_hit <= l1_cache_hit;
            l2_hit <= 0;
            read_data <= 0;

            if (l1_cache_hit) begin
                read_data <= l1_data_out;
            end else begin
                if (l2_cache_hit) begin
                    l2_hit <= 1;
                    read_data <= l2_data_out;
                    // Promote to L1: simulate read to L1 to store L2's data
                    // L1 will store the L2 data on next clock cycle automatically via its logic
                end else begin
                    // L2 miss: insert fake memory data to both L2 and L1
                    read_data <= 32'hCAFEBABE;
                end
            end
        end
    end

endmodule
