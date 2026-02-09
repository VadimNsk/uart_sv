`ifndef TRANSACTION_SV
    `define TRANSACTION_SV

`include "uart_pkg.svh"
import uart_pkg::*;

class Transaction;

    static int  errors = 0;
    static bit  stop   = 0;

    rand data_t din;
         data_t tx_dout;
         logic  tx_dout_valid = 0;
         data_t rx_dout;

    // Display transaction's inputs
    virtual function void display_inputs();
        $display(" Transaction inputs: din = 0x%02h ", din);
    endfunction : display_inputs
    //
    virtual function string append_inputs();
        $swrite(append_inputs, "din = 0x%02h ", din);
    endfunction : append_inputs

    // Display transaction's outputs
    virtual function void display_outputs();
        $display(" Transaction outputs: rx_dout = 0x%02h; tx_dout = 0x%02h; tx_dout_valid = %0b ", tx_dout, rx_dout, tx_dout_valid);
    endfunction : display_outputs
    //
    virtual function string append_outputs();
        $swrite(append_outputs, "rx_dout = 0x%02h; tx_dout = 0x%02h; tx_dout_valid = %0b ", tx_dout, rx_dout, tx_dout_valid);
    endfunction : append_outputs

    // Compare transactions
    virtual function bit compare(Transaction rtrans);
        compare = 1;

        if (rtrans == null) begin
            $display(" ** ERROR ** : trans : received a null object ");
            compare = 0;
        end else begin
            if(!rtrans.tx_dout_valid) begin
                $display(" ** ERROR **: trans : received data not valid");
                compare = 0;
            end
            if(rtrans.tx_dout !== this.din) begin
                $display(" ** ERROR **: trans : tx_dout did not match");
                compare = 0;
            end
            if(rtrans.rx_dout !== this.din) begin
                $display(" ** ERROR **: trans : rx_dout did not match");
                compare = 0;
            end
        end
    endfunction : compare

endclass

`endif //TRANSACTION_SV

