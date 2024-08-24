create_clock -period 40.690 -name i2s_in_mclki [get_ports i2s_in_mclki]

set_property -dict {LOC J19 IOSTANDARD LVCMOS33} [get_ports i2s_in_mclki]
set_property -dict {LOC J20 IOSTANDARD LVCMOS33} [get_ports {i2s_in_bclk[0]}]
set_property -dict {LOC H17 IOSTANDARD LVCMOS33} [get_ports {i2s_in_lrck[0]}]
set_property -dict {LOC H18 IOSTANDARD LVCMOS33} [get_ports {i2s_in_datin[0]}]
set_property -dict {LOC J17 IOSTANDARD LVCMOS33} [get_ports {i2s_out_datout[0]}]

# link: https://docs.amd.com/r/en-US/ug835-vivado-tcl-commands/create_generated_clock
# internal generated output bclk
create_generated_clock -name i2s_in_bclko0 -source [get_pins i2s_in_fifo/i2s_in/i2s_mclki_mmcm_inst/CLKOUT0] -divide_by 64 [get_pins i2s_in_fifo/i2s_in/gen_block[0].i2s_freq_divider/bclk_freq_divider/oclk_reg_reg/Q]
# external generated input bclk
create_clock -period 40.690 -name i2s_in_bclki0 [get_ports {i2s_in_bclk[0]}]
# muxed bclk
#create_generated_clock -name i2s_in_bclk0_bufr0 -source [get_pins i2s_in_fifo/i2s_in/gen_block[0].bclk_bufr_inst/I] [get_pins i2s_in_fifo/i2s_in/gen_block[0].bclk_bufr_inst/O] -master_clock i2s_in_bclko0 -add -divide_by 1
#create_generated_clock -name i2s_in_bclk0_bufr1 -source [get_pins i2s_in_fifo/i2s_in/gen_block[0].bclk_bufr_inst/I] [get_pins i2s_in_fifo/i2s_in/gen_block[0].bclk_bufr_inst/O] -master_clock i2s_in_bclki0 -add -divide_by 1

set_clock_groups -name async_sys_i2s -asynchronous -group [get_clocks -include_generated_clocks clk_50mhz] \
                                                   -group [get_clocks -include_generated_clocks i2s_in_mclki] \
                                                   -group [get_clocks -include_generated_clocks i2s_in_bclki0] \
                                                   -group [get_clocks -include_generated_clocks i2s_in_bclko0]

# temp for mclk place work around
set_property BEL BUFR [get_cells i2s_in_fifo/i2s_in/mclki_bufr_inst]
set_property LOC BUFR_X0Y5 [get_cells i2s_in_fifo/i2s_in/mclki_bufr_inst]