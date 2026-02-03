#-------------------------------------------------------------------------------
#   project:       vivado-boilerplate
#   variant:       7a35t
#
#   description:
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

#-------------------------------------------------------------------------------
#    ref_clk
#-------------------------------------------------------------------------------

create_clock -period $REF_CLK_PERIOD -name clk_ext

set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk]
set_switching_activity -deassert_resets 

#-------------------------------------------------------------------------------
#    Timing
#-------------------------------------------------------------------------------

#set_input_delay  -clock [get_clocks clk] 0.0 [get_ports {bit_period[*] control[*] tx_din[*] tx_valid rx_ready RX}]
#set_output_delay -clock [get_clocks clk] 0.0 [get_ports {status[*] TXCI RXCI UDRI tx_ready rx_dout[*] rx_valid TX}]
set_input_delay  -clock clk_ext -max 0.0 [get_ports {bit_period[*] control[*] tx_din[*] tx_valid rx_ready RX}]
set_output_delay -clock clk_ext -max 0.0 [get_ports {status[*] TXCI RXCI UDRI tx_ready rx_dout[*] rx_valid TX}]

#-------------------------------------------------------------------------------
#    Pin locations
#-------------------------------------------------------------------------------

#set_property IOB true [get_ports {out[*]}]
#set_property IOB true [get_cells -hierarchical "a_reg*" ]
#set_property IOB true [get_cells -hierarchical "b_reg*" ]
#set_property IOB true [get_cells -hierarchical "valid_a_reg*" ]
#set_property IOB true [get_cells -hierarchical "valid_b_reg*" ]

#set_property SLEW FAST [get_ports clk_out]
#set_property SLEW FAST [get_ports valid_out]
#set_property SLEW FAST [get_ports {out[*]}]

#-------------------------------------------------------------------------------

set_property PACKAGE_PIN R10 [get_ports rst]
set_property PACKAGE_PIN E3  [get_ports clk]
#
set_property PACKAGE_PIN K17 [get_ports TX]
set_property PACKAGE_PIN K18 [get_ports RX]
#
#set_property PACKAGE_PIN L13 [get_ports {control[RXCIE]}]
set_property PACKAGE_PIN L13 [get_ports {control[0]}]
#set_property PACKAGE_PIN L14 [get_ports {control[TXCIE]}]
set_property PACKAGE_PIN L14 [get_ports {control[1]}]
#set_property PACKAGE_PIN L15 [get_ports {control[UDRIE]}]
set_property PACKAGE_PIN L15 [get_ports {control[2]}]
#set_property PACKAGE_PIN L16 [get_ports {control[RXEN]}]
set_property PACKAGE_PIN L16 [get_ports {control[3]}]
#set_property PACKAGE_PIN L18 [get_ports {control[TXEN]}]
set_property PACKAGE_PIN L18 [get_ports {control[4]}]
#
#set_property PACKAGE_PIN M13 [get_ports {status[RXC]}]
set_property PACKAGE_PIN M13 [get_ports {status[0]}]
#set_property PACKAGE_PIN M14 [get_ports {status[TXC]}]
set_property PACKAGE_PIN M14 [get_ports {status[1]}]
#set_property PACKAGE_PIN M16 [get_ports {status[UDRE]}]
set_property PACKAGE_PIN M16 [get_ports {status[2]}]
#set_property PACKAGE_PIN M17 [get_ports {status[FE]}]
set_property PACKAGE_PIN M17 [get_ports {status[3]}]
#set_property PACKAGE_PIN M18 [get_ports {status[DOR]}]
set_property PACKAGE_PIN M18 [get_ports {status[4]}]
#
set_property PACKAGE_PIN N14 [get_ports TXCI]
set_property PACKAGE_PIN N15 [get_ports RXCI]
set_property PACKAGE_PIN N16 [get_ports UDRI]
#
set_property PACKAGE_PIN P14 [get_ports {bit_period[0]}]
set_property PACKAGE_PIN P15 [get_ports {bit_period[1]}]
set_property PACKAGE_PIN P17 [get_ports {bit_period[2]}]
set_property PACKAGE_PIN P18 [get_ports {bit_period[3]}]
set_property PACKAGE_PIN R12 [get_ports {bit_period[4]}]
set_property PACKAGE_PIN R13 [get_ports {bit_period[5]}]
set_property PACKAGE_PIN R15 [get_ports {bit_period[6]}]
set_property PACKAGE_PIN R16 [get_ports {bit_period[7]}]
set_property PACKAGE_PIN R17 [get_ports {bit_period[8]}]
set_property PACKAGE_PIN R18 [get_ports {bit_period[9]}]
set_property PACKAGE_PIN T9  [get_ports {bit_period[10]}]
set_property PACKAGE_PIN T10 [get_ports {bit_period[11]}]
set_property PACKAGE_PIN T11 [get_ports {bit_period[12]}]
set_property PACKAGE_PIN T13 [get_ports {bit_period[13]}]
set_property PACKAGE_PIN T14 [get_ports {bit_period[14]}]
set_property PACKAGE_PIN T15 [get_ports {bit_period[15]}]
set_property PACKAGE_PIN T16 [get_ports {bit_period[16]}]
set_property PACKAGE_PIN T18 [get_ports {bit_period[17]}]
set_property PACKAGE_PIN L1  [get_ports tx_ready]
set_property PACKAGE_PIN L3  [get_ports {tx_din[0]}]
set_property PACKAGE_PIN L4  [get_ports {tx_din[1]}]
set_property PACKAGE_PIN L5  [get_ports {tx_din[2]}]
set_property PACKAGE_PIN L6  [get_ports {tx_din[3]}]
set_property PACKAGE_PIN M1  [get_ports {tx_din[4]}]
set_property PACKAGE_PIN M2  [get_ports {tx_din[5]}]
set_property PACKAGE_PIN M3  [get_ports {tx_din[6]}]
set_property PACKAGE_PIN M4  [get_ports {tx_din[7]}]
set_property PACKAGE_PIN M6  [get_ports tx_valid]
set_property PACKAGE_PIN N1  [get_ports rx_ready]
set_property PACKAGE_PIN N2  [get_ports {rx_dout[0]}]
set_property PACKAGE_PIN N4  [get_ports {rx_dout[1]}]
set_property PACKAGE_PIN N5  [get_ports {rx_dout[2]}]
set_property PACKAGE_PIN N6  [get_ports {rx_dout[3]}]
set_property PACKAGE_PIN P2  [get_ports {rx_dout[4]}]
set_property PACKAGE_PIN P3  [get_ports {rx_dout[5]}]
set_property PACKAGE_PIN P4  [get_ports {rx_dout[6]}]
set_property PACKAGE_PIN P5  [get_ports {rx_dout[7]}]
set_property PACKAGE_PIN R1  [get_ports rx_valid]

