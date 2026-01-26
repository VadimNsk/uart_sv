//-------------------------------------------------------------------------------
//
//     Project: UART
//
//     Purpose: Receiver
//
//-------------------------------------------------------------------------------

//`include "cfg_params.svh"

package uart_rcv_pkg;

    localparam  DATA_WIDTH      = 8;
    //
    typedef logic [DATA_WIDTH-1:0]  data_t;

    localparam  STATES_NUM      = DATA_WIDTH + 4;
    localparam  STATE_WIDTH     = $clog2(STATES_NUM);
    //
    typedef logic [STATE_WIDTH-1:0] status_t;
    //
    localparam  IDLE_STATE      = 0;
    localparam  START_BIT_STATE = 1;
    localparam  RCV_BIT0_STATE  = 2;
    localparam  RCV_BITn_STATE  = RCV_BIT0_STATE+DATA_WIDTH-1;
    localparam  STOP_BIT_STATE  = RCV_BITn_STATE+1;
    localparam  FINISH_STATE    = STOP_BIT_STATE+1;

endpackage : uart_rcv_pkg



module automatic uart_rcv
#(   parameter CLOCK_FREQ_MHz       = 100
    ,parameter MIN_BAUDRATE_Hz      = 600
    ,localparam BAUDRATE_RATIO      = CLOCK_FREQ_MHz * 1_000_000 / MIN_BAUDRATE_Hz
    ,localparam BIT_PERIOD_WIDTH    = $clog2(BAUDRATE_RATIO)
)
(    input  logic reset
    ,input  logic clock
    //
    ,input logic[BIT_PERIOD_WIDTH-1:0]  bit_period
    //
    ,output uart_rcv_pkg::status_t      status
    //
    ,input logic                        ready
    ,output uart_rcv_pkg::data_t        dour
    ,output logic                       valid
    //
    ,input logic                        RXd
);

//------------------------------------------------------------------------------
//
//    Settings
//

//------------------------------------------------------------------------------
//
//    Types
//
typedef logic [BIT_PERIOD_WIDTH-1:0]            bit_count_t;

typedef uart_rcv_pkg::status_t                  status_t;

typedef logic [uart_rcv_pkg::DATA_WIDTH+2:0]    shifter_t;


//------------------------------------------------------------------------------
//
//    Objects
//

logic           strobe_en   = 0;
bit_count_t     bit_cnt     = 0;
logic           bit_strobe  = 0;
shifter_t       shifter     = -1;

//------------------------------------------------------------------------------
//
//    Functions and tasks
//

//------------------------------------------------------------------------------
//
//    Logic
//

always_ff @(posedge clock) begin
    if(reset) begin
        bit_cnt     <= 0;
        bit_strobe  <= 0;
    end
    else begin
        assert (bit_period)
            else $error("Error: bit_period failed at time %0t", $time);

        bit_strobe      <= 0;
        if(!strobe_en)
            bit_cnt     <= 0;//bit_period;
        else begin
            bit_cnt     <= bit_cnt - 1;
            if(bit_cnt == 0) begin
                bit_cnt     <= bit_period;
                bit_strobe  <= 1;
            end
        end
    end
end


always_ff @(posedge clock) begin
    if(reset) begin
        status      <= uart_rcv_pkg::IDLE_STATE;
        strobe_en   <= 0;
        TXd         <= 1;
        shifter     <= -1;
        ready       <= 0;
    end
    else begin
        if(bit_strobe) begin
            TXd         <= shifter[0];
            shifter     <= {1'b1, shifter[$size(shifter)-1:1]};
        end

        case(status)
            uart_rcv_pkg::IDLE_STATE: begin
                ready       <= 1;
                if(valid) begin
                    status      <= uart_rcv_pkg::START_BIT_STATE;
                    strobe_en   <= 1;
                    TXd         <= 1;
                    shifter     <= {1'b1, din, 1'b0};
                    ready       <= 0;
                end
            end
            uart_rcv_pkg::FINISH_STATE:
                if(bit_strobe) begin
                    status      <= uart_rcv_pkg::IDLE_STATE;
                    strobe_en   <= 0;
                end
            default: begin
                if(bit_strobe) begin
                    status      <= status + 1;
                end
                assert (status <= uart_rcv_pkg::FINISH_STATE)
                    else $error("Error: bit_period failed at time %0t", $time);
                if(status > uart_rcv_pkg::FINISH_STATE) begin
                    status      <= uart_rcv_pkg::IDLE_STATE;
                    strobe_en   <= 0;
                    TXd         <= 1;
                    shifter     <= -1;
                    ready       <= 0;
                end
            end
        endcase
    end
end

//------------------------------------------------------------------------------
//
//    Instances
//

//-------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------

