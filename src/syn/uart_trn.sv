//-------------------------------------------------------------------------------
//
//     Project: UART
//
//     Purpose: Transmitter
//
//-------------------------------------------------------------------------------

package uart_trn_pkg;

    localparam DATA_WIDTH       = 8;
    //
    typedef logic [DATA_WIDTH-1:0]  data_t;

    localparam IDLE_STATE       = 0;
    localparam START_STATE      = 1;
    localparam START_BIT_STATE  = 2;
    localparam TRN_BIT0_STATE   = 3;
    localparam TRN_BITn_STATE   = TRN_BIT0_STATE+DATA_WIDTH-1;
    localparam STOP_BIT_STATE   = TRN_BITn_STATE+1;
    //
    localparam STATES_NUM       = STOP_BIT_STATE + 1;
    localparam STATE_WIDTH      = $clog2(STATES_NUM);
    //
    typedef logic [STATE_WIDTH-1:0] state_t;

endpackage : uart_trn_pkg



module automatic uart_trn
#(   parameter CLOCK_FREQ_MHz       = 100
    ,parameter MIN_BAUDRATE_Hz      = 600
    ,localparam MIN_BAUDRATE_RATIO  = CLOCK_FREQ_MHz * 1_000_000 / MIN_BAUDRATE_Hz
    ,localparam BIT_PERIOD_WIDTH    = $clog2(MIN_BAUDRATE_RATIO)
)
(    input logic    reset
    ,input logic    clock
//  ,input logic    enable
    //
    ,input logic[BIT_PERIOD_WIDTH-1:0]  bit_period
    //
//  ,output uart_trn_pkg::state_t       state   = uart_trn_pkg::IDLE_STATE
    //
    ,output logic                       ready
    ,input uart_trn_pkg::data_t         din
    ,input logic                        valid
    //
    ,output logic                       TXD             // UART Transmit Data
    ,output logic                       TXC             // UART Transmit Complete
);

//------------------------------------------------------------------------------
//
//    Settings
//
localparam SHIFTER_WIDTH    = uart_trn_pkg::DATA_WIDTH+2;

//------------------------------------------------------------------------------
//
//    Types
//
typedef logic [BIT_PERIOD_WIDTH-1:0]    bit_period_t;

typedef uart_trn_pkg::state_t           state_t;

typedef logic [SHIFTER_WIDTH-1:0]       shifter_t;

//------------------------------------------------------------------------------
//
//    Objects
//

uart_trn_pkg::state_t   state       = uart_trn_pkg::IDLE_STATE;
logic                   strobe_en   = 0;
bit_period_t            bit_prd_reg = 0;
bit_period_t            bit_cnt     = 0;
logic                   bit_strobe  = 0;
shifter_t               shifter     = -1;

//------------------------------------------------------------------------------
//
//    Functions and tasks
//

//------------------------------------------------------------------------------
//
//    Logic
//
/*
initial begin
    ready   = 0;
    //
    TXD     = 1;    // UART Transmit Data
    TXC     = 0;    // UART Transmit Complete
end
*/

always_ff @(posedge clock, posedge reset) begin
    if(reset) begin
        bit_cnt     <= 0;
        bit_strobe  <= 0;
    end
    else begin
        bit_strobe      <= 0;
        if(!strobe_en) begin
            bit_cnt     <= 0;//bit_prd_reg;
        end
        else begin
            assert (bit_prd_reg)
                else $error("Error: bit_period failed at time %0t", $time);

            bit_cnt     <= bit_cnt - 1;
            if(bit_cnt == 0) begin
                bit_cnt     <= bit_prd_reg;
                bit_strobe  <= 1;
            end
        end
    end
end


always_ff @(posedge clock, posedge reset) begin
    if(reset) begin
        bit_prd_reg <= 1;
        strobe_en   <= 0;
        state       <= uart_trn_pkg::IDLE_STATE;
        TXD         <= 1;
        shifter     <= -1;
        ready       <= 0;
        TXC         <= 0;
    end
    else begin
        if(bit_strobe) begin
            TXD         <= shifter[0];
            shifter     <= {1'b1, shifter[SHIFTER_WIDTH-1:1]};
        end

        // Состояние автомата действует на протяжении передачи бита.
        // Т.е. состояние START_BIT_STATE действует до строба переключения на передачу 0-го бита,
        // а состояние STOP_BIT_STATE действует до конца стопбита, т.е. до окончания транзакции
        case(state)
            uart_trn_pkg::IDLE_STATE: begin
                strobe_en       <= 0;
                bit_prd_reg     <= bit_period;
                ready           <= 1;
                TXD             <= 1;
                if(valid && ready) begin
                    state       <= uart_trn_pkg::START_STATE;
                    strobe_en   <= 1;

                    shifter     <= {-1, din, 1'b0};
                    ready       <= 0;
                    TXC         <= 0;
                end
            end
            //
            uart_trn_pkg::STOP_BIT_STATE:
                if(bit_strobe) begin
                    state       <= uart_trn_pkg::IDLE_STATE;
                    strobe_en   <= 0;
                    TXC         <= 1;
                end
            //
            default: begin
                if(bit_strobe) begin
                    state       <= state + 1;
                    if(state == uart_trn_pkg::STOP_BIT_STATE) begin
                        state   <= uart_trn_pkg::IDLE_STATE;
                        strobe_en   <= 0;
                    end
                end
                // Если сбой работы командного автомата и выход за диапазон допустимых состояний
                assert (state <= uart_trn_pkg::STOP_BIT_STATE)
                    else $error("Error: state = %0d is failed at time %0t", state, $time);
                if(state > uart_trn_pkg::STOP_BIT_STATE) begin
                    state       <= uart_trn_pkg::IDLE_STATE;
                    strobe_en   <= 0;
                    TXD         <= 1;
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

