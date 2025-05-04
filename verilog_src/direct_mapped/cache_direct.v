module cache_direct (            // Create the module called cache_direct
    input clk,                   // Clock input; cache checks for address on the positive edge
    input [10:0] addr,           // 11-bit address input from the CPU
    output reg hit               // Output is 1 if it's a cache hit, 0 if a miss
);

    // Cache configuration
    localparam BLOCKS = 16;       // 256B total / 16B per block = 16 blocks
    localparam TAG_WIDTH = 3;     // Tag uses upper 3 bits of the 11-bit address

    // Tag memory and valid bits for each block 
    reg [TAG_WIDTH-1:0] tag_array [0:BLOCKS-1];   // Stores the tag for each block
    reg valid_array [0:BLOCKS-1];                // 1 if block is valid, 0 otherwise

    // Extract index and tag from the address       
    wire [3:0] index;                            // 4-bit index (bits 7:4)
    wire [TAG_WIDTH-1:0] tag;                    // 3-bit tag (bits 10:8)

    assign index = addr[7:4];    // Extract index from address
    assign tag   = addr[10:8];   // Extract tag from address

    // Main cache logic: runs on rising edge of the clock
    always @(posedge clk) begin
        if (valid_array[index] && tag_array[index] == tag) begin
            hit <= 1'b1;                         // Cache hit
        end else begin
            hit <= 1'b0;                         // Cache miss
            tag_array[index] <= tag;             // Update stored tag
            valid_array[index] <= 1'b1;          // Mark block as valid
        end
    end

endmodule
