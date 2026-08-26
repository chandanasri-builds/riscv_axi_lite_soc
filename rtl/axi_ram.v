`timescale 1ns/1ps

module axi_ram #(
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 32
)(
    input  wire        clk,
    input  wire        resetn,

    // AXI Write Address
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,

    // AXI Write Data
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,

    // AXI Write Response
    output reg [1:0]   s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,

    // AXI Read Address
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,

    // AXI Read Data
    output reg [31:0]  s_axi_rdata,
    output reg [1:0]   s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready
);

    reg [31:0] mem [0:(1<<(ADDR_WIDTH-2))-1];   //0:(2^addr_width-1)-1

    initial begin
    $readmemh("sw/uart_test_words.hex", mem);
    end

    reg        aw_pending;
    reg        w_pending;

    reg [31:0] awaddr_reg;
    reg [31:0] wdata_reg;
    reg [3:0]  wstrb_reg;  //axi address are ram addresses, ram stores 32 bits so 4 bytes

    assign s_axi_awready = !aw_pending && !s_axi_bvalid;
    assign s_axi_wready  = !w_pending  && !s_axi_bvalid;

    assign s_axi_arready = !s_axi_rvalid;

    integer i;

    always @(posedge clk) begin

        if (!resetn) begin

            aw_pending  <= 1'b0;
            w_pending   <= 1'b0;

            awaddr_reg  <= 32'd0;
            wdata_reg   <= 32'd0;
            wstrb_reg   <= 4'd0;

            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;

            s_axi_rvalid <= 1'b0;
            s_axi_rdata  <= 32'd0;
            s_axi_rresp  <= 2'b00;

        end

        else begin

            // Capture write address
            if (s_axi_awvalid && s_axi_awready) begin
                awaddr_reg <= s_axi_awaddr;
                aw_pending <= 1'b1;
            end

           // Capture write data
            if (s_axi_wvalid && s_axi_wready) begin
                wdata_reg <= s_axi_wdata;
                wstrb_reg <= s_axi_wstrb;
                w_pending <= 1'b1;
            end

            // Perform write
            if (aw_pending && w_pending && !s_axi_bvalid) begin

                if (wstrb_reg[0])
                    mem[awaddr_reg[ADDR_WIDTH-1:2]][7:0] <= wdata_reg[7:0];
                //ignore the bottom two address bits, considering them as the byte offset
                if (wstrb_reg[1])
                    mem[awaddr_reg[ADDR_WIDTH-1:2]][15:8] <= wdata_reg[15:8];
                if (wstrb_reg[2])
                    mem[awaddr_reg[ADDR_WIDTH-1:2]][23:16] <= wdata_reg[23:16];
                if (wstrb_reg[3])
                    mem[awaddr_reg[ADDR_WIDTH-1:2]][31:24] <= wdata_reg[31:24];

                aw_pending <= 1'b0;
                w_pending  <= 1'b0;
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
            end

            // Write response accepted
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;

            // Read
            if (s_axi_arvalid && s_axi_arready) begin

                s_axi_rdata <= mem[s_axi_araddr[ADDR_WIDTH-1:2]];
                s_axi_rresp <= 2'b00;
                s_axi_rvalid <= 1'b1;

            end

            // Read response accepted
            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;

        end
    end

endmodule
