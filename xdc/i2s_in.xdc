create_clock -period 40.690 -name i2s_in_mclki [get_ports i2s_in_mclki]

set_property -dict {LOC W20 IOSTANDARD LVCMOS33} [get_ports i2s_in_mclki]
set_property -dict {LOC AB20 IOSTANDARD LVCMOS33} [get_ports {i2s_in_bclk[0]}]
set_property -dict {LOC AA20 IOSTANDARD LVCMOS33} [get_ports {i2s_in_lrck[0]}]
set_property -dict {LOC AA19 IOSTANDARD LVCMOS33} [get_ports {i2s_in_datin[0]}]
set_property -dict {LOC AB21 IOSTANDARD LVCMOS33} [get_ports {i2s_out_datout[0]}]

#create_generated_clock -name i2s_in_bclk0 -source [get_pins *clk_mmcm_inst/CLKOUT0] [get_pins REGA/Q]

set_clock_groups -name async_sys_i2s -asynchronous -group {clk_50mhz} -group {i2s_in_mclki}
#set_clock_groups -name async_sys_i2s -asynchronous -group {clk_50mhz} -group {i2s_in_mclki} -group {i2s_in_bclk*}