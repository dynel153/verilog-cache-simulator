`timescale 1ns/1ps

module test_cache_4wayl2;

    // Parameters
    parameter ADDR_WIDTH = 11;
    parameter DATA_WIDTH = 32;

    // Inputs
    reg clk;
    reg rst;
    reg read;
    reg [ADDR_WIDTH-1:0] addr;

    // Outputs
    wire hit;
    wire [DATA_WIDTH-1:0] read_data;

    // Instantiate the cache module
    cache_4wayl2 uut (
        .clk(clk),
        .rst(rst),
        .read(read),
        .addr(addr),
        .hit(hit),
        .read_data(read_data)
    );

    // Clock generation
    always #5 clk = ~clk;

    integer i;

    initial begin
        $display("Starting test for cache_4wayl2...");
        $dumpfile("cache_4wayl2.vcd");
        $dumpvars(0, test_cache_4wayl2);

        // Initialize
        clk = 0;
        rst = 1;
        read = 0;
        addr = 0;
        #10;

        rst = 0;

        // Phase 1: Fill different blocks (simulate compulsory misses)
        for (i = 0; i < 8; i = i + 1) begin
            addr = i * 32;  // Force different blocks
            read = 1;
            #10;
            read = 0;
            #10;
            $display("Access %0d: Addr = 0x%0h | HIT = %0d | Data = 0x%0h", i, addr, hit, read_data);
        end

        // Phase 2: Re-access same blocks (should produce hits)
        for (i = 0; i < 8; i = i + 1) begin
            addr = i * 32;  // Same as before
            read = 1;
            #10;
            read = 0;
            #10;
            $display("Reaccess %0d: Addr = 0x%0h | HIT = %0d | Data = 0x%0h", i, addr, hit, read_data);
        end

        // Phase 3: Evict some blocks (test pseudo-LRU)
        for (i = 8; i < 12; i = i + 1) begin
            addr = i * 32;
            read = 1;
            #10;
            read = 0;
            #10;
            $display("Evict %0d: Addr = 0x%0h | HIT = %0d | Data = 0x%0h", i, addr, hit, read_data);
        end

        // Phase 4: Check if old blocks were evicted
        addr = 0;
        read = 1;
        #10;
        read = 0;
        $display("Post-eviction check: Addr = 0x%0h | HIT = %0d | Data = 0x%0h", addr, hit, read_data);

        $finish;
    end
endmodule
