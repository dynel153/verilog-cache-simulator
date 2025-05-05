`timescale 1ns/1ps

module cache_system_4way #(
    parameter ADDR_WIDTH = 11,
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rst,
    input read,
    input [ADDR_WIDTH-1:0] addr,
    output [DATA_WIDTH-1:0] read_data,
    output l1_hit,
    output l2_hit
);

    // Internal signals
    wire [DATA_WIDTH-1:0] l1_data_out;
    wire [DATA_WIDTH-1:0] l2_data_out;
    reg [DATA_WIDTH-1:0] mem_data = 32'hCAFEBABE;

    reg l1_read, l2_read;
    wire l1_local_hit, l2_local_hit;
    reg [DATA_WIDTH-1:0] l1_fill_data;
    reg [DATA_WIDTH-1:0] final_data;
    reg l1_hit_reg, l2_hit_reg;

    assign read_data = final_data;
    assign l1_hit = l1_hit_reg;
    assign l2_hit = l2_hit_reg;

    // Instantiate L1 Cache
    cache_4way l1_cache (
        .clk(clk),
        .rst(rst),
        .read(l1_read),
        .addr(addr),
        .read_data(l1_data_out),
        .hit(l1_local_hit)
    );

    // Instantiate L2 Cache
    cache_4wayl2 l2_cache (
        .clk(clk),
        .rst(rst),
        .read(l2_read),
        .addr(addr),
        .read_data(l2_data_out),
        .hit(l2_local_hit)
    );

    // Control FSM
    typedef enum reg [1:0] {
        IDLE, READ_L1, READ_L2, MEM_FETCH
    } state_t;

    state_t state, next_state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            l1_hit_reg <= 0;
            l2_hit_reg <= 0;
            final_data <= 0;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        // Defaults
        l1_read = 0;
        l2_read = 0;
        next_state = IDLE;

        case (state)
            IDLE: begin
                if (read)
                    next_state = READ_L1;
            end

            READ_L1: begin
                l1_read = 1;
                if (l1_local_hit) begin
                    next_state = IDLE;
                end else begin
                    next_state = READ_L2;
                end
            end

            READ_L2: begin
                l2_read = 1;
                if (l2_local_hit) begin
                    next_state = IDLE;
                end else begin
                    next_state = MEM_FETCH;
                end
            end

            MEM_FETCH: begin
                next_state = IDLE;
            end
        endcase
    end

    // Output and promotion logic
    always @(posedge clk) begin
        if (rst) begin
            final_data <= 0;
            l1_hit_reg <= 0;
            l2_hit_reg <= 0;
        end else begin
            case (state)
                READ_L1: begin
                    if (l1_local_hit) begin
                        final_data <= l1_data_out;
                        l1_hit_reg <= 1;
                        l2_hit_reg <= 0;
                    end
                end

                READ_L2: begin
                    if (l2_local_hit) begin
                        final_data <= l2_data_out;
                        l1_hit_reg <= 0;
                        l2_hit_reg <= 1;
                        // Promote to L1 by forcing an L1 write (reuse l1_read)
                        l1_read <= 1;
                    end
                end

                MEM_FETCH: begin
                    final_data <= mem_data;
                    l1_hit_reg <= 0;
                    l2_hit_reg <= 0;
                    // Simulate filling L2 and then L1
                    l2_read <= 1;
                    l1_read <= 1;
                end
            endcase
        end
    end
endmodule
