`timescale 1ns/1ps

module test_cache_all;

    reg clk;
    reg rst;
    reg read;
    reg [10:0] addr;
    wire [31:0] read_data_direct, read_data_2way, read_data_4way;

    wire l1_hit_direct, l1_hit_2way, l1_hit_4way;
    wire l2_hit_direct, l2_hit_2way, l2_hit_4way;

    reg [31:0] direct_hit, two_way_hit, four_way_hit;
    reg [31:0] direct_miss, two_way_miss, four_way_miss;

    // Clock generation
    always #5 clk = ~clk;

    // Instantiate cache systems
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

    integer i;
    reg [10:0] random_addr;

    initial begin
        // Initialize
        clk = 0;
        rst = 1;
        read = 0;
        addr = 0;
        direct_hit = 0; direct_miss = 0;
        two_way_hit = 0; two_way_miss = 0;
        four_way_hit = 0; four_way_miss = 0;

        #20 rst = 0;

        // 10,000 Random Access Test
        for (i = 0; i < 10000; i = i + 1) begin
            #10;
            random_addr = $random % 2048;
            addr = random_addr;
            read = 1;
            #10;
            read = 0;

            if (l1_hit_direct) direct_hit = direct_hit + 1; else direct_miss = direct_miss + 1;
            if (l1_hit_2way)   two_way_hit = two_way_hit + 1; else two_way_miss = two_way_miss + 1;
            if (l1_hit_4way)   four_way_hit = four_way_hit + 1; else four_way_miss = four_way_miss + 1;

            $display("Access %0d: Addr = 0x%03h | Direct: %s | 2-Way: %s | 4-Way: %s",
                     i, addr,
                     l1_hit_direct ? "HIT " : "MISS",
                     l1_hit_2way   ? "HIT " : "MISS",
                     l1_hit_4way   ? "HIT " : "MISS");
        end

        // Final summary
        $display("\n--- Simulation Summary ---");
        $display("Direct Cache: Hits = %0d, Misses = %0d", direct_hit, direct_miss);
        $display("2-Way Cache : Hits = %0d, Misses = %0d", two_way_hit, two_way_miss);
        $display("4-Way Cache : Hits = %0d, Misses = %0d", four_way_hit, four_way_miss);

        $finish;
    end

endmodule
