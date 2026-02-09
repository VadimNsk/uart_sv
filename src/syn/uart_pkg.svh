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

    localparam CLOCK_FREQ_MHz      = `REF_CLK;
    localparam int CLOCK_PERIOD_ns = 1_000 / CLOCK_FREQ_MHz;


    localparam MIN_BAUDRATE_Hz     = 600;
    localparam MIN_BAUDRATE_RATIO  = CLOCK_FREQ_MHz * 1_000_000 / MIN_BAUDRATE_Hz;
    localparam BIT_PERIOD_WIDTH    = $clog2(MIN_BAUDRATE_RATIO);
    //
    typedef logic [BIT_PERIOD_WIDTH-1:0] bit_period_t;
    //
    function bit_period_t get_bit_period (input int baudrate);
    begin
        get_bit_period = CLOCK_FREQ_MHz * 1_000_000 / baudrate;
    end
    endfunction


    localparam STARTBIT_WIDTH      = 1;
    localparam DATA_WIDTH          = 8;
    localparam STOPBIT_WIDTH       = 1;
    //
    typedef logic [DATA_WIDTH-1:0] data_t;


    localparam int TEST_BAUDRATE    = 192_000;
    localparam int TEST_BIT_PERIOD  = 1_000_000_000 / TEST_BAUDRATE;


    typedef struct packed
    {   logic RXC;      // UART Receive Complete
        logic TXC;      // UART Transmit Complete
        logic TXDRE;    // UART TX Data Register Empty
        logic RXDRNE;   // UART RX Data Register Not Empty
        logic FE;       // UART Framing Error
        logic DOR;      // UART Data OverRun
//      logic reserved[1:0];
    } status_t;


    typedef struct packed
    {   logic RXCIE;    // RX Complete Interrupt Enable
        logic TXCIE;    // TX Complete Interrupt Enable
        logic TXDREIE;  // TX Data Register Empty Interrupt Enable
        logic RXDRNEIE; // RX Data Register Not Empty Interrupt Enable
        logic RXEN;     // Receiver Enable
        logic TXEN;     // Transmitter Enable
//      logic reserved[1:0];
    } control_t;

endpackage : uart_pkg

`endif // UART_DEFS_H