#-------------------------------------------------------------------------------

set_property IOSTANDARD LVCMOS33 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports {control[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {status[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {bit_period[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports tx_ready]
set_property IOSTANDARD LVCMOS33 [get_ports {tx_din[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports tx_valid]
set_property IOSTANDARD LVCMOS33 [get_ports rx_ready]
set_property IOSTANDARD LVCMOS33 [get_ports {rx_dout[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports rx_valid]
set_property IOSTANDARD LVCMOS33 [get_ports TX]
set_property IOSTANDARD LVCMOS33 [get_ports RX]
set_property IOSTANDARD LVCMOS33 [get_ports TXCI]
set_property IOSTANDARD LVCMOS33 [get_ports RXCI]
set_property IOSTANDARD LVCMOS33 [get_ports UDRI]

#set_property IOB true [get_ports tx_ready]
set_property IOB true [get_ports {tx_din[*]}]
#set_property IOB true [get_ports tx_valid]
#set_property IOB true [get_ports rx_ready]
set_property IOB true [get_ports {rx_dout[*]}]
#set_property IOB true [get_ports rx_valid]
#
#set_property IOB true [get_ports {status[UDRE]}]
set_property IOB true [get_ports {status[2]}]
#set_property IOB true [get_ports {status[FE]}]
set_property IOB true [get_ports {status[1]}]
#set_property IOB true [get_ports {status[DOR]}]
set_property IOB true [get_ports {status[0]}]
#
set_property IOB true [get_ports TXCI]
set_property IOB true [get_ports RXCI]
set_property IOB true [get_ports UDRI]
set_property IOB true [get_ports TX]
set_property IOB true [get_ports RX]

set_property DRIVE 12 [get_ports TXCI]
set_property DRIVE 12 [get_ports RXCI]
set_property DRIVE 12 [get_ports UDRI]
set_property DRIVE 12 [get_ports status[*]]
set_property DRIVE 12 [get_ports tx_ready]
set_property DRIVE 12 [get_ports rx_dout[*]]
set_property DRIVE 12 [get_ports rx_valid]
set_property DRIVE 12 [get_ports TX]

set_property OFFCHIP_TERM NONE [get_ports TXCI]
set_property OFFCHIP_TERM NONE [get_ports RXCI]
set_property OFFCHIP_TERM NONE [get_ports UDRI]
set_property OFFCHIP_TERM NONE [get_ports status[*]]
set_property OFFCHIP_TERM NONE [get_ports tx_ready]
set_property OFFCHIP_TERM NONE [get_ports rx_dout[*]]
set_property OFFCHIP_TERM NONE [get_ports rx_valid]
set_property OFFCHIP_TERM NONE [get_ports TX]

