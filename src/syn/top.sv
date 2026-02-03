//-------------------------------------------------------------------------------
//
//     Project: Any
//
//     Purpose: Default top-level file
//
//-------------------------------------------------------------------------------

`include "cfg_params.svh"
`include "uart_pkg.svh"


module automatic top
    import uart_pkg::*;
(
    input logic                              rst,
    input logic                              clk,

    // UART
    input  logic [     BIT_PERIOD_WIDTH-1:0] bit_period,
    input  wire  [$size(uart_control_t)-1:0] control,
    output wire  [ $size(uart_status_t)-1:0] status,
    output logic                             TXCI,        // TX Complete Interrupt
    output logic                             RXCI,        // RX Complete Interrupt
    output logic                             UDRI,        // Data Register Empty Interrupt
    //
    output logic                             tx_ready,
    input  data_t                            tx_din,
    input  logic                             tx_valid,
    //
    input  logic                             rx_ready,
    output data_t                            rx_dout,
    output logic                             rx_valid,
    //
    output logic                             TX,         // UART Transmit Data
    input  logic                             RX          // UART Receive Data
);

//------------------------------------------------------------------------------
//
//    Settings
//

//------------------------------------------------------------------------------
//
//    Types
//

//------------------------------------------------------------------------------
//
//    Objects
//
uart_control_t    control_reg;
uart_status_t     status_reg;


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

uart    uart_inst
(    .reset        ( rst         )
    ,.clock        ( clk         )
    // UART
    ,.bit_period   ( bit_period  )
    ,.control      ( control_reg )
    ,.status       ( status_reg  )
    ,.TXCI         ( TXCI        )        // TX Complete Interrupt
    ,.RXCI         ( RXCI        )        // RX Complete Interrupt
    ,.UDRI         ( UDRI        )        // Data Register Empty Interrupt
    //
    ,.tx_ready     ( tx_ready    )
    ,.tx_din       ( tx_din      )
    ,.tx_valid     ( tx_valid    )
    //
    ,.rx_ready     ( rx_ready    )
    ,.rx_dout      ( rx_dout     )
    ,.rx_valid     ( rx_valid    )
    //
    ,.TX           ( TX          )            // UART Transmit Data
    ,.RX           ( RX          )            // UART Receive Data
);

//-------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------

