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

localparam STATES_NUM      = DATA_WIDTH + 5;
localparam STATE_WIDTH     = $clog2(STATES_NUM);

localparam IDLE_STATE      = 0;
localparam START_BIT_STATE = 1;
localparam RCV_BIT0_STATE  = 2;
localparam RCV_BITn_STATE  = RCV_BIT0_STATE+DATA_WIDTH-1;
localparam STOP_BIT_STATE  = RCV_BITn_STATE+1;
localparam DATA_OUT_STATE  = STOP_BIT_STATE+1;
localparam FINISH_STATE    = DATA_OUT_STATE+1;

//------------------------------------------------------------------------------
//
//    Types
//
typedef logic [SHIFTER_WIDTH-1:0] shifter_t;

typedef logic [  STATE_WIDTH-1:0] state_t;

//------------------------------------------------------------------------------
//
//    Objects
//

state_t      state       = IDLE_STATE;
logic        strobe_en   = 0;
bit_period_t bit_prd_reg = 0;
bit_period_t bit_cnt     = 0;
logic        bit_strobe  = 0;
shifter_t    shifter     = -1;
logic[3:0]   RXdff       = -1;

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
    if(reset) begin
        bit_prd_reg <= 1;
        strobe_en   <= 0;
        state       <= IDLE_STATE;
        shifter     <= -1;
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

        if(ready && valid_reg) begin                        // данные с выхода должны быть считаны в течение 1 такта
            valid_reg <= 0;
            DOR_reg   <= 0;                                 // сброс флага переполнения данных при чтении данных
        end

        // Состояние автомата действует с середины предыдущего бита и до середины принимаемого бита.
        // Т.е. состояние START_BIT_STATE действует от фронта на линии RX и до середины старбита,
        // состояния RCV_BIT0_STATE действуют с середины стартбита и до середины нулевого бита,
        // а состояние STOP_BIT_STATE действует с середины 7-го бита и до середины стопбита.
        // RX       : < ======== START bit ======== > <  RX_DATA[0]  > <  RX_DATA[1]  >...<  RX_DATA[6]  > <  RX_DATA[7]  > <  STOP bit  >
        // state    : |START_BIT_STATE|    RCV_BIT0_STATE    | RCV_BIT1_STATE |        ...       | RCV_BIT7_STATE | STOP_BIT_STATE |FINISH_STATE
        case(state)
            IDLE_STATE: begin
                strobe_en   <= 0;
                bit_prd_reg <= bit_period;
                if(RXdff == 5'b1100 || RXdff == 0) begin    // нисходящий фронт или низкий уровень
                    state     <= START_BIT_STATE;
                    strobe_en <= 1;
                end
            end
            //
            // Ожидание нисходящего фронта или низкого уровня сигнала
            START_BIT_STATE: begin
                if(bit_strobe) begin
                    state          <= RCV_BIT0_STATE;
                    if(RXdff != 0) begin    //if(RXdff[1] != 0)
                        state      <= IDLE_STATE;
                        strobe_en  <= 0;
                    end
                    RXC_reg        <= 0;
                end
            end
            //
            STOP_BIT_STATE:
                if(bit_strobe) begin
                    state     <= DATA_OUT_STATE;
                    strobe_en <= 0;
                    FE_reg    <= 0;                    // сброс ошибки кадра
                    if(~RXdff)                         // стоповый бит зашумлен или имеет низкий уровень
                        FE_reg <= 1;                   // ошибка кадра
                end
            //
            DATA_OUT_STATE: begin
                state     <= FINISH_STATE;
                dout_reg  <= shifter[DATA_WIDTH-1:0];
                valid_reg <= 1;
                DOR_reg   <= (valid_reg && !ready);   // переполнение данных
            end
            //
            // Ожидание пол периода стопового бита (из-за джиттера можно увеличить до периода)
            FINISH_STATE: begin
                strobe_en     <= 1;
                if(bit_strobe || RXdff == 5'b0011 || RXdff == -1) begin   // восходящий фронт или высокий уровень
                    state     <= IDLE_STATE;
                    strobe_en <= 0;
                    RXC_reg   <= 1;
                end
            end
            //
            default: begin
                if(bit_strobe) begin
                    state <= state + 1;
                end
                // Если сбой работы командного автомата и выход за диапазон допустимых состояний
                assert (state <= FINISH_STATE)
                    else $error("Error: state = %0d is failed at time %0t", state, $time);
                if(state > FINISH_STATE) begin
                    state     <= IDLE_STATE;
                    strobe_en <= 0;
                end
            end
        endcase

        // Если приемник выключен, приём прерывается, флаги не меняются
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

