`timescale 1ns / 1ps
//------------------------------------------------------------------
// APB interface: bundles all APB signals with clocking blocks
//------------------------------------------------------------------
interface apb_if (input logic PCLK, input logic PRESETn);

    logic [31:0] PADDR;
    logic        PSEL;
    logic        PENABLE;
    logic        PWRITE;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;
    logic        PREADY;

    // Driver clocking block: drives the master-side signals
    clocking drv_cb @(posedge PCLK);
        default input #1step output #1;
        output PADDR, PSEL, PENABLE, PWRITE, PWDATA;
        input  PRDATA, PREADY;
    endclocking

    // Monitor clocking block: samples everything
    clocking mon_cb @(posedge PCLK);
        default input #1step;
        input PADDR, PSEL, PENABLE, PWRITE, PWDATA, PRDATA, PREADY;
    endclocking

    modport DRV (clocking drv_cb, input PCLK, PRESETn);
    modport MON (clocking mon_cb, input PCLK, PRESETn);

endinterface