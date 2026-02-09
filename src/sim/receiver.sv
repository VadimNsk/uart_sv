`ifndef RECEIVER_SV
    `define RECEIVER_SV

class Receiver;
    virtual uart_if.rcv    rcv_intf;
    mailbox #(Transaction) rcvr2sb;

// Constructor
    function new(virtual uart_if.rcv    rcv_intf_new,
                 mailbox #(Transaction) rcvr2sb
                 );
        this.rcv_intf = rcv_intf_new;
        if(rcvr2sb == null) begin
            $display(" **ERROR: rcvr2sb is null");
            $finish;
        end else
            this.rcvr2sb = rcvr2sb;
    endfunction : new

    task receive(Transaction trans);
        @(posedge rcv_intf.clock);
        fork
            rcv_intf.receive_data_from_tx(trans.tx_dout, trans.tx_dout_valid);
            rcv_intf.read_rx_data(trans.rx_dout);
        join
        rcv_intf.wait_for_rx_complete();
    endtask

    // Start method
    task start();
        Transaction trans = new();

        while (!trans.stop) begin
            receive(trans);
            trans.display_outputs();
            rcvr2sb.put(trans);
        end
    endtask : start

endclass

`endif //RECEIVER_SV

