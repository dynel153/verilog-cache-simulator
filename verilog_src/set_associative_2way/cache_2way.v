// Module for a 2-level cache system with L1 and L2 (both 2-way set-associative, read-only, with LRU replacement)

module cache_system_2level #(
    //  parameters
    parameter ADDR_WIDTH = 11,
    parameter DATA_WIDTH = 11,

    // L1 cache parameters
    parameter L1_BLOCK_SIZE  = 16,
    parameter L1_CACHE_SIZE  = 256,
    parameter L1_NUM_WAYS    = 2,
    parameter L1_NUM_SETS    = L1_CACHE_SIZE / (L1_BLOCK_SIZE * L1_NUM_WAYS),
    parameter L1_INDEX_WIDTH = $clog2(L1_NUM_SETS),
    parameter L1_OFFSET_WIDTH= $clog2(L1_BLOCK_SIZE),
    parameter L1_TAG_WIDTH   = ADDR_WIDTH - L1_INDEX_WIDTH - L1_OFFSET_WIDTH,

    // L2 cache parameters
    parameter L2_BLOCK_SIZE  = 16,
    parameter L2_CACHE_SIZE  = 512,
    parameter L2_NUM_WAYS    = 2,
    parameter L2_NUM_SETS    = L2_CACHE_SIZE / (L2_BLOCK_SIZE * L2_NUM_WAYS),
    parameter L2_INDEX_WIDTH = $clog2(L2_NUM_SETS),
    parameter L2_OFFSET_WIDTH= $clog2(L2_BLOCK_SIZE),
    parameter L2_TAG_WIDTH   = ADDR_WIDTH - L2_INDEX_WIDTH - L2_OFFSET_WIDTH
)(
    input  logic                   clk,
    input  logic                   rst,
    input  logic [ADDR_WIDTH-1:0]  addr,
    input  logic                   read,
    output logic [DATA_WIDTH-1:0]  read_data,
    output logic                   l1_hit,
    output logic                   l2_hit
);

    // Address decomposition for L1
    logic [L1_TAG_WIDTH-1:0]   l1_tag;
    logic [L1_INDEX_WIDTH-1:0] l1_index;
    assign l1_tag   = addr[ADDR_WIDTH-1 -: L1_TAG_WIDTH];
    assign l1_index = addr[L1_OFFSET_WIDTH +: L1_INDEX_WIDTH];

    // Address decomposition for L2
    logic [L2_TAG_WIDTH-1:0]   l2_tag;
    logic [L2_INDEX_WIDTH-1:0] l2_index;
    assign l2_tag   = addr[ADDR_WIDTH-1 -: L2_TAG_WIDTH];
    assign l2_index = addr[L2_OFFSET_WIDTH +: L2_INDEX_WIDTH];

    // L1 cache structures
    logic [DATA_WIDTH-1:0]        l1_data   [L1_NUM_SETS-1:0][L1_NUM_WAYS-1:0];
    logic [L1_TAG_WIDTH-1:0]      l1_tags   [L1_NUM_SETS-1:0][L1_NUM_WAYS-1:0];
    logic                         l1_valid  [L1_NUM_SETS-1:0][L1_NUM_WAYS-1:0];
    logic                         l1_lru    [L1_NUM_SETS-1:0];  // 0 -> use way 0 next, 1 -> way 1

    // L2 cache structures
    logic [DATA_WIDTH-1:0]        l2_data   [L2_NUM_SETS-1:0][L2_NUM_WAYS-1:0];
    logic [L2_TAG_WIDTH-1:0]      l2_tags   [L2_NUM_SETS-1:0][L2_NUM_WAYS-1:0];
    logic                         l2_valid  [L2_NUM_SETS-1:0][L2_NUM_WAYS-1:0];
    logic                         l2_lru    [L2_NUM_SETS-1:0];

    // LRU replacement helper
    function automatic int lru_select(input logic lru_bit);
        return lru_bit ? 0 : 1;
    endfunction

  always_ff @(posedge clk or posedge rst) begin//uses flip flop to hold value until reset 
    if (rst) begin//reset function condition
            for (int i = 0; i < L1_NUM_SETS; i++) begin
                l1_lru[i] <= 0;
                for (int j = 0; j < L1_NUM_WAYS; j++) begin
                    l1_valid[i][j] <= 0;
                    l1_data[i][j]  <= 0;
                    l1_tags[i][j]  <= 0;
                end
            end
            for (int i = 0; i < L2_NUM_SETS; i++) begin
                l2_lru[i] <= 0;
                for (int j = 0; j < L2_NUM_WAYS; j++) begin
                    l2_valid[i][j] <= 0;
                    l2_data[i][j]  <= 0;
                    l2_tags[i][j]  <= 0;
                end
            end
            l1_hit <= 0;
            l2_hit <= 0;
            read_data <= 0;
        end else if (read) begin
            l1_hit <= 0;
            l2_hit <= 0;
            read_data <= 0;

            // L1 hit check
            for (int w = 0; w < L1_NUM_WAYS; w++) begin
                if (l1_valid[l1_index][w] && l1_tags[l1_index][w] == l1_tag) begin
                    l1_hit <= 1;
                    read_data <= l1_data[l1_index][w];
                    l1_lru[l1_index] <= ~w;  // Update LRU bit
                end
            end

            // L1 miss -> check L2
            if (!l1_hit) begin
                for (int w = 0; w < L2_NUM_WAYS; w++) begin
                  if (l2_valid[l2_index][w] && l2_tags[l2_index][w] == l2_tag) begin//continue if valid bit, index, and way are correct and check if tag is same
                        l2_hit <= 1;//if hit 
                    read_data <= l2_data[l2_index][w];//read data if hit and update 
                     l1_lru[l1_index] <= ~w; // Update LRU bit (other way becomes LRU)

                        // Promote to L1 (evict using LRU)
                        int lru_way = lru_select(l1_lru[l1_index]);
                        l1_data[l1_index][lru_way] <= l2_data[l2_index][w];
                        l1_tags[l1_index][lru_way] <= l1_tag;
                        l1_valid[l1_index][lru_way] <= 1;
                        l1_lru[l1_index] <= ~lru_way;
                    end
                end

                // L2 miss -> fake memory load and populate both L2 and L1
                if (!l2_hit) begin
                    logic [DATA_WIDTH-1:0] mem_data = 32'hCAFEBABE;

                    int l2_lru_way = lru_select(l2_lru[l2_index]);
                    l2_data[l2_index][l2_lru_way] <= mem_data;
                    l2_tags[l2_index][l2_lru_way] <= l2_tag;
                    l2_valid[l2_index][l2_lru_way] <= 1;
                    l2_lru[l2_index] <= ~l2_lru_way;

                    int l1_lru_way = lru_select(l1_lru[l1_index]);
                    l1_data[l1_index][l1_lru_way] <= mem_data;
                    l1_tags[l1_index][l1_lru_way] <= l1_tag;
                    l1_valid[l1_index][l1_lru_way] <= 1;
                    l1_lru[l1_index] <= ~l1_lru_way;

                    read_data <= mem_data;
                end
            end
        end
    end

endmodule
