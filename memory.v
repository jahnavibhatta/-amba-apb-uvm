`timescale 1ns / 1ps
//------------------------------------------------------------------
// Simple memory connected behind the APB slave
// Ports follow the paper: WR, RD, ADDR_WR, ADDR_RD, DIN, DOUT
// - Synchronous write (when WR=1)
// - Synchronous read  (when RD=1), DOUT valid one clock later
//------------------------------------------------------------------
module memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter DEPTH      = 256          // only the lower log2(DEPTH) address bits are used
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  WR,
    input  wire                  RD,
    input  wire [ADDR_WIDTH-1:0] ADDR_WR,
    input  wire [ADDR_WIDTH-1:0] ADDR_RD,
    input  wire [DATA_WIDTH-1:0] DIN,
    output reg  [DATA_WIDTH-1:0] DOUT
);

    localparam IDX_W = $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = {DATA_WIDTH{1'b0}};
    end

    // Write port
    always @(posedge clk) begin
        if (WR)
            mem[ADDR_WR[IDX_W-1:0]] <= DIN;
    end

    // Read port (registered output)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            DOUT <= {DATA_WIDTH{1'b0}};
        else if (RD)
            DOUT <= mem[ADDR_RD[IDX_W-1:0]];
    end

endmodule