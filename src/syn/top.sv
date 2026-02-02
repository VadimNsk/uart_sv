//-------------------------------------------------------------------------------
//
//     Project: Any
//
//     Purpose: Default top-level file
//
//-------------------------------------------------------------------------------

`include "cfg_params.svh"


module automatic top
#(
    localparam int CLOCK_FREQ_MHz   = `REF_CLK
    ,localparam int MIN_BAUDRATE_Hz  = 600

    ,localparam int MIN_BAUDRATE_RATIO  = CLOCK_FREQ_MHz * 1_000_000 / MIN_BAUDRATE_Hz
    ,localparam int BIT_PERIOD_WIDTH    = $clog2(MIN_BAUDRATE_RATIO)
)
(
    input logic         rst,
    input logic         clk

    // UART
    ,input logic[BIT_PERIOD_WIDTH-1:0]                  bit_period
    ,input wire[0:$size(uart_pkg::uart_control_t)-1]    control
    ,output wire[0:$size(uart_pkg::uart_status_t)-1]    status
    ,output logic                           TXCI        // TX Complete Interrupt
    ,output logic                           RXCI        // RX Complete Interrupt
    ,output logic                           UDRI        // Data Register Empty Interrupt
    //
    ,output logic                           tx_ready
    ,input uart_trn_pkg::data_t             tx_din
    ,input logic                            tx_valid
    //
    ,input logic                            rx_ready
    ,output uart_rcv_pkg::data_t            rx_dout
    ,output logic                           rx_valid
    //
    ,output logic                           TX          // UART Transmit Data
    ,input logic                            RX          // UART Receive Data
);

//------------------------------------------------------------------------------
//
//    Settings
//

//------------------------------------------------------------------------------
//
//    Types
//
typedef logic [BIT_PERIOD_WIDTH-1:0]    bit_period_t;
//typedef uart_trn_pkg::data_t            data_t;
//import uart_trn_pkg::data_t;

//------------------------------------------------------------------------------
//
//    Objects
//
uart_pkg::uart_control_t    control_reg;
uart_pkg::uart_status_t     status_reg;


//------------------------------------------------------------------------------
//
//    ILA debug
//


//------------------------------------------------------------------------------
//
//    Functions and tasks
//

//------------------------------------------------------------------------------
//
//    Logic
//

//logic clock;

assign control_reg  = control;
assign status       = status_reg;


//------------------------------------------------------------------------------
//
//    Instances
//
/*
IBUFG clk_inst
(
    .I  ( clk ),
    .O  ( clock )
);
*/
//assign clock = clk;

uart
    #(   .CLOCK_FREQ_MHz(CLOCK_FREQ_MHz)
        ,.MIN_BAUDRATE_Hz(MIN_BAUDRATE_Hz)
    )
    uart_inst
    (    .reset(rst)
        ,.clock(clk)
        // UART
        ,.bit_period(bit_period)
        ,.control(control_reg)
        ,.status(status_reg)
        ,.TXCI(TXCI)        // TX Complete Interrupt
        ,.RXCI(RXCI)        // RX Complete Interrupt
        ,.UDRI(UDRI)        // Data Register Empty Interrupt
        //
        ,.tx_ready(tx_ready)
        ,.tx_din(tx_din)
        ,.tx_valid(tx_valid)
        //
        ,.rx_ready(rx_ready)
        ,.rx_dout(rx_dout)
        ,.rx_valid(rx_valid)
        //
        ,.TX(TX)            // UART Transmit Data
        ,.RX(RX)            // UART Receive Data
    );

//-------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------

