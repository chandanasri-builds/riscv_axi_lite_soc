`timescale 1ns/1ps

module tb_soc;

    reg clk;
    reg resetn;

    // External UART pins
    reg  uart_rx;
    wire uart_tx;
    wire uart_tx_busy;

    // =========================================================
    // DUT
    // =========================================================

    soc_top #(
        .CLK_FREQ(10_000_000),
        .BAUD_RATE(1_000_000)
    ) dut (
        .clk(clk),
        .resetn(resetn),

        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .uart_tx_busy(uart_tx_busy)
    );

    // =========================================================
    // CLOCK
    // 10 MHz = 100 ns period
    // =========================================================

    always #50 clk = ~clk;

    // =========================================================
    // TEST
    // =========================================================

    initial begin

        $dumpfile("soc.vcd");
        $dumpvars(0, tb_soc);

        clk     = 1'b0;
        resetn  = 1'b0;
        uart_rx = 1'b1;       // UART idle = HIGH

        $display("");
        $display("======================================");
        $display("        RISC-V AXI UART SoC");
        $display("======================================");

        // -----------------------------------------------------
        // RESET
        // -----------------------------------------------------

        $display("RESET");

        #500;

        resetn = 1'b1;

        $display("RESET RELEASED");

        // -----------------------------------------------------
        // Wait for CPU to execute program
        // -----------------------------------------------------

        $display("");
        $display("Waiting for PicoRV32 to access UART...");
        
        wait (uart_tx_busy);

        $display("UART TX STARTED.");
        $display("CPU successfully reached UART TX register.");

        // -----------------------------------------------------
        // Wait for UART transmission to finish
        // -----------------------------------------------------

        wait (!uart_tx_busy);

        $display("UART TX COMPLETED.");

        // -----------------------------------------------------
        // PASS
        // -----------------------------------------------------

        $display("");
        $display("======================================");
        $display("       RISC-V AXI UART TEST PASSED");
        $display("======================================");

        #500;

        $finish;

    end

endmodule
