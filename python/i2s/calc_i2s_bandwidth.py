max_bclk = 24.576 * 1000 * 1000
max_sr = 96 * 1000  # max sample rate
channels = 16
available_bandwidth = 1000  # in Mbps

#            preamble + SFD + mac * 2 + type + crc + ifg
eth_overlap = 7       + 1   + 6 * 2   + 2    + 4   + 12
# user overlap
user_overlap = 8

overlap = eth_overlap + user_overlap

max_payload = max_bclk * channels
max_overlap = overlap * max_sr * channels

max_payload_bits = max_payload / 1000 / 1000 # in Mbps
max_overlap_bits = max_overlap * 8 / 1000 / 1000 # in Mbps
max_bandwidth_bits = max_payload_bits + max_overlap_bits # in Mbps

print(f'available_bandwidth {available_bandwidth}Mbps expected max bandwidth {max_bandwidth_bits}Mbps max_payload {max_payload_bits}Mbps max_overlap_bits {max_overlap_bits}Mbps')
