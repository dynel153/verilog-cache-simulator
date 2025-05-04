``timescale 1ns / 1ps  // Sets the time unit to nanoseconds and time precision to picoseconds

module test_cache_directl2; // Defines the testbench module (no inputs or outputs)

    reg clk;             // A register used to generate the clock signal
    reg [10:0] addr;     // 11-bit address input that will be sent to the cache
    wire hit;            // Output signal from the cache: 1 = hit, 0 = miss

    // Instantiate the cache module (Unit Under Test)
    cache_directl2 uut (
        .clk(clk),       // Connects testbench's clk to cache module's clk input
        .addr(addr),     // Connects testbench's addr to cache's addr input
        .hit(hit)        // Connects cache's hit output back to the testbench
    );

    // Generate a clock signal that toggles every 5 nanoseconds
    always #5 clk = ~clk;

    // Address trace (10 test addresses)
    reg [10:0] trace [0:9]; // Creates an array to hold 10 test addresses (each 11 bits wide)
    integer i;              // Loop counter used in the for-loop

    initial begin                   // This block runs once at the start of the simulation
        $display("Time\tAddress\t\tHit");  // Prints column headers
        clk = 0;                     // Initializes the clock signal to 0

        // Sample address trace — simulates CPU accessing memory
        trace[0] = 11'd34;   // Decimal 34 encoded as 11-bit binary
        trace[1] = 11'd34;
        trace[2] = 11'd200;
        trace[3] = 11'd34;
        trace[4] = 11'd512;
        trace[5] = 11'd528;  // Might map to same index as 512 (conflict test)
        trace[6] = 11'd34;
        trace[7] = 11'd200;
        trace[8] = 11'd768;
        trace[9] = 11'd34;

        // Feed addresses into the cache one by one
        for (i = 0; i < 10; i = i + 1) begin
            addr = trace[i];                    // Set current address
            #10;                                // Wait one clock cycle (10 ns)
            $display("%0t\t%0d\t\t%b", $time, addr, hit); 
            // Print simulation time, current address, and hit status
        end

        $finish;  // Ends the simulation cleanly
    end

endmodule
