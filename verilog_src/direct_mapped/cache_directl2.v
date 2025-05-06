`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// Module: cache_directl2
// Description: Implements a direct-mapped Level 2 (L2) cache with 16 blocks.
//              Each memory access is checked for tag match and validity.
//              On a miss, it simulates a memory fetch and updates the cache.
// -----------------------------------------------------------------------------

module cache_directl2 (
    input clk,                    // Clock signal
    input rst,                    // Reset signal (clears cache state)
    input read,                   // Read enable
    input [10:0] addr,            // 11-bit memory address input
    output reg [31:0] read_data,  // 32-bit data output (either from cache or simulated memory)
    output reg hit                // Output flag: 1 = cache hit, 0 = miss
);

    // ----------------------------
    // Cache Configuration
    // ----------------------------
    localparam BLOCKS = 16;       // Number of cache blocks (e.g., 512B / 32B per block = 16 blocks)
    localparam TAG_WIDTH = 2;     // Tag bits: address bits [10:9] = 2 bits

    // ----------------------------
    // Cache Metadata
    // ----------------------------
    reg [TAG_WIDTH-1:0] tag_array [0:BLOCKS-1];  // Stores the tag for each cache block
    reg valid_array [0:BLOCKS-1];               // Valid bits for each cache block

    // ----------------------------
    // Address Breakdown
    // ----------------------------
    wire [3:0] index = addr[8:5];               // Address bits [8:5] select the block index
    wire [TAG_WIDTH-1:0] tag = addr[10:9];      // Address bits [10:9] are used as the tag

    integer i;

    // ----------------------------
    // Main Cache Operation
    // ----------------------------
    always @(posedge clk) begin
        if (rst) begin
            // On reset: invalidate all blocks and clear tags
            for (i = 0; i < BLOCKS; i = i + 1) begin
                valid_array[i] <= 0;
                tag_array[i] <= 0;
            end
            hit <= 0;
            read_data <= 0;

        end else if (read) begin
            // ----------------------------
            // Cache Lookup
            // ----------------------------
            if (valid_array[index] && tag_array[index] == tag) begin
                // Cache hit: tag matches and block is valid
                hit <= 1;
                read_data <= {21'b0, addr};     // Return zero-extended address as simulated data
            end else begin
                // Cache miss: tag mismatch or invalid block
                hit <= 0;
                tag_array[index] <= tag;        // Update cache with new tag
                valid_array[index] <= 1;        // Mark block as valid
                read_data <= 32'h000003F3;      // Simulate memory fetch with dummy value
            end
        end
    end

endmodule
 