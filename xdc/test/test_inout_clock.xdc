set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]

set_property -dict {LOC W19 IOSTANDARD LVCMOS33} [get_ports clk_50mhz]
create_clock -period 20.000 -name clk_50mhz [get_ports clk_50mhz]

set_property -dict {LOC AA19 IOSTANDARD LVCMOS33} [get_ports {i2s_in_bclk[0]}]
set_property -dict {LOC AB21 IOSTANDARD LVCMOS33} [get_ports {i2s_out_datout[0]}]
set_property -dict {LOC G16 IOSTANDARD LVCMOS33} [get_ports {i2s_in_bclkt[0]}]

# internal generated output bclk
create_generated_clock -name i2s_in_bclko0 -source [get_pins clk_bufg_inst/O] -divide_by 4 [get_pins freq_divider_inst/oclk_reg_reg/Q]
# external generated input bclk
create_clock -period 40.690 -name i2s_in_bclki0 [get_ports {i2s_in_bclk[0]}]
# muxed bclk
#create_generated_clock -name i2s_in_bclk0_bufr0 -source [get_pins bclk_bufr_inst/I] -divide_by 1 -add -master_clock i2s_in_bclko0 [get_pins bclk_bufr_inst/O]
#create_generated_clock -name i2s_in_bclk0_bufr1 -source [get_pins bclk_bufr_inst/I] -divide_by 1 -add -master_clock i2s_in_bclki0 [get_pins bclk_bufr_inst/O]

set_clock_groups -name async_sys_i2s -asynchronous -group [get_clocks -include_generated_clocks clk_50mhz] -group i2s_in_bclki0

