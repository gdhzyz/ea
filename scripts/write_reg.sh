#sudo /data2/tools/anaconda3/bin/python python/uart/poke.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x8000 -v 0x4140
#sudo /data2/tools/anaconda3/bin/python python/uart/poke.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x801E -v 0x000A
#sudo /data2/tools/anaconda3/bin/python python/uart/poke.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x801F -v 0x0218

sudo /data2/tools/anaconda3/bin/python python/uart/poke.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x801E -v 0x000C
sudo /data2/tools/anaconda3/bin/python python/uart/peek.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x801E
sudo /data2/tools/anaconda3/bin/python python/uart/peek.py -t uart -d /dev/ttyUSB0 -b 115200 -a 0x801F

