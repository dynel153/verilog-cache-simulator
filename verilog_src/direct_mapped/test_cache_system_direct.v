`timescale 1ns/1ps

module test_cache_system_direct;

    parameter ADDR_WIDTH = 11;
    parameter DATA_WIDTH = 32;

    logic clk;
    logic rst;
    logic read;
    logic [ADDR_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] read_data;
    logic l1_hit, l2_hit;

    // Instantiate the DUT
    cache_system_direct dut (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .read(read),
        .read_data(read_data),
        .l1_hit(l1_hit),
        .l2_hit(l2_hit)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test procedure
    initial begin
        clk = 0;
        rst = 1;
        read = 0;
        addr = 0;

        #10 rst = 0;

        $display("Time\tAddr\tReadData\tL1_Hit\tL2_Hit");
        test_read(11'h34);
        test_read(11'h200);
        test_read(11'h34);     // L1 hit expected
        test_read(11'h512);
        test_read(11'h200);    // L1 hit expected
        test_read(11'h34);     // L1 hit again
        test_read(11'h100);    // new address

        #50;
        $finish;
    end

    // Helper task
    task test_read(input [ADDR_WIDTH-1:0] test_addr);
        begin
            @(negedge clk);
            addr = test_addr;
            read = 1;
            @(negedge clk);
            read = 0;
            @(negedge clk);
            $display("%0t\t%0h\t%0h\t%b\t%b", $time, test_addr, read_data, l1_hit, l2_hit);
        end
    endtask

endmodule
