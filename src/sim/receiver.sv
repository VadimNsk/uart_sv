`ifndef RECEIVER_SV
    `define RECEIVER_SV

class Receiver;
    virtual uart_if.rcv    rcv_intf;
    mailbox #(Transaction) rcvr2sb;
    logic                  sync;

// Constructor
    function new(virtual uart_if.rcv    rcv_intf_new,
                 mailbox #(Transaction) rcvr2sb,
                 logic                  sync
                 );
        this.rcv_intf = rcv_intf_new;
        if(rcvr2sb == null) begin
            $display(" **ERROR: rcvr2sb is null");
            $finish;
        end else
            this.rcvr2sb = rcvr2sb;
        this.sync     = sync;
    endfunction : new

    task receive(Transaction trans);
        if(!sync)
            rcv_intf.receive_data_from_tx(trans.dout, trans.dout_valid);
        else if(!trans.stop) begin
            rcv_intf.wait_for_rx_complete(trans.stop);
            @(posedge rcv_intf.clock);
            rcv_intf.read_rx_data(trans.dout, trans.stop);
            if(!trans.stop) begin
                trans.dout_valid = 1'b1;
//              $display(" %0d : %sync received data 0x%02h", $time, (sync) ? "S":"As", trans.dout);
            end
        end
    endtask

    // Start method
    task start();
        Transaction trans = new();
        int received = 0;

        $display(" %0d :  %sync receiver  : start of start() method",$time, (sync) ? "S":"As");
        while (!trans.stop) begin
            receive(trans);
            $display(" %0d : %sync receiver : scheme ouput: %s ", $time, (sync) ? "S":"As", trans.append_outputs());
            if(trans.dout_valid)
                rcvr2sb.put(trans);
            received++;
            if(received == `NUM_OF_TRANS)
                break;
        end
        $display(" %0d :  %sync receiver  : end of start() method",$time, (sync) ? "S":"As");
    endtask : start

endclass

`endif //RECEIVER_SV

