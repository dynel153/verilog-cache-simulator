`timescale 1ns/1ps

module cache_system_direct #(
    parameter ADDR_WIDTH = 11,
    parameter DATA_WIDTH = 32
)(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   read,
    input  wire [ADDR_WIDTH-1:0] addr,
    output reg  [DATA_WIDTH-1:0] read_data,
    output reg                   l1_hit,
    output reg                   l2_hit
);

    // Internal wires to connect with L1 and L2
    wire [DATA_WIDTH-1:0] l1_data_out;
    wire [DATA_WIDTH-1:0] l2_data_out;
    wire l1_valid, l2_valid;

    // Instantiate L1 Direct-Mapped Cache
    cache_direct l1 (
        .clk(clk),
        .rst(rst),
        .read(read),
        .addr(addr),
        .read_data(l1_data_out),
        .hit(l1_valid)
    );

    // Instantiate L2 Direct-Mapped Cache
    cache_directl2 l2 (
        .clk(clk),
        .rst(rst),
        .read(read),
        .addr(addr),
        .read_data(l2_data_out),
        .hit(l2_valid)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            l1_hit    <= 0;
            l2_hit    <= 0;
            read_data <= 0;
        end else if (read) begin
            if (l1_valid) begin
                // L1 hit
                l1_hit    <= 1;
                l2_hit    <= 0;
                read_data <= l1_data_out;
            end else if (l2_valid) begin
                // L2 hit → promote to L1 (not shown inside L1, assume it updates itself)
                l1_hit    <= 0;
                l2_hit    <= 1;
                read_data <= l2_data_out;
            end else begin
                // Miss in both → simulate memory read
                l1_hit    <= 0;
                l2_hit    <= 0;
                read_data <= 32'hCAFEBABE;
            end
        end
    end

endmodule
