
# 设置工作库
vlib work

# 设置要列出文件的目录
vlog -work work -f ./src/compile_files.f

# 编译测试平台文件
vlog -work work -f ./sim/file_list.f

# 启动仿真并使用vopt进行优化，同时保留调试信息
vopt decouple_tb -o decouple_tb_opt +acc=npr

# 启动仿真
vsim -L work decouple_tb_opt

# 添加波形信号
add wave -position insertpoint  \
sim:/decouple_tb/dut/DATA_WIDTH \
sim:/decouple_tb/dut/KEEP_ENABLE \
sim:/decouple_tb/dut/KEEP_WIDTH \
sim:/decouple_tb/dut/clk \
sim:/decouple_tb/dut/rst \
sim:/decouple_tb/dut/m_axis_tdata \
sim:/decouple_tb/dut/m_axis_tkeep \
sim:/decouple_tb/dut/m_axis_tvalid \
sim:/decouple_tb/dut/m_axis_tready \
sim:/decouple_tb/dut/m_axis_tlast \
sim:/decouple_tb/dut/m_axis_tuser \
sim:/decouple_tb/dut/s_axis_tdata \
sim:/decouple_tb/dut/s_axis_tkeep \
sim:/decouple_tb/dut/s_axis_tvalid \
sim:/decouple_tb/dut/s_axis_tready \
sim:/decouple_tb/dut/s_axis_tlast \
sim:/decouple_tb/dut/s_axis_tuser \
sim:/decouple_tb/dut/m_axis_tdata_reg \
sim:/decouple_tb/dut/m_axis_tkeep_reg \
sim:/decouple_tb/dut/m_axis_tvalid_reg \
sim:/decouple_tb/dut/m_axis_tvalid_next \
sim:/decouple_tb/dut/m_axis_tlast_reg \
sim:/decouple_tb/dut/m_axis_tuser_reg \
sim:/decouple_tb/dut/temp_m_axis_tdata_reg \
sim:/decouple_tb/dut/temp_m_axis_tkeep_reg \
sim:/decouple_tb/dut/temp_m_axis_tvalid_reg \
sim:/decouple_tb/dut/temp_m_axis_tvalid_next \
sim:/decouple_tb/dut/temp_m_axis_tlast_reg \
sim:/decouple_tb/dut/temp_m_axis_tuser_reg \
sim:/decouple_tb/dut/store_axis_int_to_output \
sim:/decouple_tb/dut/store_axis_int_to_temp \
sim:/decouple_tb/dut/store_axis_temp_to_output \
sim:/decouple_tb/dut/m_axis_tready_int_early \
sim:/decouple_tb/dut/m_axis_tready_int_reg

# 运行仿真
run -all

# 或者运行指定的时间
# run 100ns

# 保存波形到文件
#write format wlf -force ./sim/wave/uart.wlf

# 关闭仿真
#quit -f
