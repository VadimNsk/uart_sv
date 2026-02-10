`ifndef ENVIRONMENT_SV
    `define ENVIRONMENT_SV


`include "transaction.sv"
`include "driver.sv"
`include "receiver.sv"
`include "scoreboard.sv"
`include "uart_if.sv"


class Environment ;

    virtual uart_if.drv drv_intf;
    virtual uart_if.rcv rcv_intf;


    Driver                 drvr;
    Receiver               rcvr[2];
    Scoreboard             sb;
    mailbox #(Transaction) drvr2sb;
    mailbox #(Transaction) rcvr2sb[2];


    function new(virtual uart_if.drv drv_intf_new,
                 virtual uart_if.rcv rcv_intf_new);
        this.drv_intf = drv_intf_new;
        this.rcv_intf = rcv_intf_new;

        $display(" %0d :  Environment  : constructor created env object",$time);
    endfunction : new

    function void build();
        $display(" %0d :  Environment  : start of build() method",$time);
        drvr2sb    = new(`NUM_OF_TRANS);
        rcvr2sb[0] = new(`NUM_OF_TRANS);
        rcvr2sb[1] = new(`NUM_OF_TRANS);
        drvr       = new(drv_intf, drvr2sb);
        sb         = new(drvr2sb,  rcvr2sb);
        rcvr[0]    = new(rcv_intf, rcvr2sb[0], 0);
        rcvr[1]    = new(rcv_intf, rcvr2sb[1], 1);
        $display(" %0d :  Environment  : end of build() method",$time);
    endfunction : build

    task reset();
        $display(" %0d :  Environment  : start of reset() method",$time);
        // Drive all DUT inputs to a known state
        drv_intf.bit_period = get_bit_period(TEST_BAUDRATE);    // 192000
        drv_intf.control    = '{TXEN     : 0,
                                RXEN     : 0,
                                TXCIE    : 0,
                                RXCIE    : 0,
                                TXDREIE  : 0,
                                RXDRNEIE : 0};
        drv_intf.tx_din      = 0;
        drv_intf.tx_valid    = 0;
        drv_intf.RX          = 1;
        rcv_intf.rx_ready    = 0;

        wait(drv_intf.reset == 1'b0);

        /*// Reset the DUT
        drv_intf.reset <= 1;
        repeat (4) @drv_intf.clock;
        drv_intf.reset <= 0;
        */
        $display(" %0d :  Environment  : end of reset() method",$time);
    endtask : reset

    task cfg_dut();
        $display(" %0d :  Environment  : start of cfg_dut() method",$time);
        drv_intf.bit_period = get_bit_period(TEST_BAUDRATE);    // 192000
        drv_intf.control.TXEN = 1;
        drv_intf.control.RXEN = 1;
        @(posedge drv_intf.clock);
        $display(" %0d :  Environment  : end of cfg_dut() method",$time);
    endtask : cfg_dut

    task start();
        $display(" %0d :  Environment  : start of start() method",$time);
        fork
            drvr.start();
            rcvr[0].start();
            rcvr[1].start();
        join
        sb.start();
        $display(" %0d :  Environment  : end of start() method",$time);
    endtask : start

    task wait_for_end();
        $display(" %0d :  Environment  : start of wait_for_end() method",$time);
        repeat(100) @(drv_intf.clock);
        $display(" %0d :  Environment  : end of wait_for_end() method",$time);
    endtask : wait_for_end

    task report();

        Transaction trans;

        $display(" %0d :  Environment  : start of report() method",$time);

        $display("=====================================");
        if (trans.errors == 1)
            $display(" Test completed with 1 error");
        else if (trans.errors)
            $display(" Test completed with %d errors", trans.errors);
        else
            $display(" Test completed without errors");
        $display("=====================================");

        $display(" %0d :  Environment  : end of report() method",$time);
    endtask : report

    task run();
        $display(" %0d :  Environment  : start of run() method",$time);
        build();
        reset();
        cfg_dut();
        start();
        wait_for_end();
        report();
        $display(" %0d :  Environment  : end of run() method",$time);
    endtask : run

endclass

`endif //ENVIRONMENT_SV

