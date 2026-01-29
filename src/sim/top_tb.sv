//-------------------------------------------------------------------------------
//
//     Project: Any
//
//     Purpose: Default testbench file
//
//-------------------------------------------------------------------------------

`include "cfg_params.svh"

`timescale 1ns/1ps

module top_tb;

//------------------------------------------------------------------------------
//
//    Settings
//
localparam int CLOCK_FREQ_MHz   = `REF_CLK;
localparam int MIN_BAUDRATE_Hz  = 600;

localparam int CLOCK_PERIOD_ns  = 1_000 / CLOCK_FREQ_MHz;

localparam int BAUDRATE_RATIO   = CLOCK_FREQ_MHz * 1_000_000 / MIN_BAUDRATE_Hz;
localparam int BIT_PERIOD_WIDTH = $clog2(BAUDRATE_RATIO);

localparam int TEST_BAUDRATE    = 192_000;
localparam int TEST_BIT_PERIOD  = 1_000_000_000 / TEST_BAUDRATE;
localparam int TEST_ARRAY_SIZE  = 10;

//------------------------------------------------------------------------------
//
//    Types
//
typedef logic [BIT_PERIOD_WIDTH-1:0]    bit_period_t;
typedef uart_trn_pkg::data_t            data_t;
typedef data_t [0:TEST_ARRAY_SIZE-1]    test_array_t;

//------------------------------------------------------------------------------
//
//    Objects
//
logic clk = 0;
logic rst = 1;


// UART
logic[BIT_PERIOD_WIDTH-1:0]     bit_period  = 1;
uart_pkg::uart_control_t        control     = '{default:0};
uart_pkg::uart_status_t         status;
logic                           TXCI;       // TX Complete Interrupt
logic                           RXCI;       // RX Complete Interrupt
logic                           UDRI;       // Data Register Empty Interrupt
//
logic                           tx_ready;
uart_trn_pkg::data_t            tx_din      = 0;
logic                           tx_valid    = 0;
//
logic                           rx_ready    = 0;
uart_rcv_pkg::data_t            rx_dout;
logic                           rx_valid;
//
logic                           TX;         // UART Transmit Data
logic                           RX = 1;     // UART Receive Data

test_array_t                    src_data;
test_array_t                    dst_data;

int trn_tx_counter  = 0;
int trn_txc_counter = 0;
int rcv_tx_counter  = 0;
bit trn_tx_done     = 0;
bit trn_txc_done    = 0;
bit rcv_tx_done     = 0;

bit bit_strobe      = 0;

int trn_rx_counter  = 0;
int rcv_rx_counter  = 0;
int rcv_rxc_counter = 0;
bit trn_rx_done     = 0;
bit rcv_rx_done     = 0;
bit rcv_rxc_done    = 0;


//------------------------------------------------------------------------------
//
//    Functions and tasks
//
function bit_period_t get_bit_period (input int baudrate);
begin
    get_bit_period = CLOCK_FREQ_MHz * 1_000_000 / baudrate;
end
endfunction


//------------------------------------------------------------------------------
//
//    Logic
//
/*
initial begin
    clk     = 0;
    forever begin
        #(CLOCK_PERIOD_ns/2)
        clk = ~clk;
    end
end

initial begin
    rst     = 1;
    @(posedge clk);
    @(posedge clk);
    rst     = 0;
end
*/

task trn_tx_data(input test_array_t din, output int counter, output done);
    done    = 0;
    counter = 0;

    $display("Transmit data...");

    for (int i = 0; i < TEST_ARRAY_SIZE; i = i+1) begin
        do @(posedge clk);
        while(!tx_ready);

        if(tx_valid)
            tx_valid    = 0;
        tx_din          = din[i];
        tx_valid        = 1;
        counter         = counter + 1;
        $display("%0d. transmit data[%2d] = %d", counter, i, din[i]);
    end
    @(posedge status.TXC);
//  wait(status.TXC);
//  do @(posedge clk);
//  while(!status.TXC);

    done    = 1;
endtask


task trn_txc_count(input int number, output int counter, output done);
    done    = 0;
    counter = 0;

    for (int i = 0; i < number; i = i+1) begin
        @(posedge status.TXC);
        counter     = counter + 1;
        $display("%2d. transmit data completed", counter);
    end
//  wait(status.TXC);
//  do @(posedge clk);
//  while(!status.TXC);

    done    = 1;
endtask


data_t data = 0;

task rcv_tx_data(output test_array_t dout, output int counter, output done);
    done        = 0;
    counter     = 0;
    bit_strobe  = 0;

    $display("Reseive data...");

    for (int i = 0; i < TEST_ARRAY_SIZE; i = i+1) begin
        @(negedge TX);
        #(TEST_BIT_PERIOD / 2);
        if(TX != 0) begin
            $error("Error detecting start bit");
            continue;
        end
        bit_strobe      = 1;
        bit_strobe      = #10ns 0;
        data = 0;
        for(int j = 0; j < 8; j = j + 1) begin
            #TEST_BIT_PERIOD;
            if(TX)
                data[j] = 1;
            bit_strobe  = 1;
            bit_strobe  = #10ns 0;
        end
        #TEST_BIT_PERIOD;
        bit_strobe      = 1;
        bit_strobe      = #10ns 0;
        if(TX != 1) begin
            $error("Error detecting stop bit");
            continue;
        end
//      #(TEST_BIT_PERIOD / 2);
        dout[i]         = data;
        counter         = counter + 1;
        $display("%4d. reseive data = %d", counter, data);
    end

    done    = 1;
endtask


task trn_rx_data(input test_array_t din, output int counter, output done);
    done    = 0;
    counter = 0;
    RX      = 1;

    $display("Transmit data...");

    for (int i = 0; i < TEST_ARRAY_SIZE; i = i+1) begin
        RX          = 0;    // start-bit
        #TEST_BIT_PERIOD;
        for (int j = 0; j < 8; j = j+1) begin
            RX  = (din[i] & (1 << j)) ? 1 : 0;
            #TEST_BIT_PERIOD;
        end
        RX          = 1;    // stop-bit
        #TEST_BIT_PERIOD;
        counter     = counter + 1;
        $display("%0d. transmit data[%2d] = %d", counter, i, din[i]);
    end
    RX      = 1;
    done    = 1;
endtask


task rcv_rx_data(output test_array_t dout, output int counter, output done);
    done    = 0;
    counter = 0;

    $display("Reseive data...");

    for (int i = 0; i < TEST_ARRAY_SIZE; i = i+1) begin
        do @(posedge clk);
        while(!rx_valid);

        rx_ready        = 1;
        @(posedge clk);
        rx_ready        = 0;
        dout[i]         = rx_dout;
        @(posedge clk);
        counter         = counter + 1;
        $display("%2d. reseive data[%2d] = %d", counter, i, dout[i]);
    end

    done    = 1;
endtask


task rcv_rxc_count(input int number, output int counter, output done);
    done    = 0;
    counter = 0;

    for (int i = 0; i < number; i = i+1) begin
        @(posedge status.RXC);
        counter     = counter + 1;
        $display("%4d. reseive data completed", counter);
    end
//  wait(status.TXC);
//  do @(posedge clk);
//  while(!status.TXC);

    done    = 1;
endtask


always #(CLOCK_PERIOD_ns/2) clk = ~clk;

initial begin
    bit_period      = 0;
    //
    control.TXEN    = 0;
    control.RXEN    = 0;
    control.TXCIE   = 0;
    control.RXCIE   = 0;
    control.UDRIE   = 0;
    //
    RX              = 1;
    //
    tx_din          = 0;
    tx_valid        = 0;
    rx_ready        = 0;
    //
    for (int i = 0; i < TEST_ARRAY_SIZE; i = i+1) begin
        src_data[i] = i+1;
        dst_data[i] = 0;
    end

//  rst     = 1;
    @(posedge clk);
    @(posedge clk);
    rst     = 0;
    @(posedge clk);
    @(posedge clk);


    $display("\n\n>>>>>>>>>>>>>>>+<<<<<<<<<<<<<<<<<<<");
    $display(">>> ======== Test  TR ======== <<<<");
    $display(">>>>>>>>>>>>>>>+<<<<<<<<<<<<<<<<<<<\n");

    bit_period      = get_bit_period(TEST_BAUDRATE);    // 192000
    control.TXEN    = 1;
    control.RXEN    = 0;

    @(posedge clk);

    fork
        trn_tx_data(src_data, trn_tx_counter, trn_tx_done);
        trn_txc_count($size(src_data), trn_txc_counter, trn_txc_done);
        rcv_tx_data(dst_data, rcv_tx_counter, rcv_tx_done);
    join
    wait(trn_tx_done && rcv_tx_done && trn_txc_done);
    $display("\nCompleted at time = %0t", $time);
    $display("Transmited %0d(%0d), reseived %0d", trn_tx_counter, trn_txc_counter, rcv_tx_counter);

    for (int i = 0; i < TEST_ARRAY_SIZE; i = i+1) begin
        if(src_data[i] != dst_data[i])
            $error("%d. transmit data[%2d] = %dm but reseived data = ", i+1, i, src_data[i], dst_data[i]);
    end
    $display("Data comparison completed\n");
    @(posedge clk);


    $display("\n\n>>>>>>>>>>>>>>>+<<<<<<<<<<<<<<<<<<<");
    $display(">>> ======== Test  RC ======== <<<<");
    $display(">>>>>>>>>>>>>>>+<<<<<<<<<<<<<<<<<<<\n");

    bit_period      = get_bit_period(TEST_BAUDRATE);    // 192000
    control.TXEN    = 0;
    control.RXEN    = 1;
    RX              = 1;

    @(posedge clk);

    fork
        trn_rx_data(src_data, trn_rx_counter, trn_rx_done);
        rcv_rx_data(dst_data, rcv_rx_counter, rcv_rx_done);
        rcv_rxc_count($size(src_data), rcv_rxc_counter, rcv_rxc_done);
    join
    wait(trn_rx_done && rcv_rx_done && rcv_rxc_done);
    $display("\nCompleted at time = %0t", $time);
    $display("Transmited %0d, reseived %0d(%0d)", trn_rx_counter, rcv_rx_counter, rcv_rxc_counter);

    for (int i = 0; i < TEST_ARRAY_SIZE; i = i+1) begin
        if(src_data[i] != dst_data[i])
            $error("%d. transmit data[%2d] = %dm but reseived data = ", i+1, i, src_data[i], dst_data[i]);
    end
    $display("Data comparison completed\n");
    @(posedge clk);

    #10us
    $display("\n%c[1;32m ******************** SIMULATION RUN FINISHED SUCCESSFULLY ********************%c[0m", 27, 27);
    $stop(2);
end 

/*
always_ff @(posedge clk) begin
    rst         <= 1;
    rst_counter <= rst_counter - 1;
    if(rst_counter == 0) begin
        rst_counter     <= 0;
        rst             <= 0;
    end
end
*/
/*
always_ff @(posedge clk, posedge rst) begin
    if(rst) begin
        for (int i = 0; i < 10; i = i+1) begin
            src_data[i] = i;
            dst_data[i] = 0;
        end
        tx_counter      = 0;
        rx_counter      = 0;
        //
        bit_period      = 0;
        control.TXEN    = 0;
        control.RXEN    = 0;
        control.TXCIE   = 0;
        control.RXCIE   = 0;
        control.UDRIE   = 0;
        //
        tx_din          <= 0;
        tx_valid        <= 0;
        //
        rx_ready        <= 0;
    end
    else begin
        bit_period      = get_bit_period(192000);
        control.TXEN    = 1;
        control.RXEN    = 1;
        //
        if(tx_valid && tx_ready)
            tx_valid    <= 0;
        else if(tx_counter < 10 && tx_ready) begin
            tx_din      <= src_data[tx_counter];
            tx_valid    <= 1;
            //
            tx_counter  <= tx_counter + 1;
        end
        else if(tx_counter >= 10)
            $stop();
        //
        rx_ready        <= 0;
        if(rx_counter < 10) begin
            rx_ready    <= 1;
            if(rx_valid) begin
                dst_data[rx_counter]    <= rx_dout;
                //
                rx_counter              <= rx_counter + 1;
            end
        else if(rx_counter >= 10)
            $stop();
        end
    end
end
*/

//------------------------------------------------------------------------------
//
//    Instances
//
top top_inst
    (
        .rst(rst),
        .clk(clk)

        // UART
        ,.bit_period(bit_period)
        ,.control(control)
        ,.status(status)
        ,.TXCI(TXCI)    // TX Complete Interrupt
        ,.RXCI(RXCI)    // RX Complete Interrupt
        ,.UDRI(UDRI)    // Data Register Empty Interrupt
        //
        ,.tx_ready(tx_ready)
        ,.tx_din(tx_din)
        ,.tx_valid(tx_valid)
        //
        ,.rx_ready(rx_ready)
        ,.rx_dout(rx_dout)
        ,.rx_valid(rx_valid)
        //
        ,.TX(TX)        // UART Transmit Data
        ,.RX(RX)        // UART Receive Data
    );

endmodule
//-------------------------------------------------------------------------------

