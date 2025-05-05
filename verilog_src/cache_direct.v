module cache_direct (
    input clk,                   // Clock input
    input rst,                   // Reset signal
    input read,                  // Read enable signal
    input [10:0] addr,           // 11-bit address input
    output reg [10:0] read_data, // Data output
    output reg hit               // Output: 1 = hit, 0 = miss
);

    // Cache configuration
    localparam BLOCKS = 16;       // 256B / 16B = 16 blocks
    localparam TAG_WIDTH = 3;     // bits 10–8

    // Tag memory and valid bits
    reg [TAG_WIDTH-1:0] tag_array [0:BLOCKS-1];
    reg valid_array [0:BLOCKS-1];

    // Extract index and tag
    wire [3:0] index = addr[7:4];
    wire [TAG_WIDTH-1:0] tag = addr[10:8];

    // Cache logic
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
                read_data <= addr;  // Just echo the addr as dummy data
            end else begin
                hit <= 0;
                tag_array[index] <= tag;
                valid_array[index] <= 1;
                read_data <= 11'h3F3;  // Dummy value on miss
            end
        end
    end

endmodule
