`timescale 1ns/1ps

module tb_axi_ram;

    reg clk = 0;
    reg resetn = 0;

    // Write address
    reg [31:0] awaddr;
    reg        awvalid;
    wire       awready;

    // Write data
    reg [31:0] wdata;
    reg [3:0]  wstrb;
    reg        wvalid;
    wire       wready;

    // Write response
    wire [1:0] bresp;
    wire       bvalid;
    reg        bready;

    // Read address
    reg [31:0] araddr;
    reg        arvalid;
    wire       arready;

    // Read response
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    reg         rready;

    always #10 clk = ~clk;

    axi_ram #(
        .ADDR_WIDTH(12),
        .DATA_WIDTH(32)
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

        .s_axi_araddr(araddr),
        .s_axi_arvalid(arvalid),
        .s_axi_arready(arready),

        .s_axi_rdata(rdata),
        .s_axi_rresp(rresp),
        .s_axi_rvalid(rvalid),
        .s_axi_rready(rready)
    );

    task axi_write;
        input [31:0] address;
        input [31:0] data;

        begin

            awaddr  = address;
            awvalid = 1'b1;

            wdata   = data;
            wstrb   = 4'b1111;
            wvalid  = 1'b1;

            wait (awready && wready);

            @(posedge clk);

            awvalid = 1'b0;
            wvalid  = 1'b0;

            wait (bvalid);

            bready = 1'b1;

            @(posedge clk);

            bready = 1'b0;

        end
    endtask

    task axi_read;
        input [31:0] address;

        begin

            araddr  = address;
            arvalid = 1'b1;

            wait (arready);

            @(posedge clk);

            arvalid = 1'b0;

            wait (rvalid);

            $display("READ DATA = %h", rdata);

            rready = 1'b1;

            @(posedge clk);

            rready = 1'b0;

        end
    endtask

    initial begin

        $dumpfile("axi_ram.vcd");
        $dumpvars(0, tb_axi_ram);

        awaddr  = 0;
        awvalid = 0;

        wdata   = 0;
        wstrb   = 0;
        wvalid  = 0;

        bready  = 0;

        araddr  = 0;
        arvalid = 0;
        rready  = 0;

        #100;
        resetn = 1;

        #100;

        $display("Starting AXI RAM test...");

        // Write
        axi_write(32'h00000004,32'hDEADBEEF;

        $display("AXI WRITE completed.");

        // Read same location
        axi_read(32'h00000004);

        if (rdata == 32'hDEADBEEF)
            $display("AXI RAM TEST PASSED.");
        else
            $display("AXI RAM TEST FAILED.");

        #100;

        $finish;

    end

endmodule
