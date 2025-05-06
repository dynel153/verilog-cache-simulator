`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Module: test_cache_all
// Description: Unified testbench for comparing performance of direct-mapped,
//              2-way, and 4-way set-associative cache systems. Measures hit/miss
//              counts and calculates Average Memory Access Time (AMAT).
// -----------------------------------------------------------------------------

module test_cache_all;

    // ----------------------------
    // Testbench Signals
    // ----------------------------
    reg clk;
    reg rst;
    reg read;
    reg [10:0] addr;

    wire [31:0] read_data_direct;
    wire [31:0] read_data_2way;
    wire [31:0] read_data_4way;

    reg [31:0] direct_hit, two_way_hit, four_way_hit;
    reg [31:0] direct_miss, two_way_miss, four_way_miss;

    integer i;

    // ----------------------------
    // AMAT Calculation Variables
    // ----------------------------
    real direct_miss_rate, twoway_miss_rate, fourway_miss_rate;
    real l1_time, l2_time, mem_time, l2_hit_prob;
    real amat_direct, amat_2way, amat_4way;

    // ----------------------------
    // Instantiate Cache Systems
    // ----------------------------

    wire l1_hit_direct, l1_hit_2way, l1_hit_4way;
    wire l2_hit_direct, l2_hit_2way, l2_hit_4way;

    cache_system_direct cache_direct (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .read(read),
        .read_data(read_data_direct),
        .l1_hit(l1_hit_direct),
        .l2_hit(l2_hit_direct)
    );

    cache_system_2way cache_2way (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .read(read),
        .read_data(read_data_2way),
        .l1_hit(l1_hit_2way),
        .l2_hit(l2_hit_2way)
    );

    cache_system_4way cache_4way (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .read(read),
        .read_data(read_data_4way),
        .l1_hit(l1_hit_4way),
        .l2_hit(l2_hit_4way)
    );

    // ----------------------------
    // Clock Generator (10 ns period)
    // ----------------------------
    always #5 clk = ~clk;

    // ----------------------------
    // Simulation Entry Point
    // ----------------------------
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        read = 0;
        addr = 0;

        direct_hit = 0; 
        two_way_hit = 0; 
        four_way_hit = 0;
        direct_miss = 0;
        two_way_miss = 0;
        four_way_miss = 0;

        // Apply reset for 10 ns
        #10 rst = 0;

        // ----------------------------
        // Perform 10,000 random accesses
        // ----------------------------
        for (i = 0; i < 10000; i = i + 1) begin
            #10;
            addr = $random % 2048; // Random address in range [0, 2047]
            read = 1;
            #10 read = 0;

            // Count hits/misses for each system
            if (l1_hit_direct) direct_hit = direct_hit + 1;
            else direct_miss = direct_miss + 1;

            if (l1_hit_2way) two_way_hit = two_way_hit + 1;
            else two_way_miss = two_way_miss + 1;

            if (l1_hit_4way) four_way_hit = four_way_hit + 1;
            else four_way_miss = four_way_miss + 1;

            // Optional display for tracing
            $display("Access %0d: Addr = 0x%03x | Direct: %s | 2-Way: %s | 4-Way: %s",
                i, addr,
                l1_hit_direct ? "HIT " : "MISS",
                l1_hit_2way   ? "HIT " : "MISS",
                l1_hit_4way   ? "HIT " : "MISS"
            );
        end

        // ----------------------------
        // Output Summary Stats
        // ----------------------------
        $display("\n--- Simulation Summary ---");
        $display("Direct Cache: Hits = %0d, Misses = %0d", direct_hit, direct_miss);
        $display("2-Way Cache : Hits = %0d, Misses = %0d", two_way_hit, two_way_miss);
        $display("4-Way Cache : Hits = %0d, Misses = %0d", four_way_hit, four_way_miss);

        // ----------------------------
        // Compute AMAT (Average Memory Access Time)
        // ----------------------------
        direct_miss_rate = direct_miss / 10000.0;
        twoway_miss_rate = two_way_miss / 10000.0;
        fourway_miss_rate = four_way_miss / 10000.0;

        // Assumed cycle times
        l1_time = 1;
        l2_time = 5;
        mem_time = 100;
        l2_hit_prob = 0.5;  // Simplified assumption

        // AMAT formulas
        amat_direct = l1_time + direct_miss_rate * (l2_time + (1 - l2_hit_prob) * mem_time);
        amat_2way   = l1_time + twoway_miss_rate * (l2_time + (1 - l2_hit_prob) * mem_time);
        amat_4way   = l1_time + fourway_miss_rate * (l2_time + (1 - l2_hit_prob) * mem_time);

        // Display results
        $display("\n--- Final AMAT Results ---");
        $display("Direct-Mapped AMAT: %.2f cycles", amat_direct);
        $display("2-Way Set AMAT    : %.2f cycles", amat_2way);
        $display("4-Way Set AMAT    : %.2f cycles", amat_4way);

        // Finish simulation
        $finish;
    end
endmodule
