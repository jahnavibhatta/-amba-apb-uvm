`timescale 1ns / 1ps
//------------------------------------------------------------------
// AMBA APB3 Master (acts like the bridge in Fig 1 of the paper)
//
// User side (command interface):
//   start  : pulse high for 1 clock to launch a transfer (when busy=0)
//   write  : 1 = write transfer, 0 = read transfer
//   addr   : transfer address
//   wdata  : write data (ignored for reads)
//   rdata  : read data, valid when done=1
//   done   : 1-clock pulse when the transfer completes
//   busy   : high from start until done
//
// APB side: drives PSEL / PENABLE / PWRITE / PADDR / PWDATA through
// IDLE -> SETUP -> ACCESS and waits in ACCESS until PREADY=1.
//------------------------------------------------------------------
module apb_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                  PCLK,
    input  wire                  PRESETn,

    // User / testbench side
    input  wire                  start,
    input  wire                  write,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] wdata,
    output reg  [DATA_WIDTH-1:0] rdata,
    output reg                   done,
    output wire                  busy,

    // APB side
    output reg  [ADDR_WIDTH-1:0] PADDR,
    output reg                   PSEL,
    output reg                   PENABLE,
    output reg                   PWRITE,
    output reg  [DATA_WIDTH-1:0] PWDATA,
    input  wire [DATA_WIDTH-1:0] PRDATA,
    input  wire                  PREADY
);

    localparam [1:0] IDLE   = 2'b00,
                     SETUP  = 2'b01,
                     ACCESS = 2'b10;

    reg [1:0] state;

    assign busy = (state != IDLE);

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            state   <= IDLE;
            PSEL    <= 1'b0;
            PENABLE <= 1'b0;
            PWRITE  <= 1'b0;
            PADDR   <= {ADDR_WIDTH{1'b0}};
            PWDATA  <= {DATA_WIDTH{1'b0}};
            rdata   <= {DATA_WIDTH{1'b0}};
            done    <= 1'b0;
        end else begin
            done <= 1'b0;                       // default: pulse only

            case (state)
                //--------------------------------------------------
                IDLE: begin
                    PSEL    <= 1'b0;
                    PENABLE <= 1'b0;
                    if (start) begin
                        // Drive SETUP phase: PSEL=1, PENABLE=0,
                        // address / direction / data valid
                        PSEL   <= 1'b1;
                        PWRITE <= write;
                        PADDR  <= addr;
                        PWDATA <= write ? wdata : PWDATA;
                        state  <= SETUP;
                    end
                end

                //--------------------------------------------------
                SETUP: begin
                    // SETUP lasts exactly one clock, then ACCESS
                    PENABLE <= 1'b1;
                    state   <= ACCESS;
                end

                //--------------------------------------------------
                ACCESS: begin
                    // Hold PSEL/PENABLE until the slave is ready
                    if (PREADY) begin
                        if (!PWRITE)
                            rdata <= PRDATA;    // capture read data
                        PSEL    <= 1'b0;
                        PENABLE <= 1'b0;
                        done    <= 1'b1;
                        state   <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule