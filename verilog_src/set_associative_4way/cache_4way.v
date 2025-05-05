`timescale 1ns/1ps

module cache_4way #(
    parameter ADDR_WIDTH = 11,
    parameter DATA_WIDTH = 32,
    parameter CACHE_SIZE = 256,
    parameter BLOCK_SIZE = 16
)(
    input wire clk,
    input wire rst,
    input wire read,
    input wire write_enable,
    input wire [DATA_WIDTH-1:0] write_data,
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
    reg [1:0] lru [0:NUM_SETS-1];

    wire [TAG_WIDTH-1:0] tag = addr[ADDR_WIDTH-1 -: TAG_WIDTH];
    wire [INDEX_WIDTH-1:0] index = addr[OFFSET_WIDTH +: INDEX_WIDTH];

    integer i;
    reg found;
    reg [1:0] replace_way;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            hit <= 0;
            read_data <= 0;
            for (i = 0; i < NUM_WAYS; i = i + 1) begin
                valid_array[index][i] <= 0;
                tag_array[index][i] <= 0;
                data_array[index][i] <= 0;
            end
            lru[index] <= 0;
        end
        else if (write_enable) begin
            // Promote data from L2
            replace_way = lru[index];
            tag_array[index][replace_way] <= tag;
            data_array[index][replace_way] <= write_data;
            valid_array[index][replace_way] <= 1;
            lru[index] <= (replace_way + 1) % NUM_WAYS;
            $display("L1 WRITE: Addr = 0x%h | Tag = 0x%h | Data = 0x%h", addr, tag, write_data);
        end
        else if (read) begin
            hit <= 0;
            found = 0;

            for (i = 0; i < NUM_WAYS; i = i + 1) begin
                if (valid_array[index][i] && tag_array[index][i] == tag) begin
                    hit <= 1;
                    found = 1;
                    read_data <= data_array[index][i];
                    lru[index] <= i;
                    $display("L1 READ HIT: Addr = 0x%h | Tag = 0x%h | Way = %0d | Data = 0x%h", addr, tag, i, read_data);
                end
            end

            if (!found) begin
                replace_way = lru[index];
                tag_array[index][replace_way] <= tag;
                valid_array[index][replace_way] <= 1;
                data_array[index][replace_way] <= 32'hD00DFEED;
                read_data <= 32'hD00DFEED;
                lru[index] <= (replace_way + 1) % NUM_WAYS;
                $display("L1 MISS: Addr = 0x%h | Inserted Data = 0xD00DFEED", addr);
            end
        end
    end

endmodule
