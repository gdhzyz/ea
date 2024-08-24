# set digital loopback
# 1000M loopback
sudo /data2/tools/anaconda3/bin/python python/uart/poke.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x8000 -v 0x4140
# 100M loopback
#sudo /data2/tools/anaconda3/bin/python python/uart/poke.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x8000 -v 0x6100
# set extend reg addr for jumbo
sudo /data2/tools/anaconda3/bin/python python/uart/poke.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x801E -v 0x0000
sudo /data2/tools/anaconda3/bin/python python/uart/peek.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x801E
# read extend reg for jumbo
sudo /data2/tools/anaconda3/bin/python python/uart/peek.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x801F
# set jumbo frame
sudo /data2/tools/anaconda3/bin/python python/uart/poke.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x801F -v 0x1cad
# start jumbo test
sudo /data2/tools/anaconda3/bin/python python/uart/poke.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x030C -v 0x1
