//-------------------------------------------------------------------------------
//
//     Project: Any
//
//     Purpose: Default top-level file
//
//-------------------------------------------------------------------------------

`include "uart_pkg.svh"


module automatic uart
    import uart_pkg::*;
(   input logic              reset,
    input logic              clock,
    // UART
    input bit_period_t       bit_period,
    input var uart_control_t control,
    output uart_status_t     status,
    output logic             TXCI,            // TX Complete Interrupt
    output logic             RXCI,            // RX Complete Interrupt
    output logic             UDRI,            // Data Register Empty Interrupt
    //
    output logic             tx_ready,
    input data_t             tx_din,
    input logic              tx_valid,
    //
    input logic              rx_ready,
    output data_t            rx_dout,
    output logic             rx_valid,
    //
    output logic             TX,              // UART Transmit Data
    input logic              RX               // UART Receive Data
);

//------------------------------------------------------------------------------
//
//    Settings
//

//------------------------------------------------------------------------------
//
//    Types
//

//------------------------------------------------------------------------------
//
//    Objects
//

data_t tx_UDR;                 // UART I/O Data Register
logic  tx_UDR_valid;
data_t rx_UDR;                 // UART I/O Data Register
logic  rx_UDR_valid;

logic  uart_trn_enable;
logic  uart_trn_ready;
data_t uart_trn_din;
logic  uart_trn_valid;
logic  uart_trn_TXC_prev;
logic  prev_UDR_valid;

logic  uart_rcv_ready;
data_t uart_rcv_dout;
logic  uart_rcv_valid;
logic  uart_rcv_DOR;
logic  uart_rcv_RXC;

logic  status_UDRE       = 0;  // UART Data Register Empty
logic  status_DOR        = 0;  // UART Data OverRun
logic  TXCI_reg          = 0;  // TX Complete Interrupt
logic  RXCI_reg          = 0;  // RX Complete Interrupt
logic  UDRI_reg          = 0;  // Data Register Empty Interrupt
logic  tx_ready_reg      = 0;
data_t rx_dout_reg       = 0;
logic  rx_valid_reg      = 0;

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

assign status.UDRE = status_UDRE;   // UART Data Register Empty
assign status.DOR  = status_DOR;    // UART Data OverRun
assign TXCI        = TXCI_reg;      // TX Complete Interrupt
assign RXCI        = RXCI_reg;      // RX Complete Interrupt
assign UDRI        = UDRI_reg;      // Data Register Empty Interrupt
assign tx_ready    = tx_ready_reg;
assign rx_dout     = rx_dout_reg;
assign rx_valid    = rx_valid_reg;


always_comb begin
    tx_ready_reg <= ~tx_UDR_valid && uart_trn_enable;
end

always_ff @(posedge clock, posedge reset) begin
    if(reset) begin
        tx_UDR            <= 0;       // UART I/O Data Register
        tx_UDR_valid      <= 0;
        //
        uart_trn_enable   <= 0;
        uart_trn_din      <= 0;
        uart_trn_valid    <= 0;
        //
        TXCI_reg          <= 0;       // TX Complete Interrupt
        uart_trn_TXC_prev <= 0;
        //
        status_UDRE       <= 0;       // UART Data Register Empty
        UDRI_reg          <= 0;       // Data Register Empty Interrupt
        prev_UDR_valid    <= 0;
    end
    else begin
        // detecting the signal edge
        TXCI_reg          <= 0;       // TX Complete Interrupt
        uart_trn_TXC_prev <= status.TXC;
        if(({uart_trn_TXC_prev, status.TXC} == 2'b01) && control.TXCIE)
        begin
            TXCI_reg <= 1;            // TX Complete Interrupt
        end

        // detecting the signal edge
        UDRI_reg       <= 0;          // Data Register Empty Interrupt
        prev_UDR_valid <= tx_UDR_valid;
        if(({prev_UDR_valid, tx_UDR_valid} == 2'b10) && control.UDRIE)
        begin
            UDRI_reg <= 1;            // Data Register Empty Interrupt
        end

        if(uart_trn_ready && uart_trn_valid) begin
            uart_trn_valid <= 0;
        end
        
        if(!uart_trn_enable) begin
            uart_trn_enable <= control.TXEN;        // Transmitter Enable
        end
        else begin
            if(uart_trn_ready) begin
                uart_trn_enable <= control.TXEN;    // Transmitter Enable
                if(tx_UDR_valid) begin
                    uart_trn_din   <= tx_UDR;
                    uart_trn_valid <= tx_UDR_valid;
                    tx_UDR_valid   <= 0;
                end
            end
            
            if(tx_valid && !tx_UDR_valid) begin
                tx_UDR       <= tx_din;
                tx_UDR_valid <= tx_valid;
            end
            status_UDRE <= !(tx_UDR_valid || tx_valid); // UART Data Register Empty
        end
    end
end


always_comb begin
    rx_dout_reg  <= rx_UDR;
    rx_valid_reg <= rx_UDR_valid;
end

always_ff @(posedge clock, posedge reset) begin
    if(reset) begin
        rx_UDR         <= 0;        // UART I/O Data Register
        rx_UDR_valid   <= 0;
        //
        uart_rcv_ready <= 0;
        //
        status_DOR     <= 0;        // UART Data OverRun
        //
        uart_rcv_RXC   <= 0;
        RXCI_reg       <= 0;        // RX Complete Interrupt
    end
    else begin
        uart_rcv_ready  <= 1;

        // detecting the signal edge
        RXCI_reg     <= 0;
        uart_rcv_RXC <= status.RXC;
        if({uart_rcv_RXC, status.RXC} == 2'b01 && control.RXCIE)
            RXCI_reg <= 1;          // RX Complete Interrupt

        // the data from the output must be read within 1 clock cycle
        if(rx_ready && rx_UDR_valid) begin
            rx_UDR_valid <= 0;
            status_DOR   <= 0;      // resetting the data overflow flag when reading data
        end

        if(uart_rcv_valid) begin
            rx_UDR              <= uart_rcv_dout;
            rx_UDR_valid        <= 1;
            status_DOR          <= uart_rcv_DOR;
            if(rx_UDR_valid && !rx_ready) begin
                status_DOR      <= 1;
            end
        end
    end
end

//------------------------------------------------------------------------------
//
//    Instances
//

uart_trn    trn_inst
(   .reset          ( reset          ),
    .clock          ( clock          ),
    //
    .bit_period     ( bit_period     ),
    //
    .ready          ( uart_trn_ready ),
    .din            ( uart_trn_din   ),
    .valid          ( uart_trn_valid ),
    //
    .TXD            ( TX             ),     // UART Transmit Data
    .TXC            ( status.TXC     )      // UART Transmit Complete
    );


uart_rcv    rcv_inst
(   .reset          ( reset          ),
    .clock          ( clock          ),
    .enable         ( control.RXEN   ),     // Receiver Enable
    //
    .bit_period     ( bit_period     ),
    //
    .ready          ( uart_rcv_ready ),
    .dout           ( uart_rcv_dout  ),
    .valid          ( uart_rcv_valid ),
    //
    .RXD            ( RX             ),                  // UART Receive Data
    .RXC            ( status.RXC     ),          // UART Receive Complete
    .FE             ( status.FE      ),            // UART Framing Error
    .DOR            ( uart_rcv_DOR   )         // UART Data OverRun
    );

//------------------------------------------------------------------------------

//-------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------

