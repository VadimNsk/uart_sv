`ifndef DRIVER_SV
    `define DRIVER_SV

`include "globals.sv"

class Driver;

    virtual uart_if.drv    drv_intf;
//  Transaction            trans_e;
//  Coverage               cov      = new();
    mailbox #(Transaction) drvr2sb;

    // Constructor
    function new(virtual uart_if.drv    drv_intf_new,
                 mailbox #(Transaction) drvr2sb
                 );
        this.drv_intf = drv_intf_new;
//      trans_e       = new();
        if(drvr2sb == null) begin
            $display(" **ERROR: drv2sb is null");
            $finish;
        end else
            this.drvr2sb = drvr2sb;
    endfunction : new

    task drive(Transaction trans);
        @(posedge drv_intf.clock);
        fork
            drv_intf.write_tx_data(trans.din);
            drv_intf.transmit_data_to_rx(trans.din);
        join
        drv_intf.wait_for_tx_complete();
    endtask : drive

    // Start method
    task start();
//      Transaction trans = new trans_e;
        Transaction trans = new();

        repeat(`NUM_OF_TRANS) begin
            if (trans.randomize) begin
                trans.display_inputs();
                drive(trans);
//              cov.sample(trans);
                drvr2sb.put(trans);
            end else begin
                $display (" %0d Driver : **ERROR: randomization failed",$time);
                trans.errors++;
            end
        end

        @(posedge drv_intf.clock);
        trans.stop = 1;
    endtask : start

endclass

`endif //DRIVER_SV

