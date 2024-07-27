#!/bin/bash

# 设置要列出文件的目录
directory=$1
vlog_file="vlog_files.f"
vhdl_file="vhdl_files.f"

# 获取目录中的所有verilog文件
files=$(find "$directory" -type f -name "*.v")

# 打印所有verilog文件
f="$1/$vlog_file"
rm $f
for file in $files; do
    echo "$PWD/$file" >> $f
done

# 获取目录中的所有vhdl文件
files=$(find "$directory" -type f -name "*.vhd")

# 打印所有verilog文件
f="$1/$vhdl_file"
rm $f
for file in $files; do
    echo "$PWD/$file" >> $f
done
