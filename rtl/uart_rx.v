`timescale 1ns/1ps

module uart_rx #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,
    input  wire       resetn,
    input  wire       rx,
    output reg [7:0]  rx_data,
    output reg        rx_valid
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    localparam [2:0]
        IDLE  = 3'd0,
        START = 3'd1,
        DATA  = 3'd2,
        STOP  = 3'd3;

    reg [2:0] state;

    reg [31:0] baud_count;
    reg [2:0]  bit_count;
    reg [7:0]  rx_shift;

    always @(posedge clk) begin

        if (!resetn) begin
            state      <= IDLE;
            baud_count <= 32'd0;
            bit_count  <= 3'd0;
            rx_shift   <= 8'd0;
            rx_data    <= 8'd0;
            rx_valid   <= 1'b0;
        end

        else begin

            // Default: rx_valid is a one-clock pulse
            rx_valid <= 1'b0;

            case (state)
                // IDLE: wait for start bit
                IDLE: begin

                    baud_count <= 32'd0;
                    bit_count  <= 3'd0;

                    if (rx == 1'b0) begin
                        state      <= START;
                        baud_count <= 32'd0;
                    end

                end
                // START: verify middle of start bit
                START: begin

                    if (baud_count == (CLKS_PER_BIT/2 - 1)) begin

                        baud_count <= 32'd0;

                        if (rx == 1'b0) begin
                            state <= DATA;
                            bit_count <= 3'd0;
                        end
                        else begin
                            // False start
                            state <= IDLE;
                        end

                    end
                    else begin
                        baud_count <= baud_count + 1'b1;
                    end

                end

                // DATA: receive 8 bits, LSB first
                DATA: begin

                    if (baud_count == CLKS_PER_BIT - 1) begin

                        baud_count <= 32'd0;

                        rx_shift[bit_count] <= rx;

                        if (bit_count == 3'd7) begin
                            state <= STOP;
                        end
                        else begin
                            bit_count <= bit_count + 1'b1;
                        end

                    end
                    else begin
                        baud_count <= baud_count + 1'b1;
                    end

                end

                // STOP: wait for stop bit
                STOP: begin

                    if (baud_count == CLKS_PER_BIT - 1) begin

                        baud_count <= 32'd0;

                        if (rx == 1'b1) begin
                            rx_data  <= rx_shift;
                            rx_valid <= 1'b1;
                        end

                        state <= IDLE;

                    end
                    else begin
                        baud_count <= baud_count + 1'b1;
                    end

                end

                default: begin
                    state <= IDLE;
                end

            endcase

        end

    end

endmodule
