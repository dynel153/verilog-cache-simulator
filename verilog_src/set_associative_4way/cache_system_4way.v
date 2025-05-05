`timescale 1ns/1ps

module cache_system_4way #(
    parameter ADDR_WIDTH = 11,
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rst,
    input [ADDR_WIDTH-1:0] addr,
    input read,
    output reg [DATA_WIDTH-1:0] read_data,
    output reg l1_hit,
    output reg l2_hit
);

    wire l1_cache_hit, l2_cache_hit;
    wire [DATA_WIDTH-1:0] l1_data_out, l2_data_out;

    // Instantiate L1 (smaller)
    cache_4way #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .CACHE_SIZE(256),
        .BLOCK_SIZE(16)
    ) l1 (
        .clk(clk),
        .rst(rst),
        .read(read),
        .addr(addr),
        .read_data(l1_data_out),
        .hit(l1_cache_hit)
    );

    // Instantiate L2 (larger)
    cache_4wayl2 #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .CACHE_SIZE(512),
        .BLOCK_SIZE(32)
    ) l2 (
        .clk(clk),
        .rst(rst),
        .read(read),
        .addr(addr),
        .read_data(l2_data_out),
        .hit(l2_cache_hit)
    );

    // Register to simulate L1 promotion manually
    reg promote_to_l1;
    reg [DATA_WIDTH-1:0] promoted_data;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_data <= 0;
            l1_hit <= 0;
            l2_hit <= 0;
            promote_to_l1 <= 0;
        end else if (read) begin
            promote_to_l1 <= 0;
            l1_hit <= l1_cache_hit;
            l2_hit <= 0;
            read_data <= 0;

            if (l1_cache_hit) begin
                read_data <= l1_data_out;
            end else if (l2_cache_hit) begin
                l2_hit <= 1;
                read_data <= l2_data_out;
                promoted_data <= l2_data_out;
                promote_to_l1 <= 1;
            end else begin
                read_data <= 32'hD00DFEED;
            end
        end
    end

endmodule
