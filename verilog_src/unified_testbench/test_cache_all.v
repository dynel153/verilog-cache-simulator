`timescale 1ns/1ps

module test_cache_all;
    reg clk, rst, read;
    reg [10:0] addr;

    wire [10:0] read_data_direct, read_data_2way;
    wire [31:0] read_data_4way;
    wire l1_hit_direct, l2_hit_direct;
    wire l1_hit_2way,   l2_hit_2way;
    wire l1_hit_4way,   l2_hit_4way;

    integer i;
    integer hit_count_direct = 0, miss_count_direct = 0;
    integer hit_count_2way   = 0, miss_count_2way   = 0;
    integer hit_count_4way   = 0, miss_count_4way   = 0;

    // Instantiate Direct-mapped Cache
    cache_system_direct direct_cache (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .read(read),
        .read_data(read_data_direct),
        .l1_hit(l1_hit_direct),
        .l2_hit(l2_hit_direct)
    );

    // Instantiate 2-Way Cache
    cache_system_2way assoc2way_cache (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .read(read),
        .read_data(read_data_2way),
        .l1_hit(l1_hit_2way),
        .l2_hit(l2_hit_2way)
    );

    // Instantiate 4-Way Cache
    cache_system_4way assoc4way_cache (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .read(read),
        .read_data(read_data_4way),
        .l1_hit(l1_hit_4way),
        .l2_hit(l2_hit_4way)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $display("Starting unified cache test...");
        clk = 0; rst = 1; read = 0; addr = 0;
        #20 rst = 0;

        // Run test accesses
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            addr <= i * 16;
            read <= 1;
            @(posedge clk);
            read <= 0;

            // Direct-mapped stats
            if (l1_hit_direct || l2_hit_direct)
                hit_count_direct = hit_count_direct + 1;
            else
                miss_count_direct = miss_count_direct + 1;

            // 2-way stats
            if (l1_hit_2way || l2_hit_2way)
                hit_count_2way = hit_count_2way + 1;
            else
                miss_count_2way = miss_count_2way + 1;

            // 4-way stats
            if (l1_hit_4way || l2_hit_4way)
                hit_count_4way = hit_count_4way + 1;
            else
                miss_count_4way = miss_count_4way + 1;
        end

        // Calculate AMAT (assume L1 = 1 cycle, L2 = 10, Mem = 100)
        $display("\n==== RESULTS ====");
        $display("Direct-Mapped Hits: %0d, Misses: %0d", hit_count_direct, miss_count_direct);
        $display("2-Way Assoc Hits:   %0d, Misses: %0d", hit_count_2way, miss_count_2way);
        $display("4-Way Assoc Hits:   %0d, Misses: %0d", hit_count_4way, miss_count_4way);

        real total = hit_count_direct + miss_count_direct;
        real amat_direct = (hit_count_direct * 1 + (miss_count_direct * 10)) / total;
        real amat_2way    = (hit_count_2way * 1 + (miss_count_2way * 10)) / total;
        real amat_4way    = (hit_count_4way * 1 + (miss_count_4way * 10)) / total;

        $display("AMAT (Direct): %.2f", amat_direct);
        $display("AMAT (2-Way):  %.2f", amat_2way);
        $display("AMAT (4-Way):  %.2f", amat_4way);

        $finish;
    end
endmodule
