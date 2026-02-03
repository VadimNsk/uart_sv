//-------------------------------------------------------------------------------
//
//     Project: UART
//
//     Purpose: uart_pkg
//
//-------------------------------------------------------------------------------

`ifndef UART_DEFS_H
`define UART_DEFS_H

`include "cfg_params.svh"


package uart_pkg;

    localparam CLOCK_FREQ_MHz     = `REF_CLK;
    localparam MIN_BAUDRATE_Hz    = 600;
    localparam MIN_BAUDRATE_RATIO = CLOCK_FREQ_MHz * 1_000_000 / MIN_BAUDRATE_Hz;
    localparam BIT_PERIOD_WIDTH   = $clog2(MIN_BAUDRATE_RATIO);

    typedef logic [BIT_PERIOD_WIDTH-1:0] bit_period_t;


    localparam DATA_WIDTH         = 8;
    //
    typedef logic [DATA_WIDTH-1:0] data_t;


    typedef struct packed
    {   logic RXC;      // UART Receive Complete
        logic TXC;      // UART Transmit Complete
        logic UDRE;     // UART Data Register Empty
        logic FE;       // UART Framing Error
        logic DOR;      // UART Data OverRun
//      logic reserved[2:0];
    } uart_status_t;


    typedef struct packed
    {   logic RXCIE;    // RX Complete Interrupt Enable
        logic TXCIE;    // TX Complete Interrupt Enable
        logic UDRIE;    // UART Data Register Empty Interrupt Enable
        logic RXEN;     // Receiver Enable
        logic TXEN;     // Transmitter Enable
//      logic reserved[2:0];
//      logic CHR9;     // 9 Bit Characters
//      logic RXB8;     // Receive Data Bit 8
//      logic TXB8;     // Transmit Data Bit 8
    } uart_control_t;

endpackage : uart_pkg

`endif // UART_DEFS_H
