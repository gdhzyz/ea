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
# 50 MHz
set_property -dict {LOC R4 IOSTANDARD LVCMOS15} [get_ports clk_50mhz]
set_property -dict {LOC U7 IOSTANDARD LVCMOS15} [get_ports reset_n]
create_clock -period 20.000 -name clk_50mhz [get_ports clk_50mhz]

# leds
set_property -dict {LOC M21 IOSTANDARD LVCMOS33} [get_ports led1]
set_property -dict {LOC M22 IOSTANDARD LVCMOS33} [get_ports led2]


# uart
set_property -dict {LOC AB20 IOSTANDARD LVCMOS33} [get_ports uart_tx]
set_property -dict {LOC AA19 IOSTANDARD LVCMOS33} [get_ports uart_rx]
