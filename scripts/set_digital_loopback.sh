sudo /data2/tools/anaconda3/bin/python python/uart/poke.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x8000 -v 0x4140
sudo /data2/tools/anaconda3/bin/python python/uart/peek.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x8000
