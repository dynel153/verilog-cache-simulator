`timescale 1ns/1ps

module test_cache_all;

    // Clock and control signals
    reg clk;
    reg rst;
    reg read;
    reg [10:0] addr;

    // Individual read_data wires for each cache
    wire [31:0] read_data_direct;
    wire [31:0] read_data_2way;
    wire [31:0] read_data_4way;

    // Hit/miss counters
    reg [31:0] direct_hit, two_way_hit, four_way_hit;
    reg [31:0] direct_miss, two_way_miss, four_way_miss;

    // Hit signals
    wire l1_hit_direct, l1_hit_2way, l1_hit_4way;
    wire l2_hit_direct, l2_hit_2way, l2_hit_4way;

    // Instantiate Direct-Mapped Cache
    cache_system_direct cache_direct (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .read(read),
        .read_data(read_data_direct),  // updated
        .l1_hit(l1_hit_direct),
        .l2_hit(l2_hit_direct)
    );

    // Instantiate 2-Way Set-Associative Cache
    cache_system_2way cache_2way (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .read(read),
        .read_data(read_data_2way),    // updated
        .l1_hit(l1_hit_2way),
        .l2_hit(l2_hit_2way)
    );

    // Instantiate 4-Way Set-Associative Cache
    cache_system_4way cache_4way (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .read(read),
        .read_data(read_data_4way),    // updated
        .l1_hit(l1_hit_4way),
        .l2_hit(l2_hit_4way)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        clk = 0;
        rst = 1;
        read = 0;
        addr = 0;

        direct_hit = 0; two_way_hit = 0; four_way_hit = 0;
        direct_miss = 0; two_way_miss = 0; four_way_miss = 0;

        #10 rst = 0;

        // === Sample test 1 ===
        #10 addr = 11'h020; read = 1;

        #10;
        if (l1_hit_direct) direct_hit = direct_hit + 1;
        else direct_miss = direct_miss + 1;

        if (l1_hit_2way) two_way_hit = two_way_hit + 1;
        else two_way_miss = two_way_miss + 1;

        if (l1_hit_4way) four_way_hit = four_way_hit + 1;
        else four_way_miss = four_way_miss + 1;

        // === Sample test 2 ===
        #10 addr = 11'h040;

        #10;
        if (l1_hit_direct) direct_hit = direct_hit + 1;
        else direct_miss = direct_miss + 1;

        if (l1_hit_2way) two_way_hit = two_way_hit + 1;
        else two_way_miss = two_way_miss + 1;

        if (l1_hit_4way) four_way_hit = four_way_hit + 1;
        else four_way_miss = four_way_miss + 1;

        // Add more tests here...

        #10;
        $finish;
    end

    // Display results every cycle (optional)
    always @(posedge clk) begin
        $display("Direct Hit: %d, Miss: %d | 2-Way Hit: %d, Miss: %d | 4-Way Hit: %d, Miss: %d",
                 direct_hit, direct_miss, two_way_hit, two_way_miss, four_way_hit, four_way_miss);
    end

endmodule
