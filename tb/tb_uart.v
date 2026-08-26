`timescale 1ns/1ps

module tb_uart;

    reg clk = 0;
    reg resetn = 0;

    // -----------------------------
    // AXI-Lite Write Address
    // -----------------------------
    reg  [31:0] awaddr;
    reg         awvalid;
    wire        awready;

    // -----------------------------
    // AXI-Lite Write Data
    // -----------------------------
    reg  [31:0] wdata;
    reg  [3:0]  wstrb;
    reg         wvalid;
    wire        wready;

    // -----------------------------
    // AXI-Lite Write Response
    // -----------------------------
    wire [1:0]  bresp;
    wire        bvalid;
    reg         bready;

    // -----------------------------
    // UART
    // -----------------------------
    wire tx;
    wire tx_busy;

    // -----------------------------
    // Clock: 50 MHz
    // -----------------------------
    always #10 clk = ~clk;

    // -----------------------------
    // DUT
    // -----------------------------
    axi_uart #(
        .CLK_FREQ(50_000_000),
        .BAUD_RATE(115200)
    ) dut (
        .clk(clk),
        .resetn(resetn),

        .s_axi_awaddr(awaddr),
        .s_axi_awvalid(awvalid),
        .s_axi_awready(awready),

        .s_axi_wdata(wdata),
        .s_axi_wstrb(wstrb),
        .s_axi_wvalid(wvalid),
        .s_axi_wready(wready),

        .s_axi_bresp(bresp),
        .s_axi_bvalid(bvalid),
        .s_axi_bready(bready),

        .tx(tx),
        .tx_busy(tx_busy)
    );

    // -----------------------------
    // AXI WRITE TASK
    // -----------------------------
    task axi_write;
        input [31:0] address;
        input [31:0] data;

        begin

            // Put address and data on bus
            awaddr  = address;
            awvalid = 1'b1;

            wdata   = data;
            wstrb   = 4'b1111;
            wvalid  = 1'b1;

            // Wait until address and data are accepted
            wait (awready && wready);

            @(posedge clk);

            awvalid = 1'b0;
            wvalid  = 1'b0;

            // Wait for write response
            wait (bvalid);

            bready = 1'b1;

            @(posedge clk);

            bready = 1'b0;

        end
    endtask

    // -----------------------------
    // TEST
    // -----------------------------
    initial begin

        $dumpfile("uart_axi.vcd");
        $dumpvars(0, tb_uart);

        // Initial values
        awaddr  = 32'd0;
        awvalid = 1'b0;

        wdata   = 32'd0;
        wstrb   = 4'b0000;
        wvalid  = 1'b0;

        bready  = 1'b0;

        // Reset
        #100;
        resetn = 1'b1;

        // Give DUT time after reset
        #100;

        $display("Starting AXI UART test...");

        // Write ASCII 'C' to TX register
        axi_write(32'h00000000, 32'h00000043);

        $display("AXI write completed.");

        // Wait until UART transmission completes
        wait (!tx_busy);

        #100;

        $display("UART transmission completed.");
        $finish;

    end

endmodule
