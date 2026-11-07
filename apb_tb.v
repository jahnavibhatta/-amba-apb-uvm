`timescale 1ns / 1ps
//------------------------------------------------------------------
// Verilog testbench for APB master + APB slave/memory (Fig 6 style)
//  - generates clock and reset
//  - directed write/read tests (same pattern as the paper)
//  - random write/read-back tests
//  - $monitor log and automatic PASS/FAIL check
//------------------------------------------------------------------
module apb_tb;

    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;

    // ---------------- Clock / reset ---------------------------------
    reg PCLK;
    reg PRESETn;

    // ---------------- User side of the master -----------------------
    reg                   start;
    reg                   write;
    reg  [ADDR_WIDTH-1:0] addr;
    reg  [DATA_WIDTH-1:0] wdata;
    wire [DATA_WIDTH-1:0] rdata;
    wire                  done;
    wire                  busy;

    // ---------------- APB bus ---------------------------------------
    wire [ADDR_WIDTH-1:0] PADDR;
    wire                  PSEL;
    wire                  PENABLE;
    wire                  PWRITE;
    wire [DATA_WIDTH-1:0] PWDATA;
    wire [DATA_WIDTH-1:0] PRDATA;
    wire                  PREADY;

    // ---------------- DUT -------------------------------------------
    apb_master #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) u_master (
        .PCLK    (PCLK),
        .PRESETn (PRESETn),
        .start   (start),
        .write   (write),
        .addr    (addr),
        .wdata   (wdata),
        .rdata   (rdata),
        .done    (done),
        .busy    (busy),
        .PADDR   (PADDR),
        .PSEL    (PSEL),
        .PENABLE (PENABLE),
        .PWRITE  (PWRITE),
        .PWDATA  (PWDATA),
        .PRDATA  (PRDATA),
        .PREADY  (PREADY)
    );

    apb_top #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) u_dut (
        .PCLK    (PCLK),
        .PRESETn (PRESETn),
        .PADDR   (PADDR),
        .PSEL    (PSEL),
        .PENABLE (PENABLE),
        .PWRITE  (PWRITE),
        .PWDATA  (PWDATA),
        .PRDATA  (PRDATA),
        .PREADY  (PREADY)
    );

    // ---------------- Clock: 10 ns period ---------------------------
    initial PCLK = 1'b0;
    always #5 PCLK = ~PCLK;

    // ---------------- Scoreboard counters ---------------------------
    integer pass_cnt;
    integer fail_cnt;
    integer i;

    // ---------------- Tasks -----------------------------------------
    task apb_write(input [ADDR_WIDTH-1:0] a, input [DATA_WIDTH-1:0] d);
    begin
        @(posedge PCLK); #1;
        start = 1'b1; write = 1'b1; addr = a; wdata = d;
        @(posedge PCLK); #1;
        start = 1'b0;
        @(posedge done);
        @(posedge PCLK); #1;
    end
    endtask

    task apb_read_check(input [ADDR_WIDTH-1:0] a, input [DATA_WIDTH-1:0] expected);
    begin
        @(posedge PCLK); #1;
        start = 1'b1; write = 1'b0; addr = a;
        @(posedge PCLK); #1;
        start = 1'b0;
        @(posedge done);
        #1;
        if (rdata === expected) begin
            pass_cnt = pass_cnt + 1;
            $display("[PASS] t=%0t  READ  addr=%h  data=%h", $time, a, rdata);
        end else begin
            fail_cnt = fail_cnt + 1;
            $display("[FAIL] t=%0t  READ  addr=%h  got=%h  expected=%h",
                      $time, a, rdata, expected);
        end
        @(posedge PCLK); #1;
    end
    endtask

    // ---------------- Bus monitor (Fig 6 style) ---------------------
    initial begin
        $monitor("%0t PSEL=%b, PENABLE=%b, PWRITE=%b, PADDR=%h, PWDATA=%h, PRDATA=%h, PREADY=%b",
                  $time, PSEL, PENABLE, PWRITE, PADDR, PWDATA, PRDATA, PREADY);
    end

    // ---------------- Main stimulus ---------------------------------
    reg [DATA_WIDTH-1:0] ref_mem [0:15];

    initial begin
        pass_cnt = 0;
        fail_cnt = 0;
        start    = 1'b0;
        write    = 1'b0;
        addr     = {ADDR_WIDTH{1'b0}};
        wdata    = {DATA_WIDTH{1'b0}};
        PRESETn  = 1'b0;

        // Reset
        repeat (3) @(posedge PCLK);
        #1 PRESETn = 1'b1;
        repeat (2) @(posedge PCLK);

        // ---- Directed test (pattern from the paper) ----
        $display("---- Directed test ----");
        apb_write(32'h00000001, 32'hCCCCCCCC);
        apb_read_check(32'h00000001, 32'hCCCCCCCC);

        apb_write(32'h00000002, 32'h0000000F);
        apb_read_check(32'h00000002, 32'h0000000F);

        apb_write(32'h00000003, 32'h000000AA);
        apb_read_check(32'h00000003, 32'h000000AA);

        // Overwrite address 2 with new data
        apb_write(32'h00000002, 32'h000000F0);
        apb_read_check(32'h00000002, 32'h000000F0);

        // Earlier locations must be unchanged
        apb_read_check(32'h00000001, 32'hCCCCCCCC);
        apb_read_check(32'h00000003, 32'h000000AA);

        // ---- Random test: write 16 locations, read all back ----
        $display("---- Random test ----");
        for (i = 0; i < 16; i = i + 1) begin
            ref_mem[i] = $random;
            apb_write(i + 32'h10, ref_mem[i]);
        end
        for (i = 0; i < 16; i = i + 1)
            apb_read_check(i + 32'h10, ref_mem[i]);

        // ---- Summary ----
        repeat (3) @(posedge PCLK);
        $display("=======================================");
        $display(" TEST SUMMARY: PASS = %0d, FAIL = %0d", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display(" RESULT: ALL TESTS PASSED");
        else               $display(" RESULT: TEST FAILED");
        $display("=======================================");
        $finish;
    end

    // ---------------- Watchdog --------------------------------------
    initial begin
        #200000;
        $display("[ERROR] Simulation timeout");
        $finish;
    end

endmodule