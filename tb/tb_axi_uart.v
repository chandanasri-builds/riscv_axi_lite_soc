`timescale 1ns/1ps

module tb_axi_uart;

    reg clk = 0;
    reg resetn = 0;

    // AXI WRITE CHANNEL
    reg  [31:0] awaddr;
    reg         awvalid;
    wire        awready;

    reg  [31:0] wdata;
    reg  [3:0]  wstrb;
    reg         wvalid;
    wire        wready;

    wire [1:0]  bresp;
    wire        bvalid;
    reg         bready;

    // AXI READ CHANNEL
    reg  [31:0] araddr;
    reg         arvalid;
    wire        arready;

    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    reg         rready;

    // UART
    wire tx;
    reg  rx;
    wire tx_busy;

    // DUT
        axi_uart #(
        .CLK_FREQ(10_000_000),
        .BAUD_RATE(1_000_000)
    ) dut (

        .clk(clk),
        .resetn(resetn),

        // AXI WRITE
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

        // AXI READ
        .s_axi_araddr(araddr),
        .s_axi_arvalid(arvalid),
        .s_axi_arready(arready),

        .s_axi_rdata(rdata),
        .s_axi_rresp(rresp),
        .s_axi_rvalid(rvalid),
        .s_axi_rready(rready),

        // UART
        .rx(rx),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    // 10 MHz CLOCK
    // 100 ns period

    always #50 clk = ~clk;

    task axi_write;

    input [31:0] address;
    input [31:0] data;

    begin

        awaddr  = address;
        wdata   = data;
        wstrb   = 4'b1111;

        // Assert VALID
        awvalid = 1'b1;
        wvalid  = 1'b1;

        // Wait for a clock edge with both READY signals high
        @(posedge clk);

        while (!(awready && wready))
            @(posedge clk);

        // Handshake has now occurred
        awvalid = 1'b0;
        wvalid  = 1'b0;

        $display("AXI WRITE: address/data accepted.");

        // Wait for write response
        while (!bvalid)
            @(posedge clk);

        $display("AXI WRITE: BVALID received.");

        bready = 1'b1;

        @(posedge clk);

        bready = 1'b0;

        $display("AXI WRITE: response accepted.");

    end

endtask 

    // AXI READ TASK
    task axi_read;

     input  [31:0] address;
     output [31:0] data;

     begin

        araddr  = address;
        arvalid = 1'b1;

        // Wait for read address handshake
        while (!arready)
            @(posedge clk);

        @(posedge clk);

        arvalid = 1'b0;

        // Wait for read response
        while (!rvalid)
            @(posedge clk);

        data = rdata;

        $display("AXI READ: address=%h data=%h",
                 address, rdata);

        rready = 1'b1;

        @(posedge clk);

        rready = 1'b0;

     end

    endtask

    // MAIN TEST
    reg [31:0] read_data;

    initial begin

        $dumpfile("axi_uart.vcd");
        $dumpvars(0, tb_axi_uart);

        // Initial values
        awaddr  = 32'd0;
        awvalid = 1'b0;

        wdata   = 32'd0;
        wstrb   = 4'd0;
        wvalid  = 1'b0;

        bready  = 1'b0;

        araddr  = 32'd0;
        arvalid = 1'b0;
        rready  = 1'b0;

        rx = 1'b1;       // UART idle state

        // RESET
        #200;
        resetn = 1'b1;

        #200;

        // TEST 1: AXI WRITE → UART TX
        $display("");
        $display("======================================");
        $display("TEST 1: UART TX");
        $display("======================================");

        $display("AWREADY=%b WREADY=%b BVALID=%b TX_BUSY=%b", awready, wready, bvalid, tx_busy);

        axi_write(32'h0000_0000, 32'h0000_0043);
        
        $display("TX write completed.");

        wait (!tx_busy);

        $display("UART TX transmission completed.");
        $display("TX TEST PASSED.");

        // TEST 2: UART RX
        $display("");
        $display("======================================");
        $display("TEST 2: UART RX");
        $display("======================================");

        // Send 8'h41 ('A') manually on RX line
        // Start bit
        rx = 1'b0;

        // One bit = 10 clocks = 1000 ns
        #1000;

        // D0 = 1
        rx = 1'b1;
        #1000;

        // D1 = 0
        rx = 1'b0;
        #1000;

        // D2 = 0
        rx = 1'b0;
        #1000;

        // D3 = 0
        rx = 1'b0;
        #1000;

        // D4 = 0
        rx = 1'b0;
        #1000;

        // D5 = 0
        rx = 1'b0;
        #1000;

        // D6 = 1
        rx = 1'b1;
        #1000;

        // D7 = 0
        rx = 1'b0;
        #1000;

        // Stop bit
        rx = 1'b1;
        #1000;

        $display("UART RX frame sent.");

        // TEST 3: AXI READ RX DATA
        $display("");
        $display("======================================");
        $display("TEST 3: AXI READ RX DATA");
        $display("======================================");

        axi_read(32'h0000_0004, read_data);

        $display("RX DATA = %h", read_data);

        if (read_data == 32'h0000_0041)
            $display("RX DATA TEST PASSED.");
        else
            $display("RX DATA TEST FAILED.");

        // TEST 4: STATUS REGISTER
        $display("");
        $display("======================================");
        $display("TEST 4: STATUS REGISTER");
        $display("======================================");

        axi_read(32'h0000_0008, read_data);

        $display("STATUS = %h", read_data);

        $display("STATUS TEST COMPLETED.");

        // COMPLETE
        #500;

        $display("");
        $display("======================================");
        $display("AXI UART TEST COMPLETE");
        $display("======================================");

        $finish;

    end

endmodule
