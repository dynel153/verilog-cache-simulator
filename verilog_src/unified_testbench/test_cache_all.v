`timescale 1ns/1ps

module test_cache_all;

    // Declare variables to track hits/misses for each cache
    reg clk;
    reg rst;
    reg read;
    reg [10:0] addr;
    wire [31:0] read_data;

    // Declare registers for hits and misses
    reg [31:0] direct_hit, two_way_hit, four_way_hit;
    reg [31:0] direct_miss, two_way_miss, four_way_miss;

    // Instantiate the caches
    wire l1_hit_direct, l1_hit_2way, l1_hit_4way;
    wire l2_hit_direct, l2_hit_2way, l2_hit_4way;
    
    cache_system_direct cache_direct (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .read(read),
        .read_data(read_data),
        .l1_hit(l1_hit_direct),
        .l2_hit(l2_hit_direct)
    );

    cache_system_2way cache_2way (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .read(read),
        .read_data(read_data),
        .l1_hit(l1_hit_2way),
        .l2_hit(l2_hit_2way)
    );

    cache_system_4way cache_4way (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .read(read),
        .read_data(read_data),
        .l1_hit(l1_hit_4way),
        .l2_hit(l2_hit_4way)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        read = 0;
        addr = 0;

        // Reset the counters
        direct_hit = 0; 
        two_way_hit = 0; 
        four_way_hit = 0;
        direct_miss = 0;
        two_way_miss = 0;
        four_way_miss = 0;

        // Apply reset
        #10 rst = 0;

        // Test 1: Access address 0x020
        #10 addr = 11'h020;
        read = 1;  // Start read cycle

        // Wait for results and update hit/miss counters
        #10;
        if (l1_hit_direct) direct_hit = direct_hit + 1;
        else direct_miss = direct_miss + 1;

        if (l1_hit_2way) two_way_hit = two_way_hit + 1;
        else two_way_miss = two_way_miss + 1;

        if (l1_hit_4way) four_way_hit = four_way_hit + 1;
        else four_way_miss = four_way_miss + 1;

        // Test 2: Access address 0x040
        #10 addr = 11'h040;

        // Repeat the process for other addresses
        #10;
        if (l1_hit_direct) direct_hit = direct_hit + 1;
        else direct_miss = direct_miss + 1;

        if (l1_hit_2way) two_way_hit = two_way_hit + 1;
        else two_way_miss = two_way_miss + 1;

        if (l1_hit_4way) four_way_hit = four_way_hit + 1;
        else four_way_miss = four_way_miss + 1;

        // Add more tests as needed...

        // Finish simulation
        #10;
        $finish;
    end

    // Display results
    always @(posedge clk) begin
        $display("Direct Hit: %d, Direct Miss: %d", direct_hit, direct_miss);
        $display("2-way Hit: %d, 2-way Miss: %d", two_way_hit, two_way_miss);
        $display("4-way Hit: %d, 4-way Miss: %d", four_way_hit, four_way_miss);
    end

endmodule
