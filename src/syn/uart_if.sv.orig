//-------------------------------------------------------------------------------
//
//     Project: Any
//
//     Purpose:
//
//
//-------------------------------------------------------------------------------


//-------------------------------------------------------------------------------
interface trn_if
#(
    parameter CLOCK_FREQ_MHz = 100;
    parameter BAUDRATE_MIN = 600;
);
(
    input logic reset;
    input logic clock
);

//    localparam BLINK
//    localparam REF_CLK_HALF_PERIOD
    localparam baudrate_ratio = CLOCK_FREQ_MHz * 10e6 / BAUDRATE_MIN;
    localparam baudrate_width = $clog2(baudrate_ratio);
    //
    typedef logic[baudrate_width-1:0] baudrate_t;

    typedef enum {waitData, trnData} status_t;

    modport master
    {
        output logic        reset;
        output logic        clock;
        //
        output baudrate_t   baudrate;
        input status_t      status;
        //
        output byte_t       dout;
        output logic        valid;
        input logic         ready
    };

    modport slave
    (
        input logic         reset;
        input logic         clock;
        //
        input baudrate_t    baudrate;
        output status_t     status;
        //
        input byte_t        din;
        input logic         valid;
        output logic        ready
    };
endinterface

//-------------------------------------------------------------------------------


//-------------------------------------------------------------------------------
interface rcv_if
(
    input  logic reset;
    input  logic clock
);

    typedef enum {waitStart, receiveData} status_t;

    modport master
    (
        input byte_t    din;
        input logic     valid;
        output logic    ready;
        //
        input logic     busy;
        input logic     finish
    };

    modport slave
    {
        output byte_t   dout;
        output logic    valid;
        input logic     ready;
        //
        output logic    busy;
        output logic    finish
    };
endinterface
//-------------------------------------------------------------------------------

