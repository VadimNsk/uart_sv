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
        @(posedge drv.clock);
        tx_valid = 1'b0;
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

        while(1) begin
            err = 0;
            wait(TX == 1'b0);
            #(TEST_BIT_PERIOD / 2);
            for (int i = 0; i < STARTBIT_WIDTH; i = i+1) begin
                if(TX != 0) begin
                    err = 1;
                    break;
                end
                #TEST_BIT_PERIOD;
            end
            if(err) begin
                err = 0;
                continue;
            end
            for(int i = 0; i < DATA_WIDTH; i = i+1) begin
                data[i] = TX;
                #TEST_BIT_PERIOD;
            end
            for (int i = 0; i < STOPBIT_WIDTH; i = i+1) begin
                if(TX != 1'b1) begin
                    err = 1;
                    break;
                end
                #TEST_BIT_PERIOD;
            end
            valid   = !err;
            break;
        end;
    endtask

    // RX data read task
    task automatic read_rx_data(output data_t data);
        rx_ready = 1'b1;
        wait(rx_valid == 1'b1);
        data     = rx_dout;
        @(posedge clock);
        rx_ready = 1'b0;
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
    task automatic wait_for_tx_complete();
        wait(dut.status.TXC);
        @(posedge dut.clock);
    endtask

    // Wait for RX complete interrupt
    task automatic wait_for_rx_complete();
        wait(dut.status.RXC);
        @(posedge dut.clock);
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

