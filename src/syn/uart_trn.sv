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
localparam SHIFTER_WIDTH   = DATA_WIDTH+2;

localparam IDLE_STATE      = 0;
localparam START_STATE     = 1;
localparam START_BIT_STATE = 2;
localparam TRN_BIT0_STATE  = 3;
localparam TRN_BITn_STATE  = TRN_BIT0_STATE+DATA_WIDTH-1;
localparam STOP_BIT_STATE  = TRN_BITn_STATE+1;
//
localparam STATES_NUM      = STOP_BIT_STATE + 1;
localparam STATE_WIDTH     = $clog2(STATES_NUM);

//------------------------------------------------------------------------------
//
//    Types
//
typedef logic [  STATE_WIDTH-1:0] state_t;

typedef logic [SHIFTER_WIDTH-1:0] shifter_t;

//------------------------------------------------------------------------------
//
//    Objects
//

state_t      state       = IDLE_STATE;
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
    if(reset) begin
        bit_prd_reg <= 1;
        strobe_en   <= 0;
        state       <= IDLE_STATE;
        TXD_reg     <= 1;
        shifter     <= -1;
        ready_reg   <= 0;
        TXC_reg     <= 0;
    end
    else begin
        if(bit_strobe) begin
            TXD_reg <= shifter[0];
            shifter <= {1'b1, shifter[SHIFTER_WIDTH-1:1]};
        end

        // Состояние автомата действует на протяжении передачи бита.
        // Т.е. состояние START_BIT_STATE действует до строба переключения на передачу 0-го бита,
        // а состояние STOP_BIT_STATE действует до конца стопбита, т.е. до окончания транзакции
        case(state)
            IDLE_STATE: begin
                strobe_en   <= 0;
                bit_prd_reg <= bit_period;
                ready_reg   <= 1;
                TXD_reg     <= 1;
                if(valid && ready_reg) begin
                    state     <= START_STATE;
                    strobe_en <= 1;

                    shifter   <= {-1, din, 1'b0};
                    ready_reg <= 0;
                    TXC_reg   <= 0;
                end
            end
            //
            STOP_BIT_STATE:
                if(bit_strobe) begin
                    state     <= IDLE_STATE;
                    strobe_en <= 0;
                    TXC_reg   <= 1;
                end
            //
            default: begin
                if(bit_strobe) begin
                    state         <= state + 1;
                    if(state == STOP_BIT_STATE) begin
                        state     <= IDLE_STATE;
                        strobe_en <= 0;
                    end
                end
                // Если сбой работы командного автомата и выход за диапазон допустимых состояний
                assert (state <= STOP_BIT_STATE)
                    else $error("Error: state = %0d is failed at time %0t", state, $time);
                if(state > STOP_BIT_STATE) begin
                    state     <= IDLE_STATE;
                    strobe_en <= 0;
                    TXD_reg   <= 1;
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

`endif //UART_TRN_SV

