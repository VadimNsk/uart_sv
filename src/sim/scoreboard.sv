`ifndef SCOREBOARD_SV
    `define SCOREBOARD_SV

class Scoreboard;

    mailbox #(Transaction) drvr2sb;
    mailbox #(Transaction) rcvr2sb[2];

    // Constructor
    function new(mailbox #(Transaction) drvr2sb,
                 mailbox #(Transaction) rcvr2sb[2]);
        this.drvr2sb = drvr2sb;
        this.rcvr2sb = rcvr2sb;
    endfunction : new

    task start();
        Transaction dtrans, rtrans[2];
        logic eq_dr[2],     // equal driver and async receiver [0], and driver and sync receiver [1]
              eq_rr;        // equal async receiver and sync receiver

        $display(" %0d :  Scoreboard  : start of start() method",$time);
        while (!dtrans.stop) begin
            drvr2sb.get(dtrans);
            rcvr2sb[0].get(rtrans[0]);
            rcvr2sb[1].get(rtrans[1]);

            $display(" %0d : Scoreboard : Transactions received ", $time);
            $display(" %0d : Scoreboard : scheme input: \n %s ", $time, dtrans.append_inputs());
            $display(" %0d : Scoreboard : scheme outputs: \n %s ", $time, rtrans[0].append_outputs());
            $display(" %0d : Scoreboard : scheme outputs: \n %s ", $time, rtrans[1].append_outputs());

            eq_dr[0] = dtrans.compare(rtrans[0]);       // equal driver and async receiver
            eq_dr[1] = dtrans.compare(rtrans[1]);       // equal driver and sync receiver
            eq_rr    = rtrans[0].compare(rtrans[1]);    // equal async receiver and sync receiver

            if(!eq_rr || !(eq_dr[0] || eq_dr[1])) begin
                dtrans.errors++;
            end

            if (eq_rr)
                $display(" %0d : Scoreboard : Equal async receiver and sync receiver",$time);
            else begin
                $display(" %0d : Scoreboard : **ERROR: Unequal async receiver and sync receiver",$time);
            end

            if(eq_dr[0])
                $display(" %0d : Scoreboard : Equal driver and async receiver",$time);
            else begin
                $display(" %0d : Scoreboard : **ERROR: Unequal driver and async receiver",$time);
            end

            if(eq_dr[1])
                $display(" %0d : Scoreboard : Equal driver and sync receiver",$time);
            else begin
                $display(" %0d : Scoreboard : **ERROR: Unequal driver and sync receiver",$time);
            end
        end
        $display(" %0d :  Scoreboard  : end of start() method",$time);
    endtask : start

endclass

`endif //SCOREBOARD_SV

