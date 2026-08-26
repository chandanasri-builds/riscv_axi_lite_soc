`timescale 1ns/1ps
module uart_tx #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,
    input  wire       resetn,

    input  wire [7:0] tx_data,
    input  wire       tx_start,

    output reg        tx,
    output reg        tx_busy
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    reg [31:0] baud_count;
    reg [3:0]  bit_count;
    reg [9:0]  tx_shift;

    always @(posedge clk) begin
        if (!resetn) begin
            tx         <= 1'b1;   //UART's idle state is High
            tx_busy    <= 1'b0;
            baud_count <= 32'd0;
            bit_count  <= 4'd0;
            tx_shift   <= 10'b1111111111;
        end
        else begin

            if (tx_start && !tx_busy) begin  //transmitter isn't already busy.
                // 1 start bit + 8 data bits + 1 stop bit
                tx_shift   <= {1'b1, tx_data, 1'b0}; //UART sends the data bits LSB first.
                tx_busy    <= 1'b1; 
                baud_count <= 32'd0;
                bit_count  <= 4'd0;
                tx         <= 1'b0; //start bit
            end
            else if (tx_busy) begin
                if (baud_count == CLKS_PER_BIT - 1) begin //wait ~434 clocks, then change uart bit 
                    baud_count <= 32'd0;
                    if (bit_count == 4'd9) begin
                        tx      <= 1'b1;
                        tx_busy <= 1'b0;
                    end
                    else begin
                        bit_count <= bit_count + 1'b1;
                        tx_shift  <= {1'b1, tx_shift[9:1]};
                        tx        <= tx_shift[1];
                    end
                end
//BEFORE shift: 1  D7  D6  D5  D4  D3  D2  D1  D0   0
//AFTER: shift : 1   1  D7  D6  D5  D4  D3  D2  D1  D0
                else begin
                    baud_count <= baud_count + 1'b1;
                end
            end
        end
    end

endmodule
