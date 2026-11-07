`timescale 1ns / 1ps
//------------------------------------------------------------------
// AMBA APB3 Slave
// - 3-state operation: IDLE -> SETUP -> ACCESS (see Fig 3 of the paper)
// - Zero wait states: PREADY is high during the ACCESS phase
// - Talks to a memory through a simple WR/RD interface (see memory.v)
//------------------------------------------------------------------
module apb_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // APB side
    input  wire                  PCLK,
    input  wire                  PRESETn,
    input  wire [ADDR_WIDTH-1:0] PADDR,
    input  wire                  PSEL,
    input  wire                  PENABLE,
    input  wire                  PWRITE,
    input  wire [DATA_WIDTH-1:0] PWDATA,
    output wire [DATA_WIDTH-1:0] PRDATA,
    output wire                  PREADY,

    // Memory side
    output wire                  mem_wr,
    output wire                  mem_rd,
    output wire [ADDR_WIDTH-1:0] mem_addr_wr,
    output wire [ADDR_WIDTH-1:0] mem_addr_rd,
    output wire [DATA_WIDTH-1:0] mem_din,
    input  wire [DATA_WIDTH-1:0] mem_dout
);

    // ---------------- Bus state (decoded from the bus) -------------
    localparam [1:0] IDLE   = 2'b00,
                     SETUP  = 2'b01,
                     ACCESS = 2'b10;

    // The state follows the bus: it must be known in the same cycle the
    // master drives PSEL/PENABLE, so it is decoded combinationally.
    reg [1:0] state;
    always @(*) begin
        if (!PSEL)          state = IDLE;    // PSEL=0
        else if (!PENABLE)  state = SETUP;   // PSEL=1, PENABLE=0
        else                state = ACCESS;  // PSEL=1, PENABLE=1
    end

    // ---------------- Handshake ------------------------------------
    // No wait states: slave is always ready in the ACCESS phase.
    assign PREADY = (state == ACCESS);

    // ---------------- Memory control -------------------------------
    // Write: strobe in ACCESS phase, memory captures at the end of it.
    assign mem_wr      = (state == ACCESS) &  PWRITE;
    assign mem_addr_wr = PADDR;
    assign mem_din     = PWDATA;

    // Read: strobe in SETUP phase so the registered memory output is
    // valid during the following ACCESS phase.
    assign mem_rd      = (state == SETUP) & ~PWRITE;
    assign mem_addr_rd = PADDR;

    // Read data back to the bus
    assign PRDATA = mem_dout;

endmodule