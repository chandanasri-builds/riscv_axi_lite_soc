`timescale 1ns/1ps

module tb_axi;

    reg clk = 0;
    reg resetn = 0;

    // MASTER SIDE
    reg [31:0] awaddr;
    reg        awvalid;
    wire       awready;

    reg [31:0] wdata;
    reg [3:0]  wstrb;
    reg        wvalid;
    wire       wready;

    wire [1:0] bresp;
    wire       bvalid;
    reg        bready;

    reg [31:0] araddr;
    reg        arvalid;
    wire       arready;

    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    reg         rready;

    // RAM SIDE
    wire [31:0] ram_awaddr;
    wire        ram_awvalid;
    wire        ram_awready;

    wire [31:0] ram_wdata;
    wire [3:0]  ram_wstrb;
    wire        ram_wvalid;
    wire        ram_wready;

    wire [1:0]  ram_bresp;
    wire        ram_bvalid;
    wire        ram_bready;

    wire [31:0] ram_araddr;
    wire        ram_arvalid;
    wire        ram_arready;

    wire [31:0] ram_rdata;
    wire [1:0]  ram_rresp;
    wire        ram_rvalid;
    wire        ram_rready;

    // UART SIDE
    wire [31:0] uart_awaddr;
    wire        uart_awvalid;
    wire        uart_awready;

    wire [31:0] uart_wdata;
    wire [3:0]  uart_wstrb;
    wire        uart_wvalid;
    wire        uart_wready;

    wire [1:0]  uart_bresp;
    wire        uart_bvalid;
    wire        uart_bready;

    wire [31:0] uart_araddr;
    wire        uart_arvalid;
    wire        uart_arready;

    wire [31:0] uart_rdata;
    wire [1:0]  uart_rresp;
    wire        uart_rvalid;
    wire        uart_rready;

    // UART PINS
    wire tx;
    reg  rx;
    wire tx_busy;

    reg [31:0] read_data;

    // CLOCK
    // 50 MHz = 20 ns period
    always #50 clk = ~clk;

    // AXI INTERCONNECT
    axi_interconnect dut_interconnect (
        .clk(clk),
        .resetn(resetn),

        //MASTER
        .m_awaddr(awaddr),
        .m_awvalid(awvalid),
        .m_awready(awready),

        .m_wdata(wdata),
        .m_wstrb(wstrb),
        .m_wvalid(wvalid),
        .m_wready(wready),

        .m_bresp(bresp),
        .m_bvalid(bvalid),
        .m_bready(bready),

        .m_araddr(araddr),
        .m_arvalid(arvalid),
        .m_arready(arready),

        .m_rdata(rdata),
        .m_rresp(rresp),
        .m_rvalid(rvalid),
        .m_rready(rready),

        //RAM 
        .ram_awaddr(ram_awaddr),
        .ram_awvalid(ram_awvalid),
        .ram_awready(ram_awready),

        .ram_wdata(ram_wdata),
        .ram_wstrb(ram_wstrb),
        .ram_wvalid(ram_wvalid),
        .ram_wready(ram_wready),

        .ram_bresp(ram_bresp),
        .ram_bvalid(ram_bvalid),
        .ram_bready(ram_bready),

        .ram_araddr(ram_araddr),
        .ram_arvalid(ram_arvalid),
        .ram_arready(ram_arready),

        .ram_rdata(ram_rdata),
        .ram_rresp(ram_rresp),
        .ram_rvalid(ram_rvalid),
        .ram_rready(ram_rready),

        //UART
        .uart_awaddr(uart_awaddr),
        .uart_awvalid(uart_awvalid),
        .uart_awready(uart_awready),

        .uart_wdata(uart_wdata),
        .uart_wstrb(uart_wstrb),
        .uart_wvalid(uart_wvalid),
        .uart_wready(uart_wready),

        .uart_bresp(uart_bresp),
        .uart_bvalid(uart_bvalid),
        .uart_bready(uart_bready),

        // NEW: UART READ
        .uart_araddr(uart_araddr),
        .uart_arvalid(uart_arvalid),
        .uart_arready(uart_arready),

        .uart_rdata(uart_rdata),
        .uart_rresp(uart_rresp),
        .uart_rvalid(uart_rvalid),
        .uart_rready(uart_rready)
    );

    // AXI RAM
    axi_ram #(
        .ADDR_WIDTH(12), .DATA_WIDTH(32)
        ) ram_inst (
        .clk(clk),
        .resetn(resetn),

        .s_axi_awaddr(ram_awaddr),
        .s_axi_awvalid(ram_awvalid),
        .s_axi_awready(ram_awready),

        .s_axi_wdata(ram_wdata),
        .s_axi_wstrb(ram_wstrb),
        .s_axi_wvalid(ram_wvalid),
        .s_axi_wready(ram_wready),

        .s_axi_bresp(ram_bresp),
        .s_axi_bvalid(ram_bvalid),
        .s_axi_bready(ram_bready),

        .s_axi_araddr(ram_araddr),
        .s_axi_arvalid(ram_arvalid),
        .s_axi_arready(ram_arready),

        .s_axi_rdata(ram_rdata),
        .s_axi_rresp(ram_rresp),
        .s_axi_rvalid(ram_rvalid),
        .s_axi_rready(ram_rready)
    );

    // AXI UART : Use smaller clock/baud values for faster simulation.
    axi_uart #(
        .CLK_FREQ(10_000_000), .BAUD_RATE(1_000_000)
    ) uart_inst (
        .clk(clk),
        .resetn(resetn),

        .s_axi_awaddr(uart_awaddr),
        .s_axi_awvalid(uart_awvalid),
        .s_axi_awready(uart_awready),

        .s_axi_wdata(uart_wdata),
        .s_axi_wstrb(uart_wstrb),
        .s_axi_wvalid(uart_wvalid),
        .s_axi_wready(uart_wready),

        .s_axi_bresp(uart_bresp),
        .s_axi_bvalid(uart_bvalid),
        .s_axi_bready(uart_bready),

        //READ
        .s_axi_araddr(uart_araddr),
        .s_axi_arvalid(uart_arvalid),
        .s_axi_arready(uart_arready),

        .s_axi_rdata(uart_rdata),
        .s_axi_rresp(uart_rresp),
        .s_axi_rvalid(uart_rvalid),
        .s_axi_rready(uart_rready),

        //UART
        .rx(rx),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    // AXI WRITE TASK
    task axi_write;
        input [31:0] address;
        input [31:0] data;
        begin
            awaddr  = address;
            awvalid = 1'b1;
            wdata   = data;
            wstrb   = 4'b1111;
            wvalid  = 1'b1;

            $display("DEBUG: AWREADY=%b WREADY=%b", awready, wready);
            // Wait until both channels are ready
            while (!(awready && wready))
                @(posedge clk);
            $display("DEBUG: AW/W READY received.");

            // Keep VALID asserted through the handshake edge
            @(posedge clk);
            #1;
            awvalid = 1'b0;
            wvalid  = 1'b0;
            $display("DEBUG: AW/W handshake completed.");

            // Wait for BVALID
            while (!bvalid)
                @(posedge clk);
            $display("DEBUG: BVALID received. BRESP=%b", bresp);

            // Accept response
            bready = 1'b1;
            @(posedge clk);
            #1;
            bready = 1'b0;
            $display("DEBUG: Write response accepted.");

        end
    endtask

    // AXI READ TASK
    task axi_read;
     input  [31:0] address;
     output [31:0] data;
     begin

        araddr  = address;
        arvalid = 1'b1;

        $display("DEBUG: ARREADY=%b", arready);

        while (!arready)
            @(posedge clk);

        $display("DEBUG: ARREADY received.");

        @(posedge clk);

        #1;
        arvalid = 1'b0;

        while (!rvalid)
            @(posedge clk);

        data = rdata;

        $display("DEBUG: RVALID received.");
        $display("READ ADDRESS = %h", address);
        $display("READ DATA    = %h", data);
        $display("RRESP        = %b", rresp);

        rready = 1'b1;

        @(posedge clk);

        #1;
        rready = 1'b0;

     end
    endtask

    // MAIN TEST
    initial begin
        $dumpfile("axi_interconnect.vcd");
        $dumpvars(0, tb_axi);

        // INITIAL VALUES
        awaddr  = 32'd0;
        awvalid = 1'b0;

        wdata   = 32'd0;
        wstrb   = 4'd0;
        wvalid  = 1'b0;

        bready  = 1'b0;

        araddr  = 32'd0;
        arvalid = 1'b0;
        rready  = 1'b0;

        // UART RX idle = 1
        rx = 1'b1;

        // RESET
        $display("======================================");
        $display("RESET");
        $display("======================================");
        #100;

        resetn = 1'b1;
        #100;

        // TEST 1: RAM WRITE
        $display("======================================");
        $display("TEST 1: RAM WRITE");
        $display("======================================");
        axi_write(32'h0000_0004, 32'hDEAD_BEEF);
        $display("RAM WRITE COMPLETED.");

        // TEST 2: RAM READ
        $display("======================================");
        $display("TEST 2: RAM READ");
        $display("======================================");
        axi_read(32'h00000004, read_data);
        if (read_data == 32'hDEADBEEF)
        axi_read(32'h00000004, read_data);

        if (read_data == 32'hDEAD_BEEF)
            $display("RAM READ PASSED.");
        else
            $display("RAM READ FAILED. Expected DEADBEEF.");
        // TEST 3: UART TX WRITE
        $display("======================================");
        $display("TEST 3: UART TX WRITE");
        $display("======================================");
        axi_write(32'h1000_0000, 32'h0000_0043);
        $display("UART WRITE COMPLETED.");

        // Wait until UART finishes transmitting
        wait (!tx_busy);
        $display("UART TRANSMISSION COMPLETED.");
        $display("UART TX TEST PASSED.");

        // TEST 4: UART STATUS READ
        $display("======================================");
        $display("TEST 4: UART STATUS READ");
        $display("======================================");
        axi_read(32'h1000_0008, read_data);
        $display("UART STATUS READ COMPLETED.");

        // TEST 5: UART RX
        $display("======================================");
        $display("TEST 5: UART RX");
        $display("======================================");
        // Send character 'A' = 8'h41 ; Data  = 1 0 0 0 0 0 1 0
        // Baud = 1 MHz , Bit period = 1 us

        // START BIT
        rx = 1'b0;
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

        // STOP BIT
        rx = 1'b1;
        #1000;

        $display("UART RX FRAME SENT.");

        // TEST 6: UART RX DATA READ
        $display("======================================");
        $display("TEST 6: UART RX DATA READ");
        $display("======================================");
        axi_read(32'h10000004, read_data);

        if (read_data == 32'h00000041)
            $display("UART RX DATA TEST PASSED.");
        else
            $display("UART RX DATA TEST FAILED. Expected 00000041.");
        
        #500;
        $display("======================================");
        $display("AXI INTERCONNECT TEST COMPLETE");
        $display("======================================");
        $finish;

    end
endmodule
