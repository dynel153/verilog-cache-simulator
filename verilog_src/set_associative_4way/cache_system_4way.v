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

    // Internal wires
    wire [DATA_WIDTH-1:0] l1_data_out;
    wire [DATA_WIDTH-1:0] l2_data_out;
    wire l1_hit_wire;
    wire l2_hit_wire;

    reg write_enable;
    reg [DATA_WIDTH-1:0] promote_data;

    // Instantiate L1
    cache_4way l1 (
        .clk(clk),
        .rst(rst),
        .read(read),
        .write_enable(write_enable),
        .write_data(promote_data),
        .addr(addr),
        .read_data(l1_data_out),
        .hit(l1_hit_wire)
    );

    // Instantiate L2
    cache_4wayl2 l2 (
        .clk(clk),
        .rst(rst),
        .read(read && !l1_hit_wire),
        .write_enable(1'b0),
        .write_data(32'b0),
        .addr(addr),
        .read_data(l2_data_out),
        .hit(l2_hit_wire)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            l1_hit <= 0;
            l2_hit <= 0;
            read_data <= 0;
            write_enable <= 0;
            promote_data <= 0;
        end
        else if (read) begin
            l1_hit <= l1_hit_wire;
            l2_hit <= 0;
            write_enable <= 0;
            read_data <= 0;

            if (l1_hit_wire) begin
                read_data <= l1_data_out;

            end else if (l2_hit_wire) begin
                l2_hit <= 1;
                read_data <= l2_data_out;

                // Promote to L1
                write_enable <= 1;
                promote_data <= l2_data_out;
                $display("PROMOTE: Addr = 0x%h | L2_Hit = %b | Data = 0x%h", addr, l2_hit_wire, l2_data_out);

            end else begin
                // Total miss — fallback memory
                read_data <= 32'hCAFEBABE;
                $display("TOTAL MISS: Addr = 0x%h — Fallback to memory", addr);
            end
        end else begin
            write_enable <= 0;
        end
    end

endmodule
