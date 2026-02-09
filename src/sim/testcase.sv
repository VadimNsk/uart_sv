`ifndef TESTCASE_SV
`define TESTCASE_SV

`include "environment.sv"
`include "uart_if.sv"


program testcase(
    uart_if.drv drv_intf,
    uart_if.rcv rcv_intf
    );

Environment env;

initial begin
    $display(" Start of program block testcase");
    env = new(drv_intf, rcv_intf);
    env.run();
    $display(" End of program block testcase");
    $stop(2);
end
/*
final
    $display(" End of program block testcase");
*/
endprogram

`endif  //TESTCASE_SV

