`ifndef TRANSACTION_SV
    `define TRANSACTION_SV

`include "uart_pkg.svh"
import uart_pkg::*;

class Transaction;

    static int  errors     = 0;
    static bit  stop       = 0;

    rand data_t din;
         logic  din_valid  = 0;
         data_t dout;
         logic  dout_valid = 0;

    // Display transaction's inputs
    virtual function void display_inputs();
        if(din_valid)
            $display("Transaction input: din = 0x%02h", din);
        else
            $display("Transaction input not valid");
    endfunction : display_inputs
    //
    virtual function string append_inputs();
        if(din_valid)
            $swrite(append_inputs, " din = 0x%02h", din);
        else
            $swrite(append_inputs, " not valid");
    endfunction : append_inputs

    // Display transaction's outputs
    virtual function void display_outputs();
        if(dout_valid)
            $display("Transaction output: dout = 0x%02h", dout);
        else
            $display("Transaction output not valid");
    endfunction : display_outputs
    //
    virtual function string append_outputs();
        if(dout_valid)
            $swrite(append_outputs, " dout = 0x%02h", dout);
        else
            $swrite(append_outputs, " not valid");
    endfunction : append_outputs

    // Compare transactions
    virtual function bit compare(Transaction rtrans);
        compare = 1;

        if (rtrans == null) begin
            $display(" ** ERROR ** : trans : received a null object ");
            compare = 0;
        end else begin
            if(this.din_valid) begin
                if(this.dout_valid && (this.din !== this.dout)) begin
                    $display(" ** ERROR **: trans : dout did not match");
                    compare = 0;
                end
            end
            if((this.dout_valid && rtrans.dout_valid) && (this.dout !== rtrans.dout)) begin
                $display(" ** ERROR **: trans : dout did not match");
                compare = 0;
            end
        end
    endfunction : compare

endclass

`endif //TRANSACTION_SV

