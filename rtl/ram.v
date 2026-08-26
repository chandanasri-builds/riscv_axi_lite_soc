`timescale 1ns/1ps

module ram #(
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  we,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] wdata,
    output reg  [DATA_WIDTH-1:0] rdata
);

    localparam DEPTH = 1 << ADDR_WIDTH;  //depth = 2^ address width

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge clk) begin

        // Write
        if (we) begin
            mem[addr] <= wdata;
        end

        // Read
        rdata <= mem[addr];

    end

endmodule
