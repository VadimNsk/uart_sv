//-------------------------------------------------------------------------------
//
//     Project: Any
//
//     Purpose: Default top-level file
//
//-------------------------------------------------------------------------------

`include "cfg_params.svh"


module automatic top
#(
    localparam DATA_W = `DATA_WIDTH
)
(
`ifdef DIFF_REFCLK
    input  logic              ref_clk_p,
    input  logic              ref_clk_n,
`else                         
    input  logic              ref_clk,
`endif

    output logic              clk_out,

    input  logic [DATA_W-1:0] dinp_a,
    input  logic              valid_a,

    input  logic [DATA_W-1:0] dinp_b,
    input  logic              valid_b,

    output logic [ DATA_W:0]  out,
    output logic              valid_out
);

//------------------------------------------------------------------------------
//
//    Settings
//
localparam int CLOCK_FREQ_MHz   = 100;
localparam int MIN_BAUDRATE_Hz  = 600;

localparam int BAUDRATE_RATIO   = CLOCK_FREQ_MHz * 1_000_000 / MIN_BAUDRATE_Hz;
localparam BIT_PERIOD_WIDTH = $clog2(BAUDRATE_RATIO);

//------------------------------------------------------------------------------
//
//    Types
//
    
//------------------------------------------------------------------------------
//
//    Objects
//
`ifdef DIFF_REFCLK
logic ref_clk;
`endif

logic clk;
logic clk2;
logic pll_locked;
logic rst;

logic [DATA_W-1:0] a_reg       = 0;
logic [DATA_W-1:0] b_reg       = 0;
logic              valid_a_reg = 0;
logic              valid_b_reg = 0;

`ifdef ADDER_MODULE
dinp_if #( .DATA_W ( DATA_W   ) ) a();
dinp_if #( .DATA_W ( DATA_W   ) ) b();
dout_if #( .DATA_W ( DATA_W+1 ) ) o();
`endif // ADDER_MODULE

//------------------------------------------------------------------------------
//
//    ILA debug
//
`ifdef TOP_ENABLE_ILA

(* mark_debug = "true" *) logic [DATA_W-1:0] dbg_out;
(* mark_debug = "true" *) logic              dbg_pll_locked;

assign dbg_out        = out;
assign dbg_pll_locked = pll_locked;

`endif // TOP_DEBUG_ENABLE


//------------------------------------------------------------------------------
//
//    Functions and tasks
//

//------------------------------------------------------------------------------
//
//    Logic
//
assign rst     = ~pll_locked;

always_ff @(posedge clk) begin
    a_reg       <= dinp_a;
    b_reg       <= dinp_b;
    valid_a_reg <= valid_a;
    valid_b_reg <= valid_b;
end

`ifdef ADDER_MODULE

assign a.valid   = valid_a_reg;
assign b.valid   = valid_b_reg;
assign a.data    = a_reg;
assign b.data    = b_reg;

always_ff @(posedge clk) begin
    out       <= o.data;
    valid_out <= o.valid;
end

`else

always_ff @(posedge clk) begin
    if(rst) begin
        out <= 0;
    end
    else begin
        valid_out <= 0;
        if(valid_a_reg && valid_b_reg) begin
            out       <= a_reg + b_reg;
            valid_out <= 1;
        end
    end
end

`endif // ADDER_MODULE


//------------------------------------------------------------------------------
//
//    Instances
//
`ifdef DIFF_REFCLK
IBUFDS diff_clk_200
(
    .I  ( ref_clk_p ),
    .IB ( ref_clk_n ),
    .O  ( ref_clk   )
);
`endif
//------------------------------------------------------------------------------
pll pll_inst
(
    .clk_in1  ( ref_clk    ),
    .clk_out1 ( clk        ),
    .clk_out2 ( clk2       ),
    .locked   ( pll_locked )
);
//-------------------------------------------------------------------------------
ODDR 
#(
   .DDR_CLK_EDGE ("OPPOSITE_EDGE" ),  // "OPPOSITE_EDGE" or "SAME_EDGE"
   .INIT         (1'b0            ),  // Initial value of Q: 1'b0 or 1'b1
   .SRTYPE       ("SYNC"          )   // Set/Reset type: "SYNC" or "ASYNC"
) 
clk_out_gen 
(
    .C  ( clk2    ),  // 1-bit clock input
    .CE ( 1'b1    ),  // 1-bit clock enable input
    .D1 ( 1'b1    ),  // 1-bit data input (positive edge)
    .D2 ( 1'b0    ),  // 1-bit data input (negative edge)
    .R  ( 1'b0    ),  // 1-bit reset
    .S  ( 1'b0    ),  // 1-bit set
    .Q  ( clk_out )   // 1-bit DDR output
);
//-------------------------------------------------------------------------------
`ifdef ADDER_MODULE
adder_m adder
(   
    .clk ( clk ),
    .rst ( rst ),
    .a   ( a   ),
    .b   ( b   ),
    .out ( o   )
 );
`endif // ADDER_MODULE
//-------------------------------------------------------------------------------
uart
    #(   .CLOCK_FREQ_MHz(CLOCK_FREQ_MHz)
        ,.MIN_BAUDRATE_Hz(MIN_BAUDRATE_Hz)
        )
    uart_inst
    (    .reset(rst)
        ,.clock(clk)
//        ,.bit_count(bit_count)
        );
//-------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------

