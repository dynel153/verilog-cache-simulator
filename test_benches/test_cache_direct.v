`timescale 1ns / 1ps

module test_cache_direct;

    reg clk;
    reg [10:0] addr;
    wire hit;

    // Instantiate the cache module
    cache_direct uut (
        .clk(clk),
        .addr(addr),
        .hit(hit)
    );

    // Generate a clock that toggles every 5 time units
    always #5 clk = ~clk;

    // Address trace (10 test addresses)
    reg [10:0] trace [0:9];
    integer i;

    initial begin
        $display("Time\tAddress\t\tHit");
        clk = 0;

        // Sample address trace
        trace[0] = 11'd34;
        trace[1] = 11'd34;
        trace[2] = 11'd200;
        trace[3] = 11'd34;
        trace[4] = 11'd512;
        trace[5] = 11'd528; // may map to same index as 512
        trace[6] = 11'd34;
        trace[7] = 11'd200;
        trace[8] = 11'd768;
        trace[9] = 11'd34;

        // Apply addresses to cache one by one
        for (i = 0; i < 10; i = i + 1) begin
            addr = trace[i];
            #10; // Wait one clock cycle
            $display("%0t\t%0d\t\t%b", $time, addr, hit);
        end

        $finish;
    end

endmodule
