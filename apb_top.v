`timescale 1ns / 1ps
//------------------------------------------------------------------
// APB top: APB slave + memory
// The bridge/master (or testbench) drives the APB signals on the left.
//------------------------------------------------------------------
module apb_top #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 256
)(
    input  wire                  PCLK,
    input  wire                  PRESETn,
    input  wire [ADDR_WIDTH-1:0] PADDR,
    input  wire                  PSEL,
    input  wire                  PENABLE,
    input  wire                  PWRITE,
    input  wire [DATA_WIDTH-1:0] PWDATA,
    output wire [DATA_WIDTH-1:0] PRDATA,
    output wire                  PREADY
);

    wire                  wr, rd;
    wire [ADDR_WIDTH-1:0] addr_wr, addr_rd;
    wire [DATA_WIDTH-1:0] din, dout;

    apb_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_apb_slave (
        .PCLK        (PCLK),
        .PRESETn     (PRESETn),
        .PADDR       (PADDR),
        .PSEL        (PSEL),
        .PENABLE     (PENABLE),
        .PWRITE      (PWRITE),
        .PWDATA      (PWDATA),
        .PRDATA      (PRDATA),
        .PREADY      (PREADY),
        .mem_wr      (wr),
        .mem_rd      (rd),
        .mem_addr_wr (addr_wr),
        .mem_addr_rd (addr_rd),
        .mem_din     (din),
        .mem_dout    (dout)
    );

    memory #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH     (MEM_DEPTH)
    ) u_memory (
        .clk     (PCLK),
        .rst_n   (PRESETn),
        .WR      (wr),
        .RD      (rd),
        .ADDR_WR (addr_wr),
        .ADDR_RD (addr_rd),
        .DIN     (din),
        .DOUT    (dout)
    );

endmodule