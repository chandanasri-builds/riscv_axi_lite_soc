`timescale 1ns/1ps

module tb_uart_rx;

    reg clk = 0;
    reg resetn = 0;

    reg [7:0] tx_data;
    reg       tx_start;

    wire tx;
    wire tx_busy;

    wire [7:0] rx_data;
    wire       rx_valid;

    // UART TX
    uart_tx #(
        .CLK_FREQ(10_000_000),
        .BAUD_RATE(1_000_000)
    ) tx_inst (
        .clk(clk),
        .resetn(resetn),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    // UART RX
    uart_rx #(
        .CLK_FREQ(10_000_000),
        .BAUD_RATE(1_000_000)
    ) rx_inst (
        .clk(clk),
        .resetn(resetn),
        .rx(tx),
        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );

    // 10 MHz clock → 100 ns period

    always #50 clk = ~clk;

    // TEST
    initial begin

        $dumpfile("uart_rx.vcd");
        $dumpvars(0, tb_uart_rx);

        tx_data  = 8'h43;       // ASCII 'C'
        tx_start = 1'b0;

        #200;

        resetn = 1'b1;

        #200;

        // Start transmission
        tx_start = 1'b1;

        #100;

        tx_start = 1'b0;

        // Wait until receiver gets the byte
        wait (rx_valid);

        $display("--------------------------------");
        $display("UART RX DATA = %h", rx_data);

        if (rx_data == 8'h43)
            $display("UART RX PASSED.");
        else
            $display("UART RX FAILED.");

        $display("--------------------------------");

        #200;

        $finish;

    end

endmodule
