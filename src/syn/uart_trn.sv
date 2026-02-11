//-------------------------------------------------------------------------------
//
//     Project: UART
//
//     Purpose: Transmitter
//
//-------------------------------------------------------------------------------

`ifndef UART_TRN_SV
    `define UART_TRN_SV

`include "uart_pkg.svh"


module automatic uart_trn
    import uart_pkg::*;
(
    input logic        reset,
    input logic        clock,
    //
    input bit_period_t bit_period,
    //
    output logic       ready,
    input data_t       din,
    input logic        valid,
    //
    output logic       TXD,            // UART Transmit Data
    output logic       TXC             // UART Transmit Complete
);

//------------------------------------------------------------------------------
//
//    Settings
//
localparam SHIFTER_WIDTH   = STOPBIT_WIDTH+DATA_WIDTH+STARTBIT_WIDTH;

localparam STATE_CNT_WIDTH = $clog2(SHIFTER_WIDTH);


//------------------------------------------------------------------------------
//
//    Types
//
typedef enum { IDLE_STATE,
               START_STATE,
               STARTBIT_STATE,
               TRN_DATA_STATE,
               STOPBIT_STATE }      state_t;
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

logic        ready_reg   = 0;
logic        TXD_reg     = 0;   // UART Transmit Data
logic        TXC_reg     = 0;   // UART Transmit Complete

//------------------------------------------------------------------------------
//
//    Functions and tasks
//

//------------------------------------------------------------------------------
//
//    Logic
//

assign ready = ready_reg;
assign TXD   = TXD_reg;         // UART Transmit Data
assign TXC   = TXC_reg;         // UART Transmit Complete


always_ff @(posedge clock, posedge reset) begin
    if(reset) begin
        bit_cnt    <= 0;
        bit_strobe <= 0;
    end
    else begin
        bit_strobe <= 0;
        if(!strobe_en) begin
            bit_cnt <= 0;//bit_prd_reg;
        end
        else begin
            assert (bit_prd_reg)
                else $error("Error: bit_period failed at time %0t", $time);

            bit_cnt <= bit_cnt - 1;
            if(bit_cnt == 0) begin
                bit_cnt    <= bit_prd_reg;
                bit_strobe <= 1;
            end
        end
    end
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
        TXD_reg     <= 1;
        shifter     <= '1;
        ready_reg   <= 0;
        TXC_reg     <= 0;
    end
    else begin
        if(bit_strobe) begin
            TXD_reg <= shifter[0];
            shifter <= {1'b1, shifter[SHIFTER_WIDTH-1:1]};
        end

        // The state of the machine is valid during the transmission of the bit.
        // That is, the STARTBIT_STATE state is valid until the gate switches to transmitting the 0th bit,
        // and the STOP_BIT_STATE state is valid until the end of the stopbit, i.e. until the end of the transaction.
        case(state)
            IDLE_STATE: begin
                strobe_en   <= 0;
                bit_prd_reg <= bit_period;
                ready_reg   <= 1;
                TXD_reg     <= 1;
                if(valid && ready_reg) begin
                    state     <= START_STATE;
                    strobe_en <= 1;
                    shifter   <= {{STOPBIT_WIDTH{1'b1}}, din, {STARTBIT_WIDTH{1'b0}}};
                    ready_reg <= 0;
                    TXC_reg   <= 0;
                end
            end
            //
            START_STATE: begin
                if(bit_strobe) begin
                    state     <= STARTBIT_STATE;
                    state_cnt <= STARTBIT_WIDTH-1;
                end
            end
            //
            STARTBIT_STATE: begin
                if(bit_strobe) begin
                    state_cnt <= state_cnt - 1;
                    if(state_cnt == 0) begin
                        state     <= TRN_DATA_STATE;
                        state_cnt <= DATA_WIDTH-1;
                    end
                end
            end
            //
            TRN_DATA_STATE: begin
                if(bit_strobe) begin
                    state_cnt <= state_cnt - 1;
                    if(state_cnt == 0) begin
                        state     <= STOPBIT_STATE;
                        state_cnt <= STOPBIT_WIDTH;
                    end
                end
            end
            //
            STOPBIT_STATE: begin
                if(bit_strobe) begin
                    state_cnt <= state_cnt - 1;
                    if(state_cnt == 0) begin
                        state     <= IDLE_STATE;
                        strobe_en <= 0;
                        TXC_reg   <= 1;
                    end
                end
            end
            //
            default: begin
                assert (state <= STOPBIT_STATE)
                    else $error("Error: state = %0d is failed at time %0t", state, $time);
                state     <= IDLE_STATE;
                strobe_en <= 0;
                TXD_reg   <= 1;
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

`endif //UART_TRN_SV

