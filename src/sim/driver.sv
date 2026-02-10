`ifndef DRIVER_SV
    `define DRIVER_SV

`include "globals.sv"

class Driver;

    virtual uart_if.drv    drv_intf;
    mailbox #(Transaction) drvr2sb;

    // Constructor
    function new(virtual uart_if.drv    drv_intf_new,
                 mailbox #(Transaction) drvr2sb
                 );
        this.drv_intf = drv_intf_new;
        if(drvr2sb == null) begin
            $display(" **ERROR: drv2sb is null");
            $finish;
        end else
            this.drvr2sb = drvr2sb;
    endfunction : new

    task drive(Transaction trans);
        drv_intf.transmit_data_to_rx(trans.din);
        drv_intf.write_tx_data(trans.din);
        drv_intf.wait_for_tx_complete(trans.stop);
    endtask : drive

    // Start method
    task start();
        Transaction trans = new();

        $display(" %0d :  Driver  : start of start() method",$time);
        repeat(`NUM_OF_TRANS) begin
            if (trans.randomize) begin
                trans.din_valid = 1'b1;
                trans.display_inputs();
                drive(trans);
                drvr2sb.put(trans);
                #1us;
            end else begin
                $display (" %0d Driver : **ERROR: randomization failed",$time);
                trans.errors++;
            end
        end

        @(posedge drv_intf.clock);
        trans.stop = 1;
        $display(" %0d :  Driver  : end of start() method",$time);
    endtask : start

endclass

`endif //DRIVER_SV

