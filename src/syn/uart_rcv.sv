//-------------------------------------------------------------------------------
//
//     Project: UART
//
//     Purpose: Receiver
//
//-------------------------------------------------------------------------------

//`include "cfg_params.svh"

package uart_rcv_pkg;

    localparam  DATA_WIDTH          = 8;
    //
    typedef logic [DATA_WIDTH-1:0]  data_t;

    localparam STATES_NUM           = DATA_WIDTH + 5;
    localparam STATE_WIDTH          = $clog2(STATES_NUM);
    //
    typedef logic [STATE_WIDTH-1:0] state_t;
    //
    localparam IDLE_STATE           = 0;
    localparam START_BIT_STATE      = 1;
    localparam RCV_BIT0_STATE       = 2;
    localparam RCV_BITn_STATE       = RCV_BIT0_STATE+DATA_WIDTH-1;
    localparam STOP_BIT_STATE       = RCV_BITn_STATE+1;
    localparam DATA_OUT_STATE       = STOP_BIT_STATE+1;
    localparam FINISH_STATE         = DATA_OUT_STATE+1;

endpackage : uart_rcv_pkg



module automatic uart_rcv
#(   parameter CLOCK_FREQ_MHz       = 100
    ,parameter MIN_BAUDRATE_Hz      = 600
    ,localparam BAUDRATE_RATIO      = CLOCK_FREQ_MHz * 1_000_000 / MIN_BAUDRATE_Hz
    ,localparam BIT_PERIOD_WIDTH    = $clog2(BAUDRATE_RATIO)
)
(    input logic    reset
    ,input logic    clock
    ,input logic    enable
    //
    ,input logic[BIT_PERIOD_WIDTH-1:0]  bit_period
    //
    ,output uart_rcv_pkg::state_t       state   = uart_rcv_pkg::IDLE_STATE
    //
    ,input logic                        ready
    ,output uart_rcv_pkg::data_t        dout    = 0
    ,output logic                       valid   = 0
    //
    ,input logic                        RXD         // UART Receive Data - Прием данных (вход)
    ,output logic                       RXC     = 0 // UART Receive Complete - Прием завершен
    ,output logic                       FE      = 0 // UART Framing Error - Ошибка кадра
    ,output logic                       DOR     = 0 // UART Data OverRun - Переполнение данных
);

//------------------------------------------------------------------------------
//
//    Settings
//

//------------------------------------------------------------------------------
//
//    Types
//
typedef logic [BIT_PERIOD_WIDTH-1:0]            bit_period_t;

typedef uart_rcv_pkg::state_t                   state_t;

typedef logic [uart_rcv_pkg::DATA_WIDTH+2:0]    shifter_t;

//------------------------------------------------------------------------------
//
//    Objects
//

logic           strobe_en   = 0;
bit_period_t    bit_prd_reg = 0;
bit_period_t    bit_cnt     = 0;
logic           bit_strobe  = 0;
shifter_t       shifter     = -1;
logic[3:0]      RXdff       = -1;

//------------------------------------------------------------------------------
//
//    Functions and tasks
//
localparam SHIFTER_WIDTH    = uart_trn_pkg::DATA_WIDTH+1;

//------------------------------------------------------------------------------
//
//    Logic
//

