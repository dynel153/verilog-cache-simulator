`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Module: cache_4way
// Description: Implements a 4-way set-associative L1 cache. Each set has 4 blocks,
//              and replacement is done using a simple pseudo-LRU policy.
//              Supports read and L2-promoted write (write-through).
// -----------------------------------------------------------------------------

module cache_4way #(
    parameter ADDR_WIDTH = 11,              // Width of memory address
    parameter DATA_WIDTH = 32,              // Width of each data block
    parameter CACHE_SIZE = 256,             // Total cache size in bytes
    parameter BLOCK_SIZE = 16               // Size of each cache block in bytes
)(
    input wire clk,                         // Clock signal
    input wire rst,                         // Reset signal
    input wire read,                        // Read enable
    input wire write_enable,                // Enable writing from L2
    input wire [DATA_WIDTH-1:0] write_data, // Data to write (on promotion from L2)
    input wire [ADDR_WIDTH-1:0] addr,       // Memory address to access
    output reg [DATA_WIDTH-1:0] read_data,  // Data output on read
    output reg hit                          // Output flag: 1 = cache hit, 0 = miss
);

    // ----------------------------
    // Cache Parameter Definitions
    // ----------------------------
    localparam NUM_WAYS = 4;                                            // 4-way set associative
    localparam NUM_SETS = CACHE_SIZE / (BLOCK_SIZE * NUM_WAYS);        // Number of sets
    localparam INDEX_WIDTH = $clog2(NUM_SETS);                          // Index width
    localparam OFFSET_WIDTH = $clog2(BLOCK_SIZE);                       // Offset width
    localparam TAG_WIDTH = ADDR_WIDTH - INDEX_WIDTH - OFFSET_WIDTH;    // Tag width

    // ----------------------------
    // Cache Arrays
    // ----------------------------
    reg [TAG_WIDTH-1:0] tag_array [0:NUM_SETS-1][0:NUM_WAYS-1];         // Tag storage
    reg valid_array [0:NUM_SETS-1][0:NUM_WAYS-1];                       // Valid bits
    reg [DATA_WIDTH-1:0] data_array [0:NUM_SETS-1][0:NUM_WAYS-1];       // Cache data
    reg [1:0] lru [0:NUM_SETS-1];                                       // Simple 2-bit LRU tracker

    // ----------------------------
    // Address Breakdown
    // ----------------------------
    wire [TAG_WIDTH-1:0] tag = addr[ADDR_WIDTH-1 -: TAG_WIDTH];        // Tag from MSBs
    wire [INDEX_WIDTH-1:0] index = addr[OFFSET_WIDTH +: INDEX_WIDTH];  // Index bits (middle of address)

    integer i;
    reg found;
    reg [1:0] replace_way;

    // ----------------------------
    // Cache Control Logic
    // ----------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset: Invalidate all entries in the current index set
            hit <= 0;
            read_data <= 0;
            for (i = 0; i < NUM_WAYS; i = i + 1) begin
                valid_array[index][i] <= 0;
                tag_array[index][i] <= 0;
                data_array[index][i] <= 0;
            end
            lru[index] <= 0;

        end else if (write_enable) begin
            // ----------------------------
            // Write from L2 (promotion)
            // ----------------------------
            replace_way = lru[index];  // Select way to replace based on LRU
            tag_array[index][replace_way] <= tag;
            data_array[index][replace_way] <= write_data;
            valid_array[index][replace_way] <= 1;
            lru[index] <= (replace_way + 1) % NUM_WAYS;  // Update LRU
            $display("L1 WRITE: Addr = 0x%h | Tag = 0x%h | Data = 0x%h", addr, tag, write_data);

        end else if (read) begin
            // ----------------------------
            // Read operation
            // ----------------------------
            hit <= 0;
            found = 0;

            // Search all 4 ways for a matching tag
            for (i = 0; i < NUM_WAYS; i = i + 1) begin
                if (valid_array[index][i] && tag_array[index][i] == tag) begin
                    hit <= 1;
                    found = 1;
                    read_data <= data_array[index][i];
                    lru[index] <= i;  // Update LRU to most recently used
                    $display("L1 READ HIT: Addr = 0x%h | Tag = 0x%h | Way = %0d | Data = 0x%h", addr, tag, i, read_data);
                end
            end

            // If no match found, it's a miss — simulate memory fetch
            if (!found) begin
                replace_way = lru[index];
                tag_array[index][replace_way] <= tag;
                valid_array[index][replace_way] <= 1;
                data_array[index][replace_way] <= 32'hD00DFEED; // Dummy data for miss
                read_data <= 32'hD00DFEED;
                lru[index] <= (replace_way + 1) % NUM_WAYS;
                $display("L1 MISS: Addr = 0x%h | Inserted Data = 0xD00DFEED", addr);
            end
        end
    end

endmodule
