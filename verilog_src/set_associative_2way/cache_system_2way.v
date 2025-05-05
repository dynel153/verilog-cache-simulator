`timescale 1ns/1ps

module cache_system_2way #(
    parameter ADDR_WIDTH = 11,
    parameter DATA_WIDTH = 11,

    // L1 cache parameters
    parameter L1_BLOCK_SIZE  = 16,
    parameter L1_CACHE_SIZE  = 256,
    parameter L1_NUM_WAYS    = 2,
    parameter L1_NUM_SETS    = L1_CACHE_SIZE / (L1_BLOCK_SIZE * L1_NUM_WAYS),
    parameter L1_INDEX_WIDTH = clog2(L1_NUM_SETS),
    parameter L1_OFFSET_WIDTH= clog2(L1_BLOCK_SIZE),
    parameter L1_TAG_WIDTH   = ADDR_WIDTH - L1_INDEX_WIDTH - L1_OFFSET_WIDTH,

    // L2 cache parameters
    parameter L2_BLOCK_SIZE  = 16,
    parameter L2_CACHE_SIZE  = 512,
    parameter L2_NUM_WAYS    = 2,
    parameter L2_NUM_SETS    = L2_CACHE_SIZE / (L2_BLOCK_SIZE * L2_NUM_WAYS),
    parameter L2_INDEX_WIDTH = clog2(L2_NUM_SETS),
    parameter L2_OFFSET_WIDTH= clog2(L2_BLOCK_SIZE),
    parameter L2_TAG_WIDTH   = ADDR_WIDTH - L2_INDEX_WIDTH - L2_OFFSET_WIDTH
)(
    input clk,
    input rst,
    input [ADDR_WIDTH-1:0] addr,
    input read,
    output reg [DATA_WIDTH-1:0] read_data,
    output reg l1_hit,
    output reg l2_hit
);

    // Function inside module
    function integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value - 1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

    // Address decomposition
    wire [L1_TAG_WIDTH-1:0]   l1_tag = addr[ADDR_WIDTH-1 -: L1_TAG_WIDTH];
    wire [L1_INDEX_WIDTH-1:0] l1_index = addr[L1_OFFSET_WIDTH +: L1_INDEX_WIDTH];
    wire [L2_TAG_WIDTH-1:0]   l2_tag = addr[ADDR_WIDTH-1 -: L2_TAG_WIDTH];
    wire [L2_INDEX_WIDTH-1:0] l2_index = addr[L2_OFFSET_WIDTH +: L2_INDEX_WIDTH];

    // L1 and L2 structures
    reg [DATA_WIDTH-1:0] l1_data [0:L1_NUM_SETS-1][0:L1_NUM_WAYS-1];
    reg [L1_TAG_WIDTH-1:0] l1_tags [0:L1_NUM_SETS-1][0:L1_NUM_WAYS-1];
    reg l1_valid [0:L1_NUM_SETS-1][0:L1_NUM_WAYS-1];
    reg l1_lru [0:L1_NUM_SETS-1];

    reg [DATA_WIDTH-1:0] l2_data [0:L2_NUM_SETS-1][0:L2_NUM_WAYS-1];
    reg [L2_TAG_WIDTH-1:0] l2_tags [0:L2_NUM_SETS-1][0:L2_NUM_WAYS-1];
    reg l2_valid [0:L2_NUM_SETS-1][0:L2_NUM_WAYS-1];
    reg l2_lru [0:L2_NUM_SETS-1];

    // LRU selection function
    function integer lru_select;
        input bit_val;
        begin
            if (bit_val) lru_select = 0;
            else lru_select = 1;
        end
    endfunction

    integer i, j, w;
    reg [DATA_WIDTH-1:0] mem_data;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < L1_NUM_SETS; i = i + 1) begin
                l1_lru[i] <= 0;
                for (j = 0; j < L1_NUM_WAYS; j = j + 1) begin
                    l1_valid[i][j] <= 0;
                    l1_data[i][j] <= 0;
                    l1_tags[i][j] <= 0;
                end
            end
            for (i = 0; i < L2_NUM_SETS; i = i + 1) begin
                l2_lru[i] <= 0;
                for (j = 0; j < L2_NUM_WAYS; j = j + 1) begin
                    l2_valid[i][j] <= 0;
                    l2_data[i][j] <= 0;
                    l2_tags[i][j] <= 0;
                end
            end
            l1_hit <= 0;
            l2_hit <= 0;
            read_data <= 0;
        end else if (read) begin
            l1_hit <= 0;
            l2_hit <= 0;
            read_data <= 0;

            // L1 Check
            for (w = 0; w < L1_NUM_WAYS; w = w + 1) begin
                if (l1_valid[l1_index][w] && l1_tags[l1_index][w] == l1_tag) begin
                    l1_hit <= 1;
                    read_data <= l1_data[l1_index][w];
                    l1_lru[l1_index] <= ~w;
                end
            end

            // L2 Check if L1 Miss
            if (!l1_hit) begin
                for (w = 0; w < L2_NUM_WAYS; w = w + 1) begin
                    if (l2_valid[l2_index][w] && l2_tags[l2_index][w] == l2_tag) begin
                        l2_hit <= 1;
                        read_data <= l2_data[l2_index][w];

                        // Promote to L1
                        j = lru_select(l1_lru[l1_index]);
                        l1_data[l1_index][j] <= l2_data[l2_index][w];
                        l1_tags[l1_index][j] <= l1_tag;
                        l1_valid[l1_index][j] <= 1;
                        l1_lru[l1_index] <= ~j;
                    end
                end

                if (!l2_hit) begin
                    mem_data = 11'h3F3;

                    // L2 Fill
                    j = lru_select(l2_lru[l2_index]);
                    l2_data[l2_index][j] <= mem_data;
                    l2_tags[l2_index][j] <= l2_tag;
                    l2_valid[l2_index][j] <= 1;
                    l2_lru[l2_index] <= ~j;

                    // L1 Fill
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
