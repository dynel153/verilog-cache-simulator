`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// Module: cache_direct
// Description: Implements a direct-mapped cache with 16 blocks. 
//              On read, checks if the requested address matches the stored tag 
//              at the indexed location. On a miss, replaces the block and 
//              updates the tag and valid bit.
// -----------------------------------------------------------------------------

module cache_direct (
    input clk,                    // Clock signal
    input rst,                    // Reset signal (clears cache contents)
    input read,                   // Read enable signal
    input [10:0] addr,            // 11-bit memory address
    output reg [31:0] read_data,  // 32-bit data returned from cache or memory
    output reg hit                // Hit signal (1 if address is in cache, else 0)
);

    // ----------------------------
    // Cache Configuration
    // ----------------------------
    localparam BLOCKS = 16;       // Total blocks in cache (16)
                                  // Assuming cache size = 256B, block size = 16B → 256/16 = 16 blocks
    localparam TAG_WIDTH = 3;     // Number of tag bits: 11 address bits - 4 (index) - 4 (offset) = 3

    // ----------------------------
    // Cache Metadata Storage
    // ----------------------------
    reg [TAG_WIDTH-1:0] tag_array [0:BLOCKS-1]; // Stores the tag for each block
    reg valid_array [0:BLOCKS-1];               // Stores validity of each block

    // ----------------------------
    // Address Breakdown
    // ----------------------------
    wire [3:0] index = addr[7:4];              // Bits 7–4 select one of the 16 cache blocks
    wire [TAG_WIDTH-1:0] tag = addr[10:8];     // Bits 10–8 form the tag used to verify the block

    integer i;

    // ----------------------------
    // Main Cache Operation
    // ----------------------------
    always @(posedge clk) begin
        if (rst) begin
            // On reset: invalidate all blocks and clear tag values
            for (i = 0; i < BLOCKS; i = i + 1) begin
                valid_array[i] <= 0;           // Mark each block as invalid
                tag_array[i] <= 0;             // Clear tag
            end
            hit <= 0;
            read_data <= 0;

        end else if (read) begin
            // Check if the current index has valid data and matching tag
            if (valid_array[index] && tag_array[index] == tag) begin
                // ----------------------------
                // Cache Hit
                // ----------------------------
                hit <= 1'b1;
                read_data <= 32'h000003F3;     // Return dummy data to simulate memory content
            end else begin
                // ----------------------------
                // Cache Miss
                // ----------------------------
                hit <= 1'b0;
                read_data <= 32'h000003F3;     // Still return dummy data (memory fallback)
                tag_array[index] <= tag;       // Update tag at this index
                valid_array[index] <= 1'b1;    // Mark block as valid
            end
        end
    end

endmodule
