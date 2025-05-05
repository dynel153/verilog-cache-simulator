``timescale 1ns/1ps

module cache_system_tb;

    // Parameters
    parameter ADDR_WIDTH = 11;
    parameter DATA_WIDTH = 11;

    // DUT Signals
    reg clk;
    reg rst;
    reg [ADDR_WIDTH-1:0] addr;
    reg read;
    wire [DATA_WIDTH-1:0] read_data;
    wire l1_hit;
    wire l2_hit;

    // Instantiate DUT
    cache_system_2level dut (
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

    // Test sequence
    integer i;
    reg [ADDR_WIDTH-1:0] trace [0:9];

    initial begin
        // Initialize
        clk = 0;
        rst = 1;
        read = 0;
        addr = 0;
        #15;
        rst = 0;

        // Test trace
        trace[0] = 11'h123;
        trace[1] = 11'h123;
        trace[2] = 11'h2A3;
        trace[3] = 11'h123;
        trace[4] = 11'h2A3;
        trace[5] = 11'h345;
        trace[6] = 11'h123;
        trace[7] = 11'h200;
        trace[8] = 11'h201;
        trace[9] = 11'h123;

        $display("Time\tAddr\tReadData\tL1_Hit\tL2_Hit");

        for (i = 0; i < 10; i = i + 1) begin
            @(negedge clk);
            addr = trace[i];
            read = 1;
            @(negedge clk);
            read = 0;
            @(negedge clk);  // wait for response
            $display("%0t\t%h\t%h\t\t%b\t%b", $time, addr, read_data, l1_hit, l2_hit);
        end

        #20;
        $finish;
    end

endmodule