always_ff @(posedge clock, posedge reset) begin
    if(reset) begin
        bit_cnt     <= 0;
        bit_strobe  <= 0;
    end
    else begin
        bit_strobe      <= 0;
        if(!strobe_en) begin
            bit_cnt     <= {1'b0, bit_period[BIT_PERIOD_WIDTH-1:1]};
            bit_prd_reg <= bit_period;
        end
        else begin
            assert (bit_period)
                else $error("Error: bit_period failed at time %0t", $time);

            bit_cnt     <= bit_cnt - 1;
            if(bit_cnt == 0) begin
                bit_cnt     <= bit_prd_reg;
                bit_strobe  <= 1;
            end
        end
    end
end


always_ff @(posedge clock, posedge reset)
    if(reset)
        RXdff       <= -1;
    else
        RXdff       <= {RXdff[2:0], RXD};


always_ff @(posedge clock, posedge reset) begin
    if(reset) begin
        bit_prd_reg <= 0;
        strobe_en   <= 0;
        state       <= uart_rcv_pkg::IDLE_STATE;
        shifter     <= -1;
        dout        <= 0;
        valid       <= 0;
        DOR         <= 0;
        FE          <= 0;
        RXC         <= 0;
    end
    else begin
        if(bit_strobe) begin
            shifter     <= {RXdff[1], shifter[SHIFTER_WIDTH-1:1]};
        end

        if(ready && valid) begin                            // данные с выхода должны быть считаны в течение 1 такта
            valid       <= 0;
            DOR         <= 0;                               // сброс флага переполнения данных при чтении данных
        end

        // Состояние автомата действует с середины предыдущего бита и до середины принимаемого бита.
        // Т.е. состояние START_BIT_STATE действует от фронта на линии RX и до середины старбита,
        // состояния RCV_BIT0_STATE действуют с середины стартбита и до середины нулевого бита,
        // а состояние STOP_BIT_STATE действует с середины 7-го бита и до середины стопбита.
        // RX       : < ======== START bit ======== > <  RX_DATA[0]  > <  RX_DATA[1]  >...<  RX_DATA[6]  > <  RX_DATA[7]  > <  STOP bit  >
        // state    : |START_BIT_STATE|    RCV_BIT0_STATE    | RCV_BIT1_STATE |        ...       | RCV_BIT7_STATE | STOP_BIT_STATE |FINISH_STATE
        case(state)
            uart_rcv_pkg::IDLE_STATE: begin
                strobe_en           <= 0;
                bit_prd_reg         <= bit_period;
                if(RXdff == 5'b1100 || RXdff == 0) begin    // нисходящий фронт или низкий уровень
                    state           <= uart_rcv_pkg::START_BIT_STATE;
                    strobe_en       <= 1;
                end
            end
            //
            // Ожидание нисходящего фронта или низкого уровня сигнала
            uart_rcv_pkg::START_BIT_STATE: begin
                if(bit_strobe) begin
                    state           <= uart_rcv_pkg::RCV_BIT0_STATE;
                    if(RXdff != 0) begin    //if(RXdff[1] != 0)
                        state       <= uart_rcv_pkg::IDLE_STATE;
                        strobe_en   <= 0;
                    end
                    RXC             <= 0;
                end
            end
            //
            uart_rcv_pkg::STOP_BIT_STATE:
                if(bit_strobe) begin
                    state           <= uart_rcv_pkg::DATA_OUT_STATE;
                    strobe_en       <= 0;
//                  dout            <= shifter[uart_rcv_pkg::DATA_WIDTH-1:0];
//                  valid           <= 1;
//                  DOR             <= (valid && !ready);   // переполнение данных, когда
                    FE              <= 0;                   // сброс ошибки кадра
                    if(~RXdff)                              // стоповый бит зашумлен или имеет низкий уровень
                        FE          <= 1;                   // ошибка кадра
                end
            //
            uart_rcv_pkg::DATA_OUT_STATE: begin
                state           <= uart_rcv_pkg::FINISH_STATE;
                dout            <= shifter[uart_rcv_pkg::DATA_WIDTH-1:0];
                valid           <= 1;
                DOR             <= (valid && !ready);   // переполнение данных, когда
                                                        // на выходе валидные данные и нет запроса на чтение
            end
            //
            // Ожидание пол периода стопового бита (из-за джиттера можно увеличить до периода)
            uart_rcv_pkg::FINISH_STATE: begin
                strobe_en           <= 1;
                if(bit_strobe || RXdff == 5'b0011 || RXdff == -1) begin   // восходящий фронт или высокий уровень
                    state           <= uart_rcv_pkg::IDLE_STATE;
                    strobe_en       <= 0;
                    RXC             <= 1;
                end
            end
            //
            default: begin
                if(bit_strobe) begin
                    state           <= state + 1;
                end
                // Если сбой работы командного автомата и выход за диапазон допустимых состояний
                assert (state <= uart_rcv_pkg::FINISH_STATE)
                    else $error("Error: bit_period failed at time %0t", $time);
                if(state > uart_rcv_pkg::FINISH_STATE) begin
                    state           <= uart_rcv_pkg::IDLE_STATE;
                    strobe_en       <= 0;
                end
            end
        endcase

        // Если приемник выключен, приём прерывается, флаги не меняются
        if(!enable) begin
            state           <= uart_rcv_pkg::IDLE_STATE;
            strobe_en       <= 0;
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

