`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Module: cache_system_4way
// Description: Two-level cache system using 4-way set-associative caches for both
//              L1 and L2. Simulates a promotion from L2 to L1 on L2 hits.
// -----------------------------------------------------------------------------

module cache_system_4way #(
    parameter ADDR_WIDTH = 11,               // Address bit width
    parameter DATA_WIDTH = 32                // Data bit width
)(
    input clk,                               // Clock signal
    input rst,                               // Reset signal
    input [ADDR_WIDTH-1:0] addr,             // Memory address input
    input read,                              // Read enable
    output reg [DATA_WIDTH-1:0] read_data,   // Final data output
    output reg l1_hit,                       // L1 hit flag
    output reg l2_hit                        // L2 hit flag
);

    // ----------------------------
    // Internal Wires
    // ----------------------------
    wire l1_cache_hit, l2_cache_hit;           // Hit indicators from L1 and L2
    wire [DATA_WIDTH-1:0] l1_data_out;         // Data from L1 cache
    wire [DATA_WIDTH-1:0] l2_data_out;         // Data from L2 cache

    // ----------------------------
    // L1 Cache Instantiation (256B total, 16B blocks, 4-way)
    // ----------------------------
    cache_4way #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .CACHE_SIZE(256),
        .BLOCK_SIZE(16)
    ) l1 (
        .clk(clk),
        .rst(rst),
        .read(read),
        .write_enable(promote_to_l1),          // Enable promotion if true
        .write_data(promoted_data),            // Data to promote
        .addr(addr),
        .read_data(l1_data_out),
        .hit(l1_cache_hit)
    );

    // ----------------------------
    // L2 Cache Instantiation (512B total, 32B blocks, 4-way)
    // ----------------------------
    cache_4wayl2 #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .CACHE_SIZE(512),
        .BLOCK_SIZE(32)
    ) l2 (
        .clk(clk),
        .rst(rst),
        .read(read),
        .addr(addr),
        .read_data(l2_data_out),
        .hit(l2_cache_hit)
    );

    // ----------------------------
    // Control Registers for Promotion Logic
    // ----------------------------
    reg promote_to_l1;                         // Flag to write L2 data into L1
    reg [DATA_WIDTH-1:0] promoted_data;        // Temporary storage for promoted data

    // ----------------------------
    // Cache System Control Logic
    // ----------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // On reset: clear all outputs and flags
            read_data <= 0;
            l1_hit <= 0;
            l2_hit <= 0;
            promote_to_l1 <= 0;

        end else if (read) begin
            // On read: reset flags
            promote_to_l1 <= 0;
            l1_hit <= l1_cache_hit;
            l2_hit <= 0;
            read_data <= 0;

            if (l1_cache_hit) begin
                // ----------------------------
                // L1 Cache Hit
                // ----------------------------
                read_data <= l1_data_out;

            end else if (l2_cache_hit) begin
                // ----------------------------
                // L2 Cache Hit → Promote to L1
                // ----------------------------
                l2_hit <= 1;
                read_data <= l2_data_out;
                promoted_data <= l2_data_out;
                promote_to_l1 <= 1;

            end else begin
                // ----------------------------
                // Miss in both caches → Simulate memory fetch
                // ----------------------------
                read_data <= 32'hD00DFEED;
            end
        end
    end

endmodule
