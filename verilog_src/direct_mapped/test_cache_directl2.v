`timescale 1ns / 1ps

module test_cache_directl2;

    reg clk;
    reg rst;
    reg read;
    reg [10:0] addr;
    wire [10:0] read_data;
    wire hit;

    // Instantiate the L2 cache module (DUT)
    cache_directl2 uut (
        .clk(clk),
        .rst(rst),
        .read(read),
        .addr(addr),
        .read_data(read_data),
        .hit(hit)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Address trace
    reg [10:0] trace [0:9];
    integer i;

    initial begin
        $display("Time\tAddr\tReadData\tHit");
        clk = 0;
        rst = 1;
        read = 0;
        addr = 0;

        #10 rst = 0;

        // Sample trace
        trace[0] = 11'd50;
        trace[1] = 11'd60;
        trace[2] = 11'd70;
        trace[3] = 11'd50;
        trace[4] = 11'd80;
        trace[5] = 11'd90;
        trace[6] = 11'd60;
        trace[7] = 11'd100;
        trace[8] = 11'd110;
        trace[9] = 11'd50;

        for (i = 0; i < 10; i = i + 1) begin
            addr = trace[i];
            read = 1;
            #10;
            read = 0;
            $display("%0t\t%0d\t%h\t%b", $time, addr, read_data, hit);
            #10;
        end

        $finish;
    end

endmodule
