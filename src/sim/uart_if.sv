//-------------------------------------------------------------------------------
//
//     Project: UART
//
//     Purpose: UART interface
//
//-------------------------------------------------------------------------------


`ifndef UART_IF_SV
    `define UART_IF_SV

`include "uart_pkg.svh"
import uart_pkg::*;

interface uart_if (input logic clock, input logic reset);

    // Timing parameters
    bit_period_t bit_period;

    // Control and status signals
    control_t    control;
    status_t     status;

    // Interrupt signals
    logic        TXCI;          // TX Complete Interrupt
    logic        RXCI;          // RX Complete Interrupt
    logic        TXDREI;        // TX Data Register Empty Interrupt
    logic        RXDRNEI;       // RX Data Register Not Empty Interrupt

    // TX FIFO interface
    logic        tx_ready;
    data_t       tx_din;
    logic        tx_valid;

    // RX FIFO interface
    logic        rx_ready;
    data_t       rx_dout;
    logic        rx_valid;

    // UART physical interface
    logic        TX;            // UART Transmit Data
    logic        RX;            // UART Receive Data


    // Modport for DUT (Device Under Test)
    modport dut (
        input   reset,
        input   clock,
        // UART configuration
        input   bit_period,
        input   control,
        output  status,
        // Interrupts
        output  TXCI,
        output  RXCI,
        output  TXDREI,
        output  RXDRNEI,
        // TX interface
        output  tx_ready,
        input   tx_din,
        input   tx_valid,
        // RX interface
        input   rx_ready,
        output  rx_dout,
        output  rx_valid,
        // Physical interface
        output  TX,
        input   RX
    );


    // TX data write task
    task automatic write_tx_data(input data_t data);
        wait(tx_ready == 1'b1);
        tx_din   = data;
        tx_valid = 1'b1;
        @(posedge clock);
        tx_valid = 1'b0;
        @(posedge clock);
    endtask

    // TX data transmit to RX task
    task automatic transmit_data_to_rx(input data_t data);
        for (int i = 0; i < STARTBIT_WIDTH; i = i+1) begin
            RX = 0;    // start-bit
            #TEST_BIT_PERIOD;
        end
        for (int i = 0; i < DATA_WIDTH; i = i+1) begin
            RX = data[i];
            #TEST_BIT_PERIOD;
        end
        for (int i = 0; i < STOPBIT_WIDTH; i = i+1) begin
            RX = 1;    // stop-bit
            #TEST_BIT_PERIOD;
        end
    endtask

    // RX data receive from TX task
    task automatic receive_data_from_tx(output data_t data, output logic valid);
        logic err;
//      $display(" %0d :  uart_if  : start of receive_data_from_tx() method",$time);

        while(1) begin
            err = 0;
            wait(TX == 1'b0);
            #(TEST_BIT_PERIOD / 2);
            for (int i = 0; i < STARTBIT_WIDTH; i = i+1) begin
//              $display(" %0d :  uart_if  : Start bit",$time);
                if(TX != 0) begin
                    $display(" %0d :  uart_if  : Start bit is failed",$time);
                    err = 1;
                end
                #TEST_BIT_PERIOD;
            end
            if(err) begin
                err = 0;
                continue;
            end
            for(int i = 0; i < DATA_WIDTH; i = i+1) begin
//              $display(" %0d :  uart_if  : data[%d] = %d",$time, i, TX);
                data[i] = TX;
                #TEST_BIT_PERIOD;
            end
            for (int i = 0; i < STOPBIT_WIDTH; i = i+1) begin
//              $display(" %0d :  uart_if  : Stop bit",$time);
                if(TX != 1'b1) begin
                    $display(" %0d :  uart_if  : Stop bit is failed",$time);
                    err = 1;
                end
                if(i < STOPBIT_WIDTH-1)
                    #(TEST_BIT_PERIOD);
                else
                    #(TEST_BIT_PERIOD / 2 - 10);    // a short distance from the end
            end
            valid   = !err;
            if(err) begin
                err = 0;
                continue;
            end
            break;
        end;
    endtask

    // RX data read task
    task automatic read_rx_data(output data_t data, input logic stop);
        rx_ready = 1'b1;
        wait(rx_valid == 1'b1 || stop);
        if(!stop) begin
            data     = rx_dout;
            @(posedge clock);
            rx_ready = 1'b0;
            @(posedge clock);
        end
    endtask

    // Check if TX is ready
    function bit is_tx_ready();
        return tx_ready;
    endfunction

    // Check if RX has data
    function bit is_rx_data_available();
        return rx_valid;
    endfunction

    // Set UART configuration
    task automatic configure_uart(input bit_period_t baud_period,
                                    input control_t  ctrl);
        dut.bit_period <= baud_period;
        dut.control    <= ctrl;
    endtask

    // Wait for TX complete interrupt
    task automatic wait_for_tx_complete(input logic stop);
        wait(dut.status.TXC || stop);   // the stop signal did not lead to a stop
    endtask

    // Wait for RX complete interrupt
    task automatic wait_for_rx_complete(input logic stop);
        wait(dut.status.RXC || stop);   // the stop signal did not lead to a stop
    endtask


    // Modport for driver
    modport drv (
        input   reset,
        input   clock,
        // UART configuration
        input   bit_period,
        input   control,
        output  status,
        // TX interface
        output  tx_ready,
        input   tx_din,
        input   tx_valid,
        // Physical interface
        input   RX,
        //
        import write_tx_data,
        import transmit_data_to_rx,
        import wait_for_tx_complete
    );

    // Modport for reveiver
    modport rcv (
        input   reset,
        input   clock,
        // UART configuration
        input   bit_period,
        input   control,
        output  status,
        // RX interface
        input   rx_ready,
        output  rx_dout,
        output  rx_valid,
        // Physical interface
        output  TX,
        //
        import receive_data_from_tx,
        import wait_for_rx_complete,
        import read_rx_data
    );

endinterface

`endif //UART_IF_SV

