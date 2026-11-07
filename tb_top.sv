`timescale 1ns / 1ps
module tb_top;

    import uvm_pkg::*;
    import apb_pkg::*;
    `include "uvm_macros.svh"

    logic PCLK;
    logic PRESETn;

    initial PCLK = 1'b0;
    always #5 PCLK = ~PCLK;

    initial begin
        PRESETn = 1'b0;
        repeat (3) @(posedge PCLK);
        #1 PRESETn = 1'b1;
    end

    apb_if vif (.PCLK(PCLK), .PRESETn(PRESETn));

    apb_top dut (
        .PCLK    (PCLK),
        .PRESETn (PRESETn),
        .PADDR   (vif.PADDR),
        .PSEL    (vif.PSEL),
        .PENABLE (vif.PENABLE),
        .PWRITE  (vif.PWRITE),
        .PWDATA  (vif.PWDATA),
        .PRDATA  (vif.PRDATA),
        .PREADY  (vif.PREADY)
    );

    initial begin
        uvm_config_db#(virtual apb_if)::set(null, "*", "vif", vif);
        run_test("apb_test");
    end

endmodule