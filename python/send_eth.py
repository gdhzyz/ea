from scapy.all import Ether, sendp

#dst_mac = "54:14:A7:12:4D:B3" # windows pc
dst_mac = "02:00:00:00:00:00" # board

# 定义自定义EtherType
custom_ethertype = 0x88B5  # 例如，自定义EtherType值

# 创建以太网帧
eth_frame = Ether(dst=dst_mac, src="00:e0:4c:60:0d:1c", type=custom_ethertype)

# 添加自定义负载
custom_payload = b"Hello, this is a custom payload!" # len 32
custom_payload = custom_payload * 8 # len 256
eth_frame = eth_frame / custom_payload

# 打印以太网帧
eth_frame.show()

# 发送以太网帧
for i in range(1000):
    sendp(eth_frame, iface="enx00e04c600d1c")  # 替换为你的实际网络接口