`timescale 1ns/1ps

module tb_ram;

    reg clk = 0;
    reg we;
    reg [11:0] addr;
    reg [31:0] wdata;
    wire [31:0] rdata;

    // 50 MHz clock
    always #10 clk = ~clk;

    ram #(
        .ADDR_WIDTH(12),
        .DATA_WIDTH(32)   
    ) dut (
        .clk(clk),
        .we(we),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata)
    );
    //DEPTH = 2^12 = 4096 ; 4096 locations × 32 bits = 16 KB
    initial begin

        $dumpfile("ram.vcd");
        $dumpvars(0, tb_ram);

        we    = 0;
        addr  = 0;
        wdata = 0;

        // WRITE
        #20;
        addr  = 12'h005;
        wdata = 32'h12345678;
        we    = 1;

        @(posedge clk);

        we = 0;

        // READ
        addr = 12'h005;

        @(posedge clk);

        #1;
        $display("RAM READ DATA = %h", rdata);

        if (rdata == 32'h12345678)
            $display("RAM TEST PASSED.");
        else
            $display("RAM TEST FAILED.");

        #20;

        $finish;

    end

endmodule
