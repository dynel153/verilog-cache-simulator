`timescale 1ns/1ps

module cache_system_tb;

    // Parameters to match the DUT
    parameter ADDR_WIDTH = 11;
    parameter DATA_WIDTH = 11;

    // Testbench signals
    logic clk;
    logic rst;
    logic [ADDR_WIDTH-1:0] addr;
    logic read;
    logic [DATA_WIDTH-1:0] read_data;
    logic l1_hit, l2_hit;

    // Instantiate the DUT (Design Under Test)
    cache_system_2level #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .read(read),
        .read_data(read_data),
        .l1_hit(l1_hit),
        .l2_hit(l2_hit)
    );

    // Clock generation (period = 10ns)
    always #5 clk = ~clk;

    // Initial block to simulate behavior
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        addr = 0;
        read = 0;

        // Hold reset for a few cycles
        #10;
        rst = 0;

        // --- Test sequence begins ---

        // First access (expected L1 and L2 miss, load from memory)
        test_read(11'h123); // address 0x123

        // Second access: same address, should now be L1 hit
        test_read(11'h123);

        // Third access: new address, L1+L2 miss
        test_read(11'h2A3);

        // Fourth: access first address again (still in L1)
        test_read(11'h123);

        // Fifth: access second address again (should be in L1 too)
        test_read(11'h2A3);

        // Sixth: a third unique address to force replacement
        test_read(11'h345);

        // Seventh: back to 0x123, may now be evicted if set/index overlapped
        test_read(11'h123);

        #50;
        $finish;
    end

    // Task to wrap a read cycle
    task test_read(input logic [ADDR_WIDTH-1:0] test_addr);
        begin
            @(negedge clk); // wait for negative edge
            addr = test_addr;
            read = 1;
            @(negedge clk); // one cycle to read
            read = 0;
            @(negedge clk); // wait one cycle for response

            $display("Time %0t | Addr: 0x%0h | Data: 0x%0h | L1 Hit: %0b | L2 Hit: %0b",
                      $time, test_addr, read_data, l1_hit, l2_hit);
        end
    endtask

endmodule