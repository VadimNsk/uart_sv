//-------------------------------------------------------------------------------
//
//     Project: Any
//
//     Purpose: Default top-level file
//
//-------------------------------------------------------------------------------

package uart_pkg;

    typedef struct packed
    {   logic RXC;      // UART Receive Complete - Прием завершен
        logic TXC;      // UART Transmit Complete - Передача завершена
        logic UDRE;     // UART Data Register Empty - Регистр данных пуст
        logic FE;       // UART Framing Error - Ошибка кадра
        logic DOR;      // UART Data OverRun - Переполнение данных
//      logic reserved[2:0];
    } uart_status_t;

    typedef struct packed
    {   logic RXCIE;    // RX Complete Interrupt Enable
        logic TXCIE;    // TX Complete Interrupt Enable
        logic UDRIE;    // UART Data Register Empty Interrupt Enable
        logic RXEN;     // Receiver Enable
        logic TXEN;     // Transmitter Enable
//      logic reserved[2:0];
//      logic CHR9;     // 9 Bit Characters
//      logic RXB8;     // Receive Data Bit 8
//      logic TXB8;     // Transmit Data Bit 8
    } uart_control_t;

endpackage : uart_pkg



module automatic uart
#(   parameter CLOCK_FREQ_MHz       = 100
    ,parameter MIN_BAUDRATE_Hz      = 600
    ,localparam MIN_BAUDRATE_RATIO  = CLOCK_FREQ_MHz * 1_000_000 / MIN_BAUDRATE_Hz
    ,localparam BIT_PERIOD_WIDTH    = $clog2(MIN_BAUDRATE_RATIO)
)
(    input logic        reset
    ,input logic        clock
    // UART
    ,input logic[BIT_PERIOD_WIDTH-1:0]      bit_period
    ,input wire uart_pkg::uart_control_t    control
    ,output uart_pkg::uart_status_t         status
    ,output logic                           TXCI            // TX Complete Interrupt
    ,output logic                           RXCI            // RX Complete Interrupt
    ,output logic                           UDRI            // Data Register Empty Interrupt
    //
    ,output logic                       tx_ready
    ,input uart_trn_pkg::data_t         tx_din
    ,input logic                        tx_valid
    //
    ,input logic                        rx_ready
    ,output uart_rcv_pkg::data_t        rx_dout
    ,output logic                       rx_valid
    //
    ,output logic                           TX              // UART Transmit Data
    ,input logic                            RX              // UART Receive Data
);

//------------------------------------------------------------------------------
//
//    Settings
//

//------------------------------------------------------------------------------
//
//    Types
//
typedef logic [BIT_PERIOD_WIDTH-1:0]    bit_count_t;
typedef uart_trn_pkg::data_t            data_t;

//------------------------------------------------------------------------------
//
//    Objects
//

//uart_trn_pkg::state_t   tx_state;
//uart_rcv_pkg::state_t   rx_state;

data_t  tx_UDR;         // UART I/O Data Register
logic tx_UDR_valid;
data_t  rx_UDR;         // UART I/O Data Register
logic rx_UDR_valid;

logic                   uart_trn_enable;
logic                   uart_trn_ready;
uart_trn_pkg::data_t    uart_trn_din;
logic                   uart_trn_valid;
logic                   uart_trn_TXC;
logic                   prev_UDR_valid;

logic                   uart_rcv_ready;
uart_rcv_pkg::data_t    uart_rcv_dout;
logic                   uart_rcv_valid;
logic                   uart_rcv_DOR;
logic                   uart_rcv_RXC;

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
/*
initial begin
    status      = '{default:0};
    TXCI        = 0;    // TX Complete Interrupt
    RXCI        = 0;    // RX Complete Interrupt
    UDRI        = 0;    // Data Register Empty Interrupt
    //
    tx_ready    = 0;
    //
    rx_dout     = 0;
    rx_valid    = 0;
    //
    TX          = 0;    // UART Transmit Data
end
*/

always_comb begin
    tx_ready            <= ~tx_UDR_valid && uart_trn_enable;
end

