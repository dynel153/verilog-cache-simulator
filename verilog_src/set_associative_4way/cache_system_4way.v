`timescale 1ns/1ps

module cache_system_4way #(
    parameter ADDR_WIDTH = 11,
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rst,
    input read,
    input [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] read_data,
    output reg l1_hit,
    output reg l2_hit
);

    // Internal signals
    wire [DATA_WIDTH-1:0] l1_data_out;
    wire [DATA_WIDTH-1:0] l2_data_out;
    wire l1_local_hit, l2_local_hit;

    reg l1_read, l2_read;
    reg [1:0] state;

    // States
    localparam IDLE = 2'b00,
               READ_L1 = 2'b01,
               READ_L2 = 2'b10,
               MEM_FETCH = 2'b11;

    // Instantiate L1
    cache_4way l1_cache (
        .clk(clk),
        .rst(rst),
        .read(l1_read),
        .addr(addr),
        .read_data(l1_data_out),
        .hit(l1_local_hit)
    );

    // Instantiate L2
    cache_4wayl2 l2_cache (
        .clk(clk),
        .rst(rst),
        .read(l2_read),
        .addr(addr),
        .read_data(l2_data_out),
        .hit(l2_local_hit)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            read_data <= 0;
            l1_hit <= 0;
            l2_hit <= 0;
        end else begin
            l1_read <= 0;
            l2_read <= 0;
            l1_hit <= 0;
            l2_hit <= 0;

            case (state)
                IDLE: begin
                    if (read) begin
                        l1_read <= 1;
                        state <= READ_L1;
                    end
                end

                READ_L1: begin
                    if (l1_local_hit) begin
                        read_data <= l1_data_out;
                        l1_hit <= 1;
                        state <= IDLE;
                    end else begin
                        l2_read <= 1;
                        state <= READ_L2;
                    end
                end

                READ_L2: begin
                    if (l2_local_hit) begin
                        read_data <= l2_data_out;
                        l2_hit <= 1;
                        l1_read <= 1; // Promote to L1
                        state <= IDLE;
                    end else begin
                        read_data <= 32'hCAFEBABE; // Simulate memory fetch
                        l1_read <= 1;
                        l2_read <= 1;
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
