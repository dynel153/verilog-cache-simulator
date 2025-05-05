`timescale 1ns / 1ps

module test_cache_4way;

    reg clk;
    reg rst;
    reg read;
    reg [10:0] addr;
    wire [31:0] read_data;
    wire hit;

    // Instantiate the cache module
    cache_4way uut (
        .clk(clk),
        .rst(rst),
        .read(read),
        .addr(addr),
        .read_data(read_data),
        .hit(hit)
    );

    // Clock generation
    always #5 clk = ~clk;

    reg [10:0] trace [0:9]; // Address trace array
    integer i;

    initial begin
        $display("Time\tAddr\tReadData\tHit");

        clk = 0;
        rst = 1;
        read = 0;
        addr = 0;

        #10;
        rst = 0;

        // Sample address trace (testing LRU replacement as well)
        trace[0] = 11'h034;
        trace[1] = 11'h038;
        trace[2] = 11'h03C;
        trace[3] = 11'h040;
        trace[4] = 11'h034; // should be a hit
        trace[5] = 11'h044; // should trigger replacement
        trace[6] = 11'h038; // might be a miss depending on LRU
        trace[7] = 11'h050;
        trace[8] = 11'h03C;
        trace[9] = 11'h034;

        for (i = 0; i < 10; i = i + 1) begin
            addr = trace[i];
            read = 1;
            #10;
            $display("%0t\t%0h\t%h\t%b", $time, addr, read_data, hit);
            read = 0;
            #10;
        end

        $finish;
    end

endmodule
