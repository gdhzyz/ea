# XDC constraints for the Xilinx KC705 board
# part: xc7k325tffg900-2

# General configuration
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
#set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN Enable  [current_design]

# System clocks
# 200 MHz
set_property -dict {LOC W19 IOSTANDARD LVCMOS33} [get_ports clk_50mhz]
create_clock -period 20.000 -name clk_50mhz [get_ports clk_50mhz]

# Gigabit Ethernet GMII PHY
set_property -dict {LOC Y18 IOSTANDARD LVCMOS33} [get_ports phy_rx_clk]
set_property -dict {LOC AA21 IOSTANDARD LVCMOS33} [get_ports {phy_rxd[0]}]
set_property -dict {LOC V19 IOSTANDARD LVCMOS33} [get_ports {phy_rxd[0]}]
set_property -dict {LOC V20 IOSTANDARD LVCMOS33} [get_ports {phy_rxd[1]}]
set_property -dict {LOC U17 IOSTANDARD LVCMOS33} [get_ports {phy_rxd[2]}]
set_property -dict {LOC U20 IOSTANDARD LVCMOS33} [get_ports {phy_rxd[3]}]
set_property -dict {LOC Y19 IOSTANDARD LVCMOS33} [get_ports phy_rx_ctl]
set_property -dict {LOC V18 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports phy_tx_clk]
set_property -dict {LOC U21 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports phy_tx_clk]
set_property -dict {LOC V22 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy_txd[0]}]
set_property -dict {LOC W21 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy_txd[1]}]
set_property -dict {LOC W22 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy_txd[2]}]
set_property -dict {LOC Y21 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports {phy_txd[3]}]
set_property -dict {LOC U22 IOSTANDARD LVCMOS33 SLEW FAST DRIVE 16} [get_ports phy_tx_ctl]
set_property -dict {LOC AB22 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 12} [get_ports phy_reset_n]

#create_clock -period 40.000 -name phy_tx_clk [get_ports phy_tx_clk]
create_clock -period 8.000 -name phy_rx_clk [get_ports phy_rx_clk]
#create_clock -period 8.000 -name phy_sgmii_clk [get_ports phy_sgmii_clk_p]

set_false_path -to [get_ports phy_reset_n]
set_output_delay 0.000 [get_ports phy_reset_n]

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks phy_rx_clk] -group [get_clocks -include_generated_clocks clk_50mhz]

set_property IDELAY_VALUE 0 [get_cells {phy_rx_ctl_idelay phy_rxd_idelay_*}]

#set_input_delay -clock phy_rx_clk -min   0 [get_ports phy_rx_ctl]
#set_input_delay -clock phy_rx_clk -min   0 [get_ports {phy_rxd[0]}]
#set_input_delay -clock phy_rx_clk -min   0 [get_ports {phy_rxd[1]}]
#set_input_delay -clock phy_rx_clk -min   0 [get_ports {phy_rxd[2]}]
#set_input_delay -clock phy_rx_clk -min   0 [get_ports {phy_rxd[3]}]
#set_input_delay -clock phy_rx_clk -max 0.5 [get_ports phy_rx_ctl]
#set_input_delay -clock phy_rx_clk -max 0.5 [get_ports {phy_rxd[0]}]
#set_input_delay -clock phy_rx_clk -max 0.5 [get_ports {phy_rxd[1]}]
#set_input_delay -clock phy_rx_clk -max 0.5 [get_ports {phy_rxd[2]}]
#set_input_delay -clock phy_rx_clk -max 0.5 [get_ports {phy_rxd[3]}]
#set_input_delay -clock phy_rx_clk -min   0 [get_ports phy_rx_ctl]    -clock_fall -add_delay
#set_input_delay -clock phy_rx_clk -min   0 [get_ports {phy_rxd[0]}]  -clock_fall -add_delay
#set_input_delay -clock phy_rx_clk -min   0 [get_ports {phy_rxd[1]}]  -clock_fall -add_delay
#set_input_delay -clock phy_rx_clk -min   0 [get_ports {phy_rxd[2]}]  -clock_fall -add_delay
#set_input_delay -clock phy_rx_clk -min   0 [get_ports {phy_rxd[3]}]  -clock_fall -add_delay
#set_input_delay -clock phy_rx_clk -max 0.5 [get_ports phy_rx_ctl]    -clock_fall -add_delay
#set_input_delay -clock phy_rx_clk -max 0.5 [get_ports {phy_rxd[0]}]  -clock_fall -add_delay
#set_input_delay -clock phy_rx_clk -max 0.5 [get_ports {phy_rxd[1]}]  -clock_fall -add_delay
#set_input_delay -clock phy_rx_clk -max 0.5 [get_ports {phy_rxd[2]}]  -clock_fall -add_delay
#set_input_delay -clock phy_rx_clk -max 0.5 [get_ports {phy_rxd[3]}]  -clock_fall -add_delay

# leds
#set_property -dict {LOC H19 IOSTANDARD LVCMOS33} [get_ports led1]
#set_property -dict {LOC K16 IOSTANDARD LVCMOS33} [get_ports led2]
set_property -dict {LOC J14 IOSTANDARD LVCMOS33} [get_ports led1]
set_property -dict {LOC H14 IOSTANDARD LVCMOS33} [get_ports led2]

# Push buttons
set_property -dict {LOC G16 IOSTANDARD LVCMOS33} [get_ports reset]

# uart
set_property -dict {LOC H22 IOSTANDARD LVCMOS33} [get_ports uart_tx]
set_property -dict {LOC J22 IOSTANDARD LVCMOS33} [get_ports uart_rx]

# mdio
set_property -dict {LOC M20 IOSTANDARD LVCMOS33} [get_ports mdio_c]
set_property -dict {LOC AA21 IOSTANDARD LVCMOS33} [get_ports mdio_c]
set_property -dict {LOC Y22 IOSTANDARD LVCMOS33} [get_ports mdio_d]

