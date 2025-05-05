`timescale 1ns / 1ps  // Sets the time unit to nanoseconds and time precision to picoseconds

module test_cache_direct;

    reg clk;
    reg rst;
    reg read;
    reg [10:0] addr;
    wire [10:0] read_data;
    wire hit;

    // Instantiate the cache module
    cache_direct uut (
        .clk(clk),
        .rst(rst),
        .read(read),
        .addr(addr),
        .read_data(read_data),
        .hit(hit)
    );

    always #5 clk = ~clk;  // Clock toggles every 5 ns

    // Address trace (10 test addresses)
    reg [10:0] trace [0:9];
    integer i;

    initial begin
        $display("Time\tAddress\tReadData\tHit");

        clk = 0;
        rst = 1;
        read = 0;
        addr = 0;

        #10;
        rst = 0;

        // Sample addresses
        trace[0] = 11'd34;
        trace[1] = 11'd34;
        trace[2] = 11'd200;
        trace[3] = 11'd34;
        trace[4] = 11'd512;
        trace[5] = 11'd528;
        trace[6] = 11'd34;
        trace[7] = 11'd200;
        trace[8] = 11'd768;
        trace[9] = 11'd34;

        for (i = 0; i < 10; i = i + 1) begin
            @(negedge clk);
            addr = trace[i];
            read = 1;
            @(negedge clk);
            read = 0;
            @(negedge clk);
            $display("%0t\t%0d\t%0h\t\t%b", $time, addr, read_data, hit);
        end

        $finish;
    end

endmodule
