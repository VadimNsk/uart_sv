`ifndef SCOREBOARD_SV
    `define SCOREBOARD_SV

class Scoreboard;

    mailbox #(Transaction) drvr2sb;
    mailbox #(Transaction) rcvr2sb;

    // Constructor
    function new(mailbox #(Transaction) drvr2sb,
                 mailbox #(Transaction) rcvr2sb);
        this.drvr2sb = drvr2sb;
        this.rcvr2sb = rcvr2sb;
    endfunction : new

    task start();
        Transaction dtrans, rtrans;

        while (!dtrans.stop && !rtrans.stop) begin
            drvr2sb.get(dtrans);
            rcvr2sb.get(rtrans);
            $display(" %0d : Scoreboard : Transactions received ", $time);
            $display(" %0d : Scoreboard : scheme outputs: \n %s ", $time, rtrans.append_outputs());
            $display(" %0d : Scoreboard : scheme input: \n %s ", $time, dtrans.append_inputs());
            if (dtrans.compare(rtrans)) begin
                $display(" %0d : Scoreboard : Equal outputs ",$time);
            end else begin
                $display(" %0d : Scoreboard : **ERROR: Unequal outputs ",$time);
                rtrans.errors++;
            end
        end
    endtask : start

endclass

`endif //SCOREBOARD_SV

