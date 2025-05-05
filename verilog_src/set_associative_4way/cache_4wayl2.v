`timescale 1ns/1ps

module cache_4wayl2 #(
    parameter ADDR_WIDTH = 11,
    parameter DATA_WIDTH = 32,
    parameter CACHE_SIZE = 512,     // total cache size in bytes
    parameter BLOCK_SIZE = 32       // size of each block in bytes
)(
    input wire clk,
    input wire rst,
    input wire read,
    input wire [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] read_data,
    output reg hit
);

    localparam NUM_WAYS = 4;
    localparam NUM_SETS = CACHE_SIZE / (BLOCK_SIZE * NUM_WAYS);
    localparam INDEX_WIDTH = $clog2(NUM_SETS);
    localparam OFFSET_WIDTH = $clog2(BLOCK_SIZE);
    localparam TAG_WIDTH = ADDR_WIDTH - INDEX_WIDTH - OFFSET_WIDTH;

    reg [TAG_WIDTH-1:0] tag_array [0:NUM_SETS-1][0:NUM_WAYS-1];
    reg valid_array [0:NUM_SETS-1][0:NUM_WAYS-1];
    reg [DATA_WIDTH-1:0] data_array [0:NUM_SETS-1][0:NUM_WAYS-1];
    reg [1:0] lru [0:NUM_SETS-1];  // 2-bit pseudo-LRU per set

    wire [TAG_WIDTH-1:0] tag = addr[ADDR_WIDTH-1 -: TAG_WIDTH];
    wire [INDEX_WIDTH-1:0] index = addr[OFFSET_WIDTH +: INDEX_WIDTH];

    integer i;
    reg found;
    reg [1:0] replace_way;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            integer s, w;
            for (s = 0; s < NUM_SETS; s = s + 1) begin
                for (w = 0; w < NUM_WAYS; w = w + 1) begin
                    valid_array[s][w] <= 0;
                    tag_array[s][w] <= 0;
                    data_array[s][w] <= 0;
                end
                lru[s] <= 0;
            end
            hit <= 0;
            read_data <= 0;
        end else if (read) begin
            $display("L2 CHECKING Addr = 0x%h | Tag = 0x%h | Index = %0d", addr, tag, index);

            hit <= 0;
            found = 0;

            for (i = 0; i < NUM_WAYS; i = i + 1) begin
                if (valid_array[index][i] && tag_array[index][i] == tag) begin
                    hit <= 1;
                    found = 1;
                    read_data <= data_array[index][i];
                    lru[index] <= i;
                    $display("L2 HIT: Addr = 0x%h | Tag = 0x%h | Way = %0d | Data = 0x%h", addr, tag, i, read_data);
                end
            end

            if (!found) begin
                replace_way = lru[index];
                tag_array[index][replace_way] <= tag;
                valid_array[index][replace_way] <= 1;
                data_array[index][replace_way] <= 32'hDEADBEEF;
                read_data <= 32'hDEADBEEF;
                lru[index] <= (replace_way + 1) % NUM_WAYS;
                $display("L2 MISS: Addr = 0x%h | Tag = 0x%h | Index = %0d | Replacing Way = %0d", addr, tag, index, replace_way);
            end
        end
    end
endmodule
