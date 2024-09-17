
# Gigabit Ethernet GMII PHY
set_property -dict {LOC U20  IOSTANDARD LVCMOS33} [get_ports phy_rx_clk]
set_property -dict {LOC AA21 IOSTANDARD LVCMOS33} [get_ports {phy_rxd[0]}]
set_property -dict {LOC V20  IOSTANDARD LVCMOS33} [get_ports {phy_rxd[1]}]
set_property -dict {LOC U22  IOSTANDARD LVCMOS33} [get_ports {phy_rxd[2]}]
set_property -dict {LOC V22  IOSTANDARD LVCMOS33} [get_ports {phy_rxd[3]}]
set_property -dict {LOC AA20 IOSTANDARD LVCMOS33} [get_ports phy_rx_ctl]

set_property -dict {LOC V18  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports phy_tx_clk]
set_property -dict {LOC T21  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy_txd[0]}]
set_property -dict {LOC U21  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy_txd[1]}]
set_property -dict {LOC P19  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy_txd[2]}]
set_property -dict {LOC R19  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy_txd[3]}]
set_property -dict {LOC V19  IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports phy_tx_ctl]
set_property -dict {LOC N20  IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports phy_reset_n]

#create_clock -period 40.000 -name phy_tx_clk [get_ports phy_tx_clk]
create_clock -period 8.000 -name phy_rx_clk [get_ports phy_rx_clk]
#create_clock -period 8.000 -name phy_sgmii_clk [get_ports phy_sgmii_clk_p]

set_false_path -to [get_ports phy_reset_n]
set_output_delay 0.000 [get_ports phy_reset_n]

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks phy_rx_clk] -group [get_clocks -include_generated_clocks clk_50mhz]

set_property IDELAY_VALUE 0 [get_cells {phy_rx_ctl_idelay phy_rxd_idelay_*}]
# mdio
set_property -dict {LOC M20 IOSTANDARD LVCMOS33} [get_ports mdio_c]
set_property -dict {LOC N22 IOSTANDARD LVCMOS33} [get_ports mdio_d]