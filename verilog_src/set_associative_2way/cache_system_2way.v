`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Module: cache_system_2way
// Description: Implements a two-level cache system with 2-way set-associative 
//              caches for both L1 and L2. Promotes from L2 to L1 on L2 hit,
//              and fills both caches from memory on total miss.
// -----------------------------------------------------------------------------

module cache_system_2way #(
    parameter ADDR_WIDTH = 11,
    parameter DATA_WIDTH = 32,  // 32-bit word size

    // L1 Cache Configuration
    parameter L1_BLOCK_SIZE  = 16,
    parameter L1_CACHE_SIZE  = 256,
    parameter L1_NUM_WAYS    = 2,
    parameter L1_NUM_SETS    = L1_CACHE_SIZE / (L1_BLOCK_SIZE * L1_NUM_WAYS),
    parameter L1_INDEX_WIDTH = clog2(L1_NUM_SETS),
    parameter L1_OFFSET_WIDTH= clog2(L1_BLOCK_SIZE),
    parameter L1_TAG_WIDTH   = ADDR_WIDTH - L1_INDEX_WIDTH - L1_OFFSET_WIDTH,

    // L2 Cache Configuration
    parameter L2_BLOCK_SIZE  = 16,
    parameter L2_CACHE_SIZE  = 512,
    parameter L2_NUM_WAYS    = 2,
    parameter L2_NUM_SETS    = L2_CACHE_SIZE / (L2_BLOCK_SIZE * L2_NUM_WAYS),
    parameter L2_INDEX_WIDTH = clog2(L2_NUM_SETS),
    parameter L2_OFFSET_WIDTH= clog2(L2_BLOCK_SIZE),
    parameter L2_TAG_WIDTH   = ADDR_WIDTH - L2_INDEX_WIDTH - L2_OFFSET_WIDTH
)(
    input clk,                                      // Clock signal
    input rst,                                      // Reset signal
    input [ADDR_WIDTH-1:0] addr,                    // Memory address
    input read,                                     // Read enable
    output reg [DATA_WIDTH-1:0] read_data,          // Output data
    output reg l1_hit,                              // L1 hit flag
    output reg l2_hit                               // L2 hit flag
);

    // ----------------------------
    // Local Functions
    // ----------------------------
    // Computes ceiling of log2 (clog2)
    function integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value - 1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

    // Selects which way to evict using simple binary LRU
    function integer lru_select;
        input bit_val;
        begin
            if (bit_val) lru_select = 0;
            else lru_select = 1;
        end
    endfunction

    // ----------------------------
    // Address Decomposition
    // ----------------------------
    wire [L1_TAG_WIDTH-1:0]   l1_tag   = addr[ADDR_WIDTH-1 -: L1_TAG_WIDTH];
    wire [L1_INDEX_WIDTH-1:0] l1_index = addr[L1_OFFSET_WIDTH +: L1_INDEX_WIDTH];
    wire [L2_TAG_WIDTH-1:0]   l2_tag   = addr[ADDR_WIDTH-1 -: L2_TAG_WIDTH];
    wire [L2_INDEX_WIDTH-1:0] l2_index = addr[L2_OFFSET_WIDTH +: L2_INDEX_WIDTH];

    // ----------------------------
    // Cache Structures (Data, Tag, Valid, LRU)
    // ----------------------------
    // L1 Cache Arrays
    reg [DATA_WIDTH-1:0]    l1_data [0:L1_NUM_SETS-1][0:L1_NUM_WAYS-1];
    reg [L1_TAG_WIDTH-1:0]  l1_tags [0:L1_NUM_SETS-1][0:L1_NUM_WAYS-1];
    reg                     l1_valid[0:L1_NUM_SETS-1][0:L1_NUM_WAYS-1];
    reg                     l1_lru  [0:L1_NUM_SETS-1]; // 1-bit LRU (way toggle)

    // L2 Cache Arrays
    reg [DATA_WIDTH-1:0]    l2_data [0:L2_NUM_SETS-1][0:L2_NUM_WAYS-1];
    reg [L2_TAG_WIDTH-1:0]  l2_tags [0:L2_NUM_SETS-1][0:L2_NUM_WAYS-1];
    reg                     l2_valid[0:L2_NUM_SETS-1][0:L2_NUM_WAYS-1];
    reg                     l2_lru  [0:L2_NUM_SETS-1]; // 1-bit LRU

    // ----------------------------
    // Main Cache Logic
    // ----------------------------
    integer i, j, w;
    reg [DATA_WIDTH-1:0] mem_data;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all cache structures
            for (i = 0; i < L1_NUM_SETS; i = i + 1) begin
                l1_lru[i] <= 0;
                for (j = 0; j < L1_NUM_WAYS; j = j + 1) begin
                    l1_valid[i][j] <= 0;
                    l1_data[i][j]  <= 0;
                    l1_tags[i][j]  <= 0;
                end
            end
            for (i = 0; i < L2_NUM_SETS; i = i + 1) begin
                l2_lru[i] <= 0;
                for (j = 0; j < L2_NUM_WAYS; j = j + 1) begin
                    l2_valid[i][j] <= 0;
                    l2_data[i][j]  <= 0;
                    l2_tags[i][j]  <= 0;
                end
            end
            l1_hit <= 0;
            l2_hit <= 0;
            read_data <= 0;

        end else if (read) begin
            // Reset hit flags
            l1_hit <= 0;
            l2_hit <= 0;
            read_data <= 0;

            // ----------------------------
            // L1 Cache Lookup
            // ----------------------------
            for (w = 0; w < L1_NUM_WAYS; w = w + 1) begin
                if (l1_valid[l1_index][w] && l1_tags[l1_index][w] == l1_tag) begin
                    l1_hit <= 1;
                    read_data <= l1_data[l1_index][w];
                    l1_lru[l1_index] <= ~w; // Flip LRU to indicate last used
                end
            end

            // ----------------------------
            // L2 Cache Lookup
            // ----------------------------
            if (!l1_hit) begin
                for (w = 0; w < L2_NUM_WAYS; w = w + 1) begin
                    if (l2_valid[l2_index][w] && l2_tags[l2_index][w] == l2_tag) begin
                        l2_hit <= 1;
                        read_data <= l2_data[l2_index][w];

                        // Promote data from L2 to L1
                        j = lru_select(l1_lru[l1_index]);
                        l1_data[l1_index][j] <= l2_data[l2_index][w];
                        l1_tags[l1_index][j] <= l1_tag;
                        l1_valid[l1_index][j] <= 1;
                        l1_lru[l1_index] <= ~j;
                    end
                end

                // ----------------------------
                // Main Memory Fallback (on full miss)
                // ----------------------------
                if (!l2_hit) begin
                    mem_data = 32'h000003F3; // Dummy data for main memory

                    // Fill L2
                    j = lru_select(l2_lru[l2_index]);
                    l2_data[l2_index][j] <= mem_data;
                    l2_tags[l2_index][j] <= l2_tag;
                    l2_valid[l2_index][j] <= 1;
                    l2_lru[l2_index] <= ~j;

                    // Fill L1
                    j = lru_select(l1_lru[l1_index]);
                    l1_data[l1_index][j] <= mem_data;
                    l1_tags[l1_index][j] <= l1_tag;
                    l1_valid[l1_index][j] <= 1;
                    l1_lru[l1_index] <= ~j;

                    read_data <= mem_data;
                end
            end
        end
    end
endmodule
