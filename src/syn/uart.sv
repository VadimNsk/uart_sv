//-------------------------------------------------------------------------------
//
//     Project: Any
//
//     Purpose: Default top-level file
//
//-------------------------------------------------------------------------------

module automatic uart
#(   parameter CLOCK_FREQ_MHz   = 100
    ,parameter MIN_BAUDRATE_Hz  = 600
)
(    input logic        reset
    ,input logic        clock
    //
//    ,input logic        RX
//    ,output logic       TX
    //
//    ,input byte         din
//    ,output byte        dout
);

//------------------------------------------------------------------------------
//
//    Settings
//
localparam BAUDRATE_RATIO   = CLOCK_FREQ_MHz * 1_000_000 / MIN_BAUDRATE_Hz;
localparam BIT_PERIOD_WIDTH = $clog2(BAUDRATE_RATIO);

//localparam int BLINK_PER_SECOND   = 3;
//localparam int MAX_BLINK_CNT_VAL  = 100_000_000/3/2;
//localparam int BLINK_CNT_W        = $clog2(MAX_BLINK_CNT_VAL);
//localparam REF_CLK_HALF_PERIOD

//------------------------------------------------------------------------------
//
//    Types
//
typedef logic [BIT_PERIOD_WIDTH-1:0] bit_count_t;

//------------------------------------------------------------------------------
//
//    Objects
//

bit_count_t   bit_period = 10;

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

//------------------------------------------------------------------------------
//
//    Instances
//

uart_trn
    #(   .CLOCK_FREQ_MHz(CLOCK_FREQ_MHz)
        ,.MIN_BAUDRATE_Hz(MIN_BAUDRATE_Hz)
        )
    trn_inst
    (    .reset(reset)
        ,.clock(clock)
        ,.bit_period(bit_period)
        );

//------------------------------------------------------------------------------

//-------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------

