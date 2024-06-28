# XDC constraints for the Xilinx KC705 board
# part: xc7k325tffg900-2

# General configuration
set_property CFGBVS VCCO                               [current_design]
set_property CONFIG_VOLTAGE 3.3                        [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true           [current_design]
#set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN Enable  [current_design]

# System clocks
# 200 MHz
set_property -dict {LOC W19 IOSTANDARD LVCMOS33} [get_ports clk_50mhz]
create_clock -period 20.000 -name clk_50mhz [get_ports clk_50mhz]

# Gigabit Ethernet GMII PHY
set_property -dict {LOC Y18  IOSTANDARD LVCMOS33} [get_ports phy_rx_clk] ;
set_property -dict {LOC V19  IOSTANDARD LVCMOS33} [get_ports {phy_rxd[0]}] ;
set_property -dict {LOC V20  IOSTANDARD LVCMOS33} [get_ports {phy_rxd[1]}] ;
set_property -dict {LOC U17  IOSTANDARD LVCMOS33} [get_ports {phy_rxd[2]}] ;
set_property -dict {LOC U20  IOSTANDARD LVCMOS33} [get_ports {phy_rxd[3]}] ;
set_property -dict {LOC Y19  IOSTANDARD LVCMOS33} [get_ports phy_rx_ctl] ;
set_property -dict {LOC U21  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports phy_tx_clk] ;
set_property -dict {LOC V22  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy_txd[0]}] ;
set_property -dict {LOC W21  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy_txd[1]}] ;
set_property -dict {LOC W22  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy_txd[2]}] ;
set_property -dict {LOC Y21  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy_txd[3]}] ;
set_property -dict {LOC U22  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports phy_tx_ctl] ;
set_property -dict {LOC AB22 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports phy_reset_n] ;

#create_clock -period 40.000 -name phy_tx_clk [get_ports phy_tx_clk]
create_clock -period 8.000 -name phy_rx_clk [get_ports phy_rx_clk]
#create_clock -period 8.000 -name phy_sgmii_clk [get_ports phy_sgmii_clk_p]

set_false_path -to [get_ports {phy_reset_n}]
set_output_delay 0 [get_ports {phy_reset_n}]


# leds
set_property -dict {LOC H19  IOSTANDARD LVCMOS33} [get_ports led1] ;
set_property -dict {LOC K16  IOSTANDARD LVCMOS33} [get_ports led2] ;