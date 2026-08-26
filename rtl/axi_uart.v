`timescale 1ns/1ps

module axi_uart #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire        clk,
    input  wire        resetn,

    // AXI-Lite Write Address Channel
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,  // master to slave 
    output wire        s_axi_awready,  // slave to master like a handshake 

    // AXI-Lite Write Data Channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,    //Without WSTRB, the slave might overwrite the entire 32-bit word
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,

    // AXI-Lite Write Response Channel
    output reg [1:0]   s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,

    // AXI-Lite Read Address Channel
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,

    // AXI-Lite Read Data Channel
    output reg [31:0]  s_axi_rdata,
    output reg [1:0]   s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,

    // UART
    input wire rx,
    output wire tx,
    output wire tx_busy
);  //s_axi signals are between the interconnect and individual modules of tx and rx 

    // AXI write storage
    reg aw_pending;  //after getting adress wait and transmit later so pending like waiting to write the adress 
    reg w_pending;   //wait to write the data in uart transmitter if it is busy 

    reg [31:0] awaddr_reg;  //temporarily store information received from the AXI master (CPU). 
    reg [31:0] wdata_reg;
    reg [3:0]  wstrb_reg;

    // UART transmit control
    reg [7:0] tx_data;
    reg       tx_start;
    reg       tx_pending;

    // UART receive control
    wire [7:0] rx_data;
    wire       rx_valid;
    reg [7:0] rx_data_reg;
    reg       rx_data_valid;

   // AXI READY signals
    assign s_axi_awready = !aw_pending && !s_axi_bvalid;  //backpressure : if not 2nd byte may overwrites 1st and can be lost 
 //already have an address/data and not waiting for a response,ready to accept a new one.
    assign s_axi_wready  = !w_pending && !s_axi_bvalid;

    assign s_axi_arready = !s_axi_rvalid;

   // UART transmitter
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_tx_inst (
        .clk(clk),
        .resetn(resetn),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx(tx),
        .tx_busy(tx_busy)
    );

// UART receiver
uart_rx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) uart_rx_inst (
    .clk(clk),
    .resetn(resetn),
    .rx(rx),
    .rx_data(rx_data),
    .rx_valid(rx_valid)
);

//axi interconnect
    always @(posedge clk) begin
        if (!resetn) begin

            aw_pending  <= 1'b0;
            w_pending   <= 1'b0;

            awaddr_reg  <= 32'd0;
            wdata_reg   <= 32'd0;
            wstrb_reg   <= 4'd0;

            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;

            tx_data     <= 8'd0;
            tx_start    <= 1'b0;
            tx_pending  <= 1'b0;
    
            rx_data_reg   <= 8'd0;
            rx_data_valid <= 1'b0;

            s_axi_rdata  <= 32'd0;
            s_axi_rresp  <= 2'b00;
            s_axi_rvalid <= 1'b0;

        end

        else begin

            // tx_start is a one-clock pulse
            tx_start <= 1'b0;
            
            // Capture received UART byte
            if (rx_valid) begin
            rx_data_reg   <= rx_data;
            rx_data_valid <= 1'b1;
            end
            
            /// AXI signal debug
        //$display("DUT AXI: AWV=%b AWR=%b WV=%b WR=%b", s_axi_awvalid, s_axi_awready, s_axi_wvalid, s_axi_wready);
                                                                                    
        // Capture AXI write address
        if (s_axi_awvalid && s_axi_awready) begin
        $display("DUT: AW HANDSHAKE addr=%h", s_axi_awaddr);
        awaddr_reg <= s_axi_awaddr;
        aw_pending <= 1'b1;
        end

        // Capture AXI write data
        if (s_axi_wvalid && s_axi_wready) begin
        $display("DUT: W HANDSHAKE data=%h", s_axi_wdata);
        wdata_reg <= s_axi_wdata;
        wstrb_reg <= s_axi_wstrb;
        w_pending <= 1'b1;
        end

        //$display("DUT DEBUG: aw_pending=%b w_pending=%b tx_pending=%b tx_busy=%b bvalid=%b", aw_pending, w_pending, tx_pending, tx_busy, s_axi_bvalid);

            // Once address + data are available, perform write
            if (aw_pending && w_pending && !tx_pending && !tx_busy && !s_axi_bvalid) begin
            //address and data, UART isn't currently waiting to start, UART isn't busy, and don't already have a response pending.
            // Address 0x00 = TX_DATA register
            if (awaddr_reg[3:0] == 4'h0) begin
              if (wstrb_reg[0]) begin
                tx_data    <= wdata_reg[7:0];
                tx_pending <= 1'b1;
              end
            end

                // Write response = OKAY
                s_axi_bresp  <= 2'b00;  //00 means okay
                s_axi_bvalid <= 1'b1;
                aw_pending <= 1'b0;
                w_pending  <= 1'b0;
            end

            // Start UART transmission one cycle after
            // tx_data has been loaded
            if (tx_pending && !tx_busy) begin
                tx_start   <= 1'b1;
                tx_pending <= 1'b0;
            end

            // AXI master accepts write response
            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end

            // AXI read address handshake
            if (s_axi_arvalid && s_axi_arready) begin

                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00;

                // Select register
                case (s_axi_araddr[3:0])

                    4'h0: begin
                        // TX_DATA register : cpu writes to get something
                        s_axi_rdata <= {24'd0, tx_data};
                    end

                    4'h4: begin
                        // RX_DATA register : cpu reads here to get a character that uart received 
                        s_axi_rdata <= {24'd0, rx_data_reg};
                        rx_data_valid <= 1'b0;
                    end

                    4'h8: begin
                        // STATUS register : does tx busy; because cpu doesn't automatically know what the uart is doing
                        s_axi_rdata <= {30'd0, tx_busy, rx_data_valid};
                    end

                    default: begin
                        s_axi_rdata <= 32'd0;
                        s_axi_rresp <= 2'b10;
                    end

                endcase
            end

            // AXI master accepts read response
            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end

        end   
        
    end       
endmodule
