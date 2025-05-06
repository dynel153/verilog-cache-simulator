`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Module: cache_4wayl2
// Description: Implements a 4-way set-associative Level 2 (L2) cache.
//              Each set contains 4 blocks, and LRU (pseudo) replacement is used.
//              Returns dummy data (D00DFEED) on cache misses.
// -----------------------------------------------------------------------------

module cache_4wayl2 #(
    parameter ADDR_WIDTH = 11,               // Width of input address
    parameter DATA_WIDTH = 32,               // Data width (32 bits)
    parameter CACHE_SIZE = 512,              // L2 cache size in bytes
    parameter BLOCK_SIZE = 32                // Block size in bytes
)(
    input wire clk,                          // Clock signal
    input wire rst,                          // Reset signal
    input wire read,                         // Read enable
    input wire [ADDR_WIDTH-1:0] addr,        // 11-bit memory address input
    output reg [DATA_WIDTH-1:0] read_data,   // Output: 32-bit read data
    output reg hit                           // Output: cache hit signal
);

    // ----------------------------
    // Cache Derived Parameters
    // ----------------------------
    localparam NUM_WAYS = 4;                                            // 4-way set-associative
    localparam NUM_SETS = CACHE_SIZE / (BLOCK_SIZE * NUM_WAYS);        // Number of sets
    localparam INDEX_WIDTH = $clog2(NUM_SETS);                          // Number of bits to index sets
    localparam OFFSET_WIDTH = $clog2(BLOCK_SIZE);                       // Number of bits for byte offset
    localparam TAG_WIDTH = ADDR_WIDTH - INDEX_WIDTH - OFFSET_WIDTH;    // Remaining bits used as tag

    // ----------------------------
    // Cache Storage Arrays
    // ----------------------------
    reg [TAG_WIDTH-1:0] tag_array [0:NUM_SETS-1][0:NUM_WAYS-1];         // Tag for each block
    reg valid_array [0:NUM_SETS-1][0:NUM_WAYS-1];                       // Valid bits
    reg [DATA_WIDTH-1:0] data_array [0:NUM_SETS-1][0:NUM_WAYS-1];       // Cache data storage
    reg [1:0] lru [0:NUM_SETS-1];                                       // LRU replacement tracker (2 bits)

    // ----------------------------
    // Address Breakdown
    // ----------------------------
    wire [TAG_WIDTH-1:0] tag = addr[ADDR_WIDTH-1 -: TAG_WIDTH];        // Extract tag bits from MSBs
    wire [INDEX_WIDTH-1:0] index = addr[OFFSET_WIDTH +: INDEX_WIDTH];  // Extract set index bits

    // ----------------------------
    // Control Variables
    // ----------------------------
    integer i, j;
    reg found;                 // Flag indicating a hit during search
    reg [1:0] replace_way;     // Chosen way to replace on miss

    // ----------------------------
    // Main Cache Operation
    // ----------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all sets and ways
            hit <= 0;
            read_data <= 0;
            for (i = 0; i < NUM_SETS; i = i + 1) begin
                for (j = 0; j < NUM_WAYS; j = j + 1) begin
                    valid_array[i][j] <= 0;         // Invalidate block
                    tag_array[i][j] <= 0;           // Clear tag
                    data_array[i][j] <= 0;          // Clear data
                end
                lru[i] <= 0;                        // Reset LRU for each set
            end

        end else if (read) begin
            // ----------------------------
            // Read Operation
            // ----------------------------
            hit <= 0;
            found = 0;

            // Search all ways for a valid matching tag
            for (i = 0; i < NUM_WAYS; i = i + 1) begin
                if (valid_array[index][i] && tag_array[index][i] == tag) begin
                    hit <= 1;
                    found <= 1;
                    read_data <= data_array[index][i];
                    lru[index] <= i; // Update LRU with last used way
                end
            end

            // If no matching tag found: simulate miss and load data
            if (!found) begin
                replace_way = lru[index]; // Select victim block using LRU
                tag_array[index][replace_way] <= tag;
                valid_array[index][replace_way] <= 1;
                data_array[index][replace_way] <= 32'hD00DFEED;  // Dummy data
                read_data <= 32'hD00DFEED;
                lru[index] <= (replace_way + 1) % NUM_WAYS;      // Update LRU for next time
            end
        end
    end

endmodule
