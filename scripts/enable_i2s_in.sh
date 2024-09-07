# tdm_num, tdm8
sudo /data2/tools/anaconda3/bin/python python/uart/poke.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x1000 -v 0x3
# is_master, true
sudo /data2/tools/anaconda3/bin/python python/uart/poke.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x1010 -v 0x1
# fpga_index
sudo /data2/tools/anaconda3/bin/python python/uart/poke.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x1030 -v 0x1
# word_width, 32b
sudo /data2/tools/anaconda3/bin/python python/uart/poke.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x1040 -v 0x1
# valid_word_width, 32b
sudo /data2/tools/anaconda3/bin/python python/uart/poke.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x1050 -v 0x3
# lrck_is_pulse, 50%
sudo /data2/tools/anaconda3/bin/python python/uart/poke.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x1060 -v 0x0
# lrck_polarity, start a frame t the falling edge.
sudo /data2/tools/anaconda3/bin/python python/uart/poke.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x1070 -v 0x1
# lrck_alignment, delay one clock
sudo /data2/tools/anaconda3/bin/python python/uart/poke.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x1080 -v 0x1
# i2s_index
sudo /data2/tools/anaconda3/bin/python python/uart/poke.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x1090 -v 0x1
# bclk_factor, 1
sudo /data2/tools/anaconda3/bin/python python/uart/poke.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x1300 -v 0x1
# enable
sudo /data2/tools/anaconda3/bin/python python/uart/poke.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x1020 -v 0x1
