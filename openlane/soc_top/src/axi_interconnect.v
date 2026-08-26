`timescale 1ns/1ps

module axi_interconnect (
    input wire clk,
    input wire resetn,

    // MASTER SIDE - PicoRV32
    // WRITE ADDRESS
    input  wire [31:0] m_awaddr,
    input  wire        m_awvalid,
    output wire        m_awready,

    // WRITE DATA
    input  wire [31:0] m_wdata,
    input  wire [3:0]  m_wstrb,
    input  wire        m_wvalid,
    output wire        m_wready,

    // WRITE RESPONSE
    output wire [1:0]  m_bresp,
    output wire        m_bvalid,
    input  wire        m_bready,

    // READ ADDRESS
    input  wire [31:0] m_araddr,
    input  wire        m_arvalid,
    output wire        m_arready,

    // READ DATA
    output wire [31:0] m_rdata,
    output wire [1:0]  m_rresp,
    output wire        m_rvalid,
    input  wire        m_rready,

    // RAM SIDE
    // WRITE ADDRESS
    output wire [31:0] ram_awaddr,
    output wire        ram_awvalid,
    input  wire        ram_awready,

    // WRITE DATA
    output wire [31:0] ram_wdata,
    output wire [3:0]  ram_wstrb,
    output wire        ram_wvalid,
    input  wire        ram_wready,

    // WRITE RESPONSE
    input  wire [1:0]  ram_bresp,
    input  wire        ram_bvalid,
    output wire        ram_bready,

    // READ ADDRESS
    output wire [31:0] ram_araddr,
    output wire        ram_arvalid,
    input  wire        ram_arready,

    // READ DATA
    input  wire [31:0] ram_rdata,
    input  wire [1:0]  ram_rresp,
    input  wire        ram_rvalid,
    output wire        ram_rready,

    // UART SIDE
    // WRITE ADDRESS
    output wire [31:0] uart_awaddr,
    output wire        uart_awvalid,
    input  wire        uart_awready,

    // WRITE DATA
    output wire [31:0] uart_wdata,
    output wire [3:0]  uart_wstrb,
    output wire        uart_wvalid,
    input  wire        uart_wready,

    // WRITE RESPONSE
    input  wire [1:0]  uart_bresp,
    input  wire        uart_bvalid,
    output wire        uart_bready,

    // READ ADDRESS
    output wire [31:0] uart_araddr,
    output wire        uart_arvalid,
    input  wire        uart_arready,

    // READ DATA
    input  wire [31:0] uart_rdata,
    input  wire [1:0]  uart_rresp,
    input  wire        uart_rvalid,
    output wire        uart_rready
);

    // ADDRESS DECODING
    wire addr_is_ram;
    wire addr_is_uart;
    wire read_addr_is_ram;
    wire read_addr_is_uart;

    assign addr_is_ram  = (m_awaddr[31:28] == 4'h0); // RAM region: 0x0000_0000 - 0x0FFF_FFFF : 0xxx_xxxx
    assign addr_is_uart = (m_awaddr[31:28] == 4'h1); // UART region: 0x1000_0000 - 0x1FFF_FFFF : 1xxx_xxxx
    assign read_addr_is_ram  = (m_araddr[31:28] == 4'h0);
    assign read_addr_is_uart = (m_araddr[31:28] == 4'h1);

    // WRITE ADDRESS CHANNEL
    assign ram_awaddr  = m_awaddr;
    assign uart_awaddr = m_awaddr;
    assign ram_awvalid = m_awvalid && addr_is_ram;
    assign uart_awvalid = m_awvalid && addr_is_uart;

    // Master sees READY from whichever peripheral is selected
    assign m_awready = (addr_is_ram  && ram_awready) || (addr_is_uart && uart_awready);

    // WRITE DATA CHANNEL
    assign ram_wdata = m_wdata;
    assign ram_wstrb = m_wstrb;
    assign uart_wdata = m_wdata;
    assign uart_wstrb = m_wstrb;

    assign ram_wvalid = m_wvalid && addr_is_ram;
    assign uart_wvalid = m_wvalid && addr_is_uart;
    assign m_wready = (addr_is_ram  && ram_wready) || (addr_is_uart && uart_wready);

    // WRITE RESPONSE CHANNEL
    // Only one peripheral should have a response for our
    // one-transaction-at-a-time design.
    assign m_bvalid = ram_bvalid || uart_bvalid;
    assign m_bresp = uart_bvalid ? uart_bresp : ram_bresp;
    assign ram_bready = m_bready && ram_bvalid;
    assign uart_bready = m_bready && uart_bvalid;

    // READ ADDRESS CHANNEL
    assign ram_araddr  = m_araddr;
    assign uart_araddr = m_araddr;
    assign ram_arvalid = m_arvalid && read_addr_is_ram;
    assign uart_arvalid = m_arvalid && read_addr_is_uart;

    // Return READY from selected peripheral
    assign m_arready = (read_addr_is_ram  && ram_arready) || (read_addr_is_uart && uart_arready);

    // READ RESPONSE CHANNEL
    // Select RAM response
    // or UART response depending on which one is valid.
    assign m_rdata = uart_rvalid ? uart_rdata : ram_rdata;
    assign m_rresp = uart_rvalid ? uart_rresp : ram_rresp;
    assign m_rvalid = ram_rvalid || uart_rvalid;

    assign ram_rready = m_rready && ram_rvalid;
    assign uart_rready = m_rready && uart_rvalid;

endmodule
