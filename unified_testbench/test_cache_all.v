`timescale 1ns/1ps

module test_cache_all;

    // Parameters
    parameter ADDR_WIDTH = 11;
    parameter DATA_WIDTH = 32;
    parameter TRACE_LENGTH = 10;

    // Inputs
    reg clk;
    reg rst;
    reg read;
    reg [ADDR_WIDTH-1:0] addr;

    // Shared access trace
    reg [ADDR_WIDTH-1:0] trace [0:TRACE_LENGTH-1];

    // Outputs for each cache system
    wire [DATA_WIDTH-1:0] data_direct, data_2way, data_4way;
    wire hit_direct, hit_2way, hit_4way;

    // Instantiate Direct-Mapped Cache
    cache_system_direct direct_cache (
        .clk(clk), .rst(rst), .read(read), .addr(addr),
        .read_data(data_direct), .hit(hit_direct)
    );

    // Instantiate 2-Way Cache
    cache_system_full2way cache_2way (
        .clk(clk), .rst(rst), .read(read), .addr(addr),
        .read_data(data_2way), .l1_hit(hit_2way), .l2_hit()
    );

    // Instantiate 4-Way Cache
    cache_system_4way cache_4way (
        .clk(clk), .rst(rst), .read(read), .addr(addr),
        .read_data(data_4way), .l1_hit(hit_4way), .l2_hit()
    );

    // Stats
    integer i;
    integer hits_direct = 0, hits_2way = 0, hits_4way = 0;

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize trace
        trace[0] = 11'h020;
        trace[1] = 11'h040;
        trace[2] = 11'h060;
        trace[3] = 11'h020;
        trace[4] = 11'h080;
        trace[5] = 11'h0a0;
        trace[6] = 11'h040;
        trace[7] = 11'h0c0;
        trace[8] = 11'h0e0;
        trace[9] = 11'h020;

        // Init signals
        clk = 0; rst = 1; read = 0; addr = 0;
        #10 rst = 0;

        $display("Time\tAddr\tDirectHit\t2WayHit\t4WayHit\tDirectData\t2WayData\t4WayData");

        for (i = 0; i < TRACE_LENGTH; i = i + 1) begin
            @(negedge clk);
            addr = trace[i];
            read = 1;
            @(negedge clk);
            read = 0;
            @(negedge clk);
            $display("%0t\t%h\t%b\t\t%b\t\t%b\t%h\t%h\t%h", $time, addr, hit_direct, hit_2way, hit_4way, data_direct, data_2way, data_4way);

            // Count hits
            if (hit_direct) hits_direct = hits_direct + 1;
            if (hit_2way) hits_2way = hits_2way + 1;
            if (hit_4way) hits_4way = hits_4way + 1;
        end

        $display("\n--- Results ---");
        $display("Direct-Mapped Hits: %0d / %0d", hits_direct, TRACE_LENGTH);
        $display("2-Way SA Hits:      %0d / %0d", hits_2way, TRACE_LENGTH);
        $display("4-Way SA Hits:      %0d / %0d", hits_4way, TRACE_LENGTH);

        $finish;
    end

endmodule
