`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Module: cache_system_direct
// Description: Implements a two-level cache system using direct-mapped L1 and L2.
//              If L1 cache misses and L2 hits, data is returned from L2.
//              If both miss, data is simulated from main memory.
// -----------------------------------------------------------------------------

module cache_system_direct #(
    parameter ADDR_WIDTH = 11,              // Width of address bus
    parameter DATA_WIDTH = 32               // Width of data bus
)(
    input  wire                   clk,       // Clock signal
    input  wire                   rst,       // Reset signal
    input  wire                   read,      // Read enable
    input  wire [ADDR_WIDTH-1:0] addr,       // Memory address input
    output reg  [DATA_WIDTH-1:0] read_data,  // Final output data (L1, L2, or memory)
    output reg                   l1_hit,     // Indicates L1 hit
    output reg                   l2_hit      // Indicates L2 hit
);

    // ----------------------------
    // Internal Wires
    // ----------------------------
    wire [DATA_WIDTH-1:0] l1_data_out;       // Data from L1 cache
    wire [DATA_WIDTH-1:0] l2_data_out;       // Data from L2 cache
    wire l1_valid, l2_valid;                 // Hit flags for L1 and L2

    // ----------------------------
    // Instantiate L1 Direct-Mapped Cache
    // ----------------------------
    cache_direct l1 (
        .clk(clk),
        .rst(rst),
        .read(read),
        .addr(addr),
        .read_data(l1_data_out),
        .hit(l1_valid)
    );

    // ----------------------------
    // Instantiate L2 Direct-Mapped Cache
    // ----------------------------
    cache_directl2 l2 (
        .clk(clk),
        .rst(rst),
        .read(read),
        .addr(addr),
        .read_data(l2_data_out),
        .hit(l2_valid)
    );

    // ----------------------------
    // Cache System Control Logic
    // ----------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all outputs
            l1_hit    <= 0;
            l2_hit    <= 0;
            read_data <= 0;

        end else if (read) begin
            if (l1_valid) begin
                // ----------------------------
                // L1 Hit: Return L1 data
                // ----------------------------
                l1_hit    <= 1;
                l2_hit    <= 0;
                read_data <= l1_data_out;

            end else if (l2_valid) begin
                // ----------------------------
                // L2 Hit: Return L2 data
                // ----------------------------
                // (Assumes L1 will be updated internally on next cycle)
                l1_hit    <= 0;
                l2_hit    <= 1;
                read_data <= l2_data_out;

            end else begin
                // ----------------------------
                // Miss in both L1 and L2
                // ----------------------------
                l1_hit    <= 0;
                l2_hit    <= 0;
                read_data <= 32'hCAFEBABE;  // Simulate data from main memory
            end
        end
    end

endmodule
