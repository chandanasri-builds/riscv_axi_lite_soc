`timescale 1ns/1ps

module tb_uart_tx;

    reg clk = 0;
    reg resetn = 0;

    reg [7:0] tx_data;
    reg       tx_start;

    wire tx;
    wire tx_busy;

    // Small values for fast simulation
    uart_tx #(
        .CLK_FREQ(10_000_000),
        .BAUD_RATE(1_000_000)
    ) dut (
        .clk(clk),
        .resetn(resetn),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    always #10 clk = ~clk;

    initial begin
        $dumpfile("uart_tx.vcd");
        $dumpvars(0, tb_uart_tx);

        tx_data  = 8'h43;   // ASCII 'C'
        tx_start = 0;

        #100;
        resetn = 1;

        #100;
        tx_start = 1;

        #10;
        tx_start = 0;

        wait (!tx_busy);

        #100;

        $display("UART transmission complete.");
        $finish;
    end

endmodule
