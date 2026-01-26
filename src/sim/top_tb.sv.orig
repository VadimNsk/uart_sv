//-------------------------------------------------------------------------------
//
//     Project: Any
//
//     Purpose: Default testbench file
//
//-------------------------------------------------------------------------------

`include "cfg_params.svh"

`timescale 1ns/1ps

module top_tb;

//------------------------------------------------------------------------------
//
//    Settings
//
localparam CLK_HALF_PERIOD = `REF_CLK_HALF_PERIOD;
localparam DATA_W          = `DATA_WIDTH;
    
//------------------------------------------------------------------------------
//
//    Types
//
    
//------------------------------------------------------------------------------
//
//    Objects
//
`ifdef DIFF_REFCLK
logic ref_clk_p = 0;
logic ref_clk_n = 1;
`else
logic ref_clk = 0;
`endif

logic clk;

logic [DATA_W-1:0] dinp_a = 1;
logic              valid_a;

logic [DATA_W-1:0] dinp_b = 2;
logic              valid_b;

logic [ DATA_W:0]  out;
logic              valid_out;

    
//------------------------------------------------------------------------------
//
//    Logic
//
`ifdef DIFF_REFCLK
always begin
    #CLK_HALF_PERIOD
    ref_clk_p = ~ref_clk_p;
    ref_clk_n = ~ref_clk_n;
end
`else
always begin
    #CLK_HALF_PERIOD
    ref_clk = ~ref_clk;
end
`endif


assign valid_a = 1;
assign valid_b = 1;

always_ff @(posedge clk) begin
    dinp_a <= dinp_a + 1;
    dinp_b <= dinp_b + 1;
end

initial begin
    #10us
    $display("\n%c[1;32m ******************** SIMULATION RUN FINISHED SUCCESSFULLY ********************%c[0m", 27, 27);
    $stop(2);   
end 

//------------------------------------------------------------------------------
//
//    Instances
//
top top_inst
(
`ifdef DIFF_REFCLK
    .ref_clk_p ( ref_clk_p ),
    .ref_clk_n ( ref_clk_n ),
`else                        
    .ref_clk   ( ref_clk   ),
`endif

    .clk_out   ( clk       ),
    .dinp_a    ( dinp_a    ),
    .valid_a   ( valid_a   ),
    .dinp_b    ( dinp_b    ),
    .valid_b   ( valid_b   ),
    .out       ( out       ),
    .valid_out ( valid_out )
);

endmodule
//-------------------------------------------------------------------------------

