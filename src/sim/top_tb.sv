//-------------------------------------------------------------------------------
//
//     Project: Any
//
//     Purpose: Default testbench file
//
//-------------------------------------------------------------------------------

`include "cfg_params.svh"
//`include "uart_wrapper_wif.sv"
`include "uart.sv"
`include "uart_if.sv"
`include "testcase.sv"

`timescale 1ns/1ps

module top_tb;

import uart_pkg::*;

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
logic clk = 0;
logic rst = 1;

uart_if uart_if0(clk, rst);

testcase TC (uart_if0.drv, uart_if0.rcv);


//------------------------------------------------------------------------------
//
//    Functions and tasks
//

//------------------------------------------------------------------------------
//
//    Logic
//

always #(CLOCK_PERIOD_ns/2) clk = ~clk;


//data_t readed;
//logic valid;

initial begin
    rst = 1;
    uart_if0.bit_period = get_bit_period(TEST_BAUDRATE);    // 192000
    uart_if0.control    = '{TXEN     : 0,
                            RXEN     : 0,
                            TXCIE    : 0,
                            RXCIE    : 0,
                            TXDREIE  : 0,
                            RXDRNEIE : 0};
    uart_if0.tx_din     = 0;
    uart_if0.tx_valid   = 0;
    uart_if0.rx_ready   = 0;
    uart_if0.RX         = 1;


    rst = 1;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    rst = 0;
    @(posedge clk);
/*
    fork
        uart_if0.write_tx_data(8'h55);
        uart_if0.receive_tx_data(readed, valid);
    join
    uart_if0.wait_for_tx_complete();

    uart_if0.transmit_rx_data(8'hAA);
    uart_if0.wait_for_rx_complete();
    uart_if0.read_rx_data(readed);
*/
//  #10us
//  $display("\n%c[1;32m ******************** SIMULATION RUN FINISHED SUCCESSFULLY ********************%c[0m", 27, 27);
//  $stop(2);
end


//------------------------------------------------------------------------------
//
//    Instances
//

//uart_wrapper_wif uart_inst (
//    .uif        ( uart_if0  )
//    );

uart    uart_inst
(    .reset      ( uart_if0.reset      )
    ,.clock      ( uart_if0.clock      )
    // UART
    ,.bit_period ( uart_if0.bit_period )
    ,.control    ( uart_if0.control    )
    ,.status     ( uart_if0.status     )
    ,.TXCI       ( uart_if0.TXCI       )    // TX Complete Interrupt
    ,.RXCI       ( uart_if0.RXCI       )    // RX Complete Interrupt
    ,.TXDREI     ( uart_if0.TXDREI     )    // TX Data Register Empty Interrupt
    ,.RXDRNEI    ( uart_if0.RXDRNEI    )    // RX Data Register Not Empty Interrupt
    //
    ,.tx_ready   ( uart_if0.tx_ready   )
    ,.tx_din     ( uart_if0.tx_din     )
    ,.tx_valid   ( uart_if0.tx_valid   )
    //
    ,.rx_ready   ( uart_if0.rx_ready   )
    ,.rx_dout    ( uart_if0.rx_dout    )
    ,.rx_valid   ( uart_if0.rx_valid   )
    //
    ,.TX         ( uart_if0.TX         )    // UART Transmit Data
    ,.RX         ( uart_if0.RX         )    // UART Receive Data
);

endmodule
//-------------------------------------------------------------------------------

