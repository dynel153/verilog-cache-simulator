`timescale 1ns/1ps

module test_cache_system_4way;

    parameter ADDR_WIDTH = 11;
    parameter DATA_WIDTH = 32;

    reg clk, rst, read;
    reg [ADDR_WIDTH-1:0] addr;
    wire [DATA_WIDTH-1:0] read_data;
    wire l1_hit, l2_hit;

    // Instantiate the DUT
    cache_system_4way dut (
        .clk(clk),
        .rst(rst),
        .read(read),
        .addr(addr),
        .read_data(read_data),
        .l1_hit(l1_hit),
        .l2_hit(l2_hit)
    );

    // Clock generator
    always #5 clk = ~clk;

    integer i;
    reg [ADDR_WIDTH-1:0] trace[0:9];

    initial begin
        $dumpfile("cache_system_4way.vcd");
        $dumpvars(0, test_cache_system_4way);

        clk = 0;
        rst = 1;
        read = 0;
        addr = 0;
        #10;
        rst = 0;

        // Test trace: access multiple addresses
        trace[0] = 11'h020;
        trace[1] = 11'h040;
        trace[2] = 11'h060;
        trace[3] = 11'h020; // should hit in L1 if promoted
        trace[4] = 11'h080;
        trace[5] = 11'h0A0;
        trace[6] = 11'h040; // check if evicted
        trace[7] = 11'h0C0;
        trace[8] = 11'h0E0;
        trace[9] = 11'h020; // confirm persistent L1 hit

        $display("Time\tAddr\t\tReadData\tL1_Hit\tL2_Hit");
        for (i = 0; i < 10; i = i + 1) begin
            @(negedge clk);
            addr = trace[i];
            read = 1;
            @(negedge clk);
            read = 0;
            @(negedge clk);
            $display("%0t\t0x%h\t0x%h\t%b\t%b", $time, addr, read_data, l1_hit, l2_hit);
        end

        #20;
        $finish;
    end

endmodule
