
# 设置工作库
vlib work

# 设置要列出文件的目录
vlog -work work -f ./src/vlog_files.f
vcom -work work -f ./src/vhdl_files.f

# 编译测试平台文件
vlog -work work -f ./sim/vlog_files.f
#vcom -work work -f ./sim/vhdl_files.f

# 启动仿真并使用vopt进行优化，同时保留调试信息
vopt mdio_tb -o mdio_tb_opt +acc=npr

# 启动仿真
vsim -L work mdio_tb_opt

# 添加波形信号
add wave *

# 运行仿真
run -all

# 或者运行指定的时间
# run 100ns

# 保存波形到文件
#write format wlf -force ./sim/wave/uart.wlf

# 关闭仿真
#quit -f
