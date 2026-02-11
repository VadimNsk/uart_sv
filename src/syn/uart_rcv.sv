//-------------------------------------------------------------------------------
//
//     Project: UART
//
//     Purpose: Receiver
//
//-------------------------------------------------------------------------------

`ifndef UART_RCV_SV
    `define UART_RCV_SV

`include "uart_pkg.svh"


module automatic uart_rcv
    import uart_pkg::*;
(
    input  logic        reset,
    input  logic        clock,
    input  logic        enable,
    //
    input  bit_period_t bit_period,
    //
    input  logic        ready,
    output data_t       dout,
    output logic        valid,
    //
    input  logic        RXD,           // UART Receive Data
    output logic        RXC,           // UART Receive Complete
    output logic        FE,            // UART Framing Error
    output logic        DOR            // UART Data OverRun
);

//------------------------------------------------------------------------------
//
//    Settings
//
localparam SHIFTER_WIDTH   = DATA_WIDTH+1;

localparam STATE_CNT_WIDTH = $clog2(SHIFTER_WIDTH);


//------------------------------------------------------------------------------
//
//    Types
//

typedef enum { IDLE_STATE,
               STARTBIT_STATE,
               RCV_DATA_STATE,
               DATA_OUT_STATE,
               STOPBIT_STATE,
               FINISH_STATE }       state_t;
typedef logic [STATE_CNT_WIDTH-1:0] state_cnt_t;
typedef logic [  SHIFTER_WIDTH-1:0] shifter_t;


//------------------------------------------------------------------------------
//
//    Objects
//

state_t      state       = IDLE_STATE;
state_cnt_t  state_cnt   = 0;

logic        strobe_en   = 0;
bit_period_t bit_prd_reg = 0;
bit_period_t bit_cnt     = 0;
logic        bit_strobe  = 0;

shifter_t    shifter     = '1;
logic[3:0]   RXdff       = '1;

data_t       dout_reg    = 0;
logic        valid_reg   = 0;
logic        RXC_reg     = 0;        // UART Receive Complete
logic        FE_reg      = 0;        // UART Framing Error
logic        DOR_reg     = 0;        // UART Data OverRun

//------------------------------------------------------------------------------
//
//    Functions and tasks
//

//------------------------------------------------------------------------------
//
//    Logic
//

assign dout  = dout_reg;
assign valid = valid_reg;
assign RXC   = RXC_reg;             // UART Receive Complete
assign FE    = FE_reg;              // UART Framing Error
assign DOR   = DOR_reg;             // UART Data OverRun


always_ff @(posedge clock, posedge reset) begin
    if(reset) begin
        bit_cnt    <= 0;
        bit_strobe <= 0;
    end
    else begin
        bit_strobe <= 0;
        if(!strobe_en) begin
            bit_cnt <= {1'b0, bit_prd_reg[BIT_PERIOD_WIDTH-1:1]};
        end
        else begin
            assert (bit_prd_reg)
                else $error("Error: bit_period failed at time %0t", $time);

            bit_cnt         <= bit_cnt - 1;
            if(bit_cnt == 0) begin
                bit_cnt     <= bit_prd_reg;
                bit_strobe  <= 1;
            end
        end
    end
end


always_ff @(posedge clock, posedge reset) begin
    if(reset)
        RXdff <= -1;
    else
        RXdff <= {RXdff[2:0], RXD};
end


always_ff @(posedge clock, posedge reset) begin
    assert (STARTBIT_WIDTH > 0)
        else $error("Error: STARTBIT_WIDTH is null");
    assert (DATA_WIDTH > 0)
        else $error("Error: DATA_WIDTH is null");
    assert (STOPBIT_WIDTH > 0)
        else $error("Error: STOPBIT_WIDTH is null");

    if(reset) begin
        bit_prd_reg <= 1;
        strobe_en   <= 0;
        state       <= IDLE_STATE;
        state_cnt   <= 0;
        shifter     <= '1;
        dout_reg    <= 0;
        valid_reg   <= 0;
        DOR_reg     <= 0;
        FE_reg      <= 0;
        RXC_reg     <= 0;
    end
    else begin
        if(bit_strobe) begin
            shifter <= {RXdff[1], shifter[SHIFTER_WIDTH-1:1]};
        end

        if(ready && valid_reg) begin                        // The data from the output must be read within 1 clock cycle.
            valid_reg <= 0;
            DOR_reg   <= 0;                                 // resetting the data overflow flag when reading data
        end

        // The state of the machine operates from the middle of the previous bit to the middle of the received bit.
        // That is, the STARTBIT_STATE state acts from the front on the RX line to the middle of the starbit,
        // the RCV_BIT0_STATE states act from the middle of the start bit to the middle of the zero bit,
        // and the STOP_BIT_STATE state acts from the middle of the 7th bit to the middle of the stop bit.
        // RX       : < ======== START bit ======== > <  RX_DATA[0]  > <  RX_DATA[1]  >...<  RX_DATA[6]  > <  RX_DATA[7]  > <  STOP bit  >
        // state    : |STARTBIT_STATE|    RCV_BIT0_STATE    | RCV_BIT1_STATE |        ...       | RCV_BIT7_STATE | STOP_BIT_STATE | FINISH_STATE
        case(state)
            IDLE_STATE: begin
                strobe_en   <= 0;
                bit_prd_reg <= bit_period;
                if(RXdff == 5'b1100 || RXdff == 0) begin    // detection of the descending edge
                    state     <= STARTBIT_STATE;
                    state_cnt <= STARTBIT_WIDTH-1;
                    strobe_en <= 1;
                end
            end
            //
            // Waiting for a descending edge or a low signal level
            STARTBIT_STATE: begin
                if(bit_strobe) begin
                    state_cnt <= state_cnt - 1;
                    if(state_cnt == 0) begin
                        state     <= RCV_DATA_STATE;
                        state_cnt <= DATA_WIDTH-1;
                        RXC_reg   <= 0;
                    end
                    if(RXdff != 0) begin
                        state     <= IDLE_STATE;
                        strobe_en <= 0;
                    end
                end
            end
            //
            RCV_DATA_STATE: begin
                if(bit_strobe) begin
                    state_cnt <= state_cnt - 1;
                    if(state_cnt == 0) begin
                        state  <= DATA_OUT_STATE;
                        FE_reg <= 0;                                // frame error reset
                    end
                end
            end
            //
            DATA_OUT_STATE: begin
                state     <= STOPBIT_STATE;
                state_cnt <= STOPBIT_WIDTH-1;
                dout_reg  <= shifter[DATA_WIDTH:1];
            end
            //
            STOPBIT_STATE: begin
                if(bit_strobe) begin
                    if(~RXdff)                                      // the stop bit is noisy or has a low level
                        FE_reg <= 1;                                // frame error
                    state_cnt  <= state_cnt - 1;
                    if(state_cnt == 0) begin
                        state     <= IDLE_STATE;
                        strobe_en <= 0;
                        if(FE_reg || ~RXdff) begin
                            state     <= FINISH_STATE;              // the stop bit failed
                        end else begin                              // the stop bit is good
                            valid_reg <= 1;
                            DOR_reg   <= (valid_reg && !ready);     // data overflow
                            RXC_reg   <= 1;
                        end
                    end
                end
            end
            //
            FINISH_STATE: begin
                strobe_en     <= 1;
                if(bit_strobe || RXdff == 5'b0011 || RXdff == -1) begin   // an ascending front or a high level
                    state     <= IDLE_STATE;
                    strobe_en <= 0;
                end
            end
            //
            default: begin
                assert (state <= STOPBIT_STATE)
                    else $error("Error: state = %0d is failed at time %0t", state, $time);
                state     <= IDLE_STATE;
                strobe_en <= 0;
            end
        endcase

        // If the receiver is turned off, reception is interrupted, the flags do not change.
        if(!enable) begin
            state     <= IDLE_STATE;
            strobe_en <= 0;
        end
    end
end

//------------------------------------------------------------------------------
//
//    Instances
//

//-------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------

`endif //UART_RCV_SV