always_ff @(posedge clock, posedge reset) begin
    if(reset) begin
        tx_UDR          <= 0;       // UART I/O Data Register
        tx_UDR_valid    <= 0;
        //
        uart_trn_enable <= 0;
        uart_trn_din    <= 0;
        uart_trn_valid  <= 0;
        //
        TXCI            <= 0;       // TX Complete Interrupt
        uart_trn_TXC    <= 0;
        //
        status.UDRE     <= 0;       // UART Data Register Empty
        UDRI            <= 0;       // Data Register Empty Interrupt
        prev_UDR_valid  <= 0;
    end
    else begin
        TXCI            <= 0;       // TX Complete Interrupt
        uart_trn_TXC    <= status.TXC;
        if({uart_trn_TXC, status.TXC} == 2'b01 && control.TXCIE)
            TXCI        <= 1;       // TX Complete Interrupt

        UDRI            <= 0;       // Data Register Empty Interrupt
        prev_UDR_valid  <= tx_UDR_valid;
        if({prev_UDR_valid, tx_UDR_valid} == 2'b10 && control.UDRIE)
            UDRI        <= 1;       // Data Register Empty Interrupt

        // Включение передатчика в любое время.
        if(!uart_trn_enable)
            uart_trn_enable         <= control.TXEN;    // Transmitter Enable

        // Выключение после передачи текущего буфера и уже передаваемого
        if(uart_trn_ready && uart_trn_valid)
            uart_trn_valid          <= 0;
        if(uart_trn_enable) begin
            // Загрузка данных со входа, если есть возможность
            if(uart_trn_ready) begin
                uart_trn_enable     <= control.TXEN;    // Transmitter Enable
                if(tx_UDR_valid) begin
                    uart_trn_din    <= tx_UDR;
                    uart_trn_valid  <= tx_UDR_valid;
                    tx_UDR_valid    <= 0;
                end
            end
            if(tx_valid && !tx_UDR_valid) begin
                tx_UDR          <= tx_din;
                tx_UDR_valid    <= tx_valid;
            end
            status.UDRE         <= !(tx_UDR_valid || tx_valid); // UART Data Register Empty
        end
    end
end


always_comb begin
    rx_dout     <= rx_UDR;
    rx_valid    <= rx_UDR_valid;
end

always_ff @(posedge clock, posedge reset) begin
    if(reset) begin
        rx_UDR          <= 0;       // UART I/O Data Register
        rx_UDR_valid    <= 0;
        //
        uart_rcv_ready  <= 0;
        //
        status.DOR      <= 0;       // UART Data OverRun
        //
        uart_rcv_RXC    <= 0;
        RXCI            <= 0;       // RX Complete Interrupt
    end
    else begin
        RXCI            <= 0;
        uart_rcv_RXC    <= status.RXC;
        if({uart_rcv_RXC, status.RXC} == 2'b01 && control.RXCIE)
            RXCI        <= 1;       // RX Complete Interrupt

        uart_rcv_ready  <= 1;

        if(rx_ready && rx_UDR_valid) begin      // данные с выхода должны быть считаны в течение 1 такта
            rx_UDR_valid        <= 0;
            status.DOR          <= 0;           // сброс флага переполнения данных при чтении данных
        end

        if(uart_rcv_valid) begin
            rx_UDR              <= uart_rcv_dout;
            rx_UDR_valid        <= 1;
            status.DOR          <= uart_rcv_DOR;
            if(rx_UDR_valid && !rx_ready) begin
                status.DOR      <= 1;
            end
        end
    end
end

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
//      ,.enable(uart_trn_enable)   // Transmitter Enable
        //
        ,.bit_period(bit_period)
//      ,.state(tx_state)
        //
        ,.ready(uart_trn_ready)
        ,.din(uart_trn_din)
        ,.valid(uart_trn_valid)
        //
        ,.TXD(TX)                   // UART Transmit Data
        ,.TXC(status.TXC)           // UART Transmit Complete
        );


uart_rcv
    #(   .CLOCK_FREQ_MHz(CLOCK_FREQ_MHz)
        ,.MIN_BAUDRATE_Hz(MIN_BAUDRATE_Hz)
        )
    rcv_inst
    (    .reset(reset)
        ,.clock(clock)
        ,.enable(control.RXEN)      // Receiver Enable
        //
        ,.bit_period(bit_period)
//      ,.state(rx_state)
        //
        ,.ready(uart_rcv_ready)
        ,.dout(uart_rcv_dout)
        ,.valid(uart_rcv_valid)
        //
        ,.RXD(RX)                   // UART Receive Data
        ,.RXC(status.RXC)           // UART Receive Complete
        ,.FE(status.FE)             // UART Framing Error
        ,.DOR(uart_rcv_DOR)         // UART Data OverRun
        );

//------------------------------------------------------------------------------

//-------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------

