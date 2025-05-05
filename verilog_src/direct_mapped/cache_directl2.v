`timescale 1ns / 1ps

module cache_directl2 (
    input clk,                    // Clock signal
    input rst,                    // Reset signal
    input read,                   // Read enable
    input [10:0] addr,            // 11-bit address input
    output reg [31:0] read_data,  // Updated: 32-bit read data output
    output reg hit                // Hit flag
);

    // Cache configuration
    localparam BLOCKS = 16;       // 512B / 32B = 16 blocks
    localparam TAG_WIDTH = 2;     // bits 10–9

    // Tag memory and valid bits for each block 
    reg [TAG_WIDTH-1:0] tag_array [0:BLOCKS-1];
    reg valid_array [0:BLOCKS-1];

    // Extract index and tag
    wire [3:0] index = addr[8:5];
    wire [TAG_WIDTH-1:0] tag = addr[10:9];

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < BLOCKS; i = i + 1) begin
                valid_array[i] <= 0;
                tag_array[i] <= 0;
            end
            hit <= 0;
            read_data <= 0;
        end else if (read) begin
            if (valid_array[index] && tag_array[index] == tag) begin
                hit <= 1;
                read_data <= {21'b0, addr};  // Zero-extend addr to 32 bits
            end else begin
                hit <= 0;
                tag_array[index] <= tag;
                valid_array[index] <= 1;
                read_data <= 32'h000003F3;  // Simulate memory fetch
            end
        end
    end

endmodule
