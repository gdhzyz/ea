#!/bin/bash

# 设置要列出文件的目录
directory="./"

# 获取目录中的所有文件
files=$(find "$directory" -type f -name "*.v")

# 打印所有文件
for file in $files; do
    echo "$PWD/$file"
done
