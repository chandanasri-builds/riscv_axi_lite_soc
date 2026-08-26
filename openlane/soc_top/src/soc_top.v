`timescale 1ns/1ps

module soc_top #(
    parameter CLK_FREQ  = 10_000_000,
    parameter BAUD_RATE = 1_000_000
)(
    input  wire clk,
    input wire resetn,

    // External UART pins
    input  wire uart_rx,
    output wire uart_tx,
    output wire uart_tx_busy
);

    // PicoRV32 AXI-Lite master signals
    wire        cpu_awvalid;
    wire        cpu_awready;
    wire [31:0] cpu_awaddr;

    wire        cpu_wvalid;
    wire        cpu_wready;
    wire [31:0] cpu_wdata;
    wire [3:0]  cpu_wstrb;

    wire        cpu_bvalid;
    wire        cpu_bready;
    wire [1:0]  cpu_bresp;

    wire        cpu_arvalid;
    wire        cpu_arready;
    wire [31:0] cpu_araddr;

    wire        cpu_rvalid;
    wire        cpu_rready;
    wire [31:0] cpu_rdata;
    wire [1:0]  cpu_rresp;

    // RAM side
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

    // UART side
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

    // PicoRV32 AXI-Lite CPU
    picorv32_axi #(
        .PROGADDR_RESET(32'h0000_0000)
    ) cpu (
        .clk(clk),
        .resetn(resetn),
        .trap(),

        // AXI write address
        .mem_axi_awvalid(cpu_awvalid),
        .mem_axi_awready(cpu_awready),
        .mem_axi_awaddr(cpu_awaddr),
        .mem_axi_awprot(),

        // AXI write data
        .mem_axi_wvalid(cpu_wvalid),
        .mem_axi_wready(cpu_wready),
        .mem_axi_wdata(cpu_wdata),
        .mem_axi_wstrb(cpu_wstrb),

        // AXI write response
        .mem_axi_bvalid(cpu_bvalid),
        .mem_axi_bready(cpu_bready),

        // AXI read address
        .mem_axi_arvalid(cpu_arvalid),
        .mem_axi_arready(cpu_arready),
        .mem_axi_araddr(cpu_araddr),
        .mem_axi_arprot(),

        // AXI read data
        .mem_axi_rvalid(cpu_rvalid),
        .mem_axi_rready(cpu_rready),
        .mem_axi_rdata(cpu_rdata),

        // PCPI unused
        .pcpi_valid(),
        .pcpi_insn(),
        .pcpi_rs1(),
        .pcpi_rs2(),
        .pcpi_wr(1'b0),
        .pcpi_rd(32'd0),
        .pcpi_wait(1'b0),
        .pcpi_ready(1'b0),

        // IRQ unused
        .irq(32'd0),
        .eoi(),

        // Trace unused
        .trace_valid(),
        .trace_data()
    );

    // AXI INTERCONNECT
    axi_interconnect axi_ic (
        .clk(clk),
        .resetn(resetn),

        // MASTER SIDE : PicoRV32
        .m_awaddr(cpu_awaddr),
        .m_awvalid(cpu_awvalid),
        .m_awready(cpu_awready),

        .m_wdata(cpu_wdata),
        .m_wstrb(cpu_wstrb),
        .m_wvalid(cpu_wvalid),
        .m_wready(cpu_wready),

        .m_bresp(cpu_bresp),
        .m_bvalid(cpu_bvalid),
        .m_bready(cpu_bready),

        .m_araddr(cpu_araddr),
        .m_arvalid(cpu_arvalid),
        .m_arready(cpu_arready),

        .m_rdata(cpu_rdata),
        .m_rresp(cpu_rresp),
        .m_rvalid(cpu_rvalid),
        .m_rready(cpu_rready),

        // RAM
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

        //uart
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
        
        .uart_araddr(uart_araddr),
        .uart_arvalid(uart_arvalid),
        .uart_arready(uart_arready),

        .uart_rdata(uart_rdata),
        .uart_rresp(uart_rresp),
        .uart_rvalid(uart_rvalid),
        .uart_rready(uart_rready)
    );

    // AXI RAM
    axi_ram ram (
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

    // AXI UART
    axi_uart #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart (
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

        .s_axi_araddr(uart_araddr),
        .s_axi_arvalid(uart_arvalid),
        .s_axi_arready(uart_arready),

        .s_axi_rdata(uart_rdata),
        .s_axi_rresp(uart_rresp),
        .s_axi_rvalid(uart_rvalid),
        .s_axi_rready(uart_rready),

        .rx(uart_rx),
        .tx(uart_tx),
        .tx_busy(uart_tx_busy)
    );

endmodule
