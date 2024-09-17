#include <pcap.h>
#include <iostream>
#include <cstring>
#include <cstdlib>


#include <fstream>

static int global_index = 1;
std::ofstream outFile("output.bin", std::ios::out | std::ios::binary);
// Callback function that is invoked by pcap for each captured packet
void packet_handler(u_char *user_data, const struct pcap_pkthdr *pkthdr, const u_char *packet) {
    //std::cout << "Packet length: " << pkthdr->len << std::endl;
    //std::cout << "Packet contents:" << std::endl;

    /* 
        src mac,    6 octs
        dst mac,    6 octs
        flag,       1 oct
        timestamp,  2 octs
        3zeros,     3 octs
        packet id,  2 octs 
    */
    //for (size_t i = 0; i < pkthdr->len; ++i) {
    //    if (i % 16 == 0) {
    //        std::cout << std::endl;
    //    }
    //    std::printf("%02x ", packet[i]);
    //}
    //std::printf("%04x: %02x%02x\n", global_index++, packet[21], packet[20]);
    //std::cout << std::endl << std::endl;

     outFile.write(reinterpret_cast<const char*>(&global_index), 2);
     outFile.write(reinterpret_cast<const char*>(&packet[20]), 1);
     outFile.write(reinterpret_cast<const char*>(&packet[21]), 1);
     global_index++;
}

int main() {
    char errbuf[PCAP_ERRBUF_SIZE];
    pcap_if_t *all_devs, *device;
    int interface_num, i = 0;

    // Retrieve the device list
    if (pcap_findalldevs(&all_devs, errbuf) == -1) {
        std::cerr << "Error in pcap_findalldevs: " << errbuf << std::endl;
        return 1;
    }

    // Print the list of devices
    std::cout << "Available interfaces:" << std::endl;
    for (device = all_devs; device; device = device->next) {
        std::cout << ++i << ": " << device->name;
        if (device->description) {
            std::cout << " (" << device->description << ")";
        } else {
            std::cout << " (No description available)";
        }
        std::cout << std::endl;
    }

    if (i == 0) {
        std::cerr << "No interfaces found! Make sure libpcap is installed." << std::endl;
        return 1;
    }

    // Ask user to select an interface
    std::cout << "Enter the interface number (1-" << i << "): ";
    std::cin >> interface_num;

    if (interface_num < 1 || interface_num > i) {
        std::cerr << "Invalid interface number." << std::endl;
        pcap_freealldevs(all_devs);
        return 1;
    }

    // Select the interface
    for (device = all_devs, i = 0; i < interface_num - 1; device = device->next, ++i);

    // Open the device for capturing with a larger buffer size
    int buffer_size = 2 * 1024 * 1024;  // 2 MB buffer size
    pcap_t *handle = pcap_create(device->name, errbuf);
    if (handle == nullptr) {
        std::cerr << "Couldn't open device " << device->name << ": " << errbuf << std::endl;
        pcap_freealldevs(all_devs);
        return 1;
    }

    if (pcap_set_buffer_size(handle, buffer_size) != 0) {
        std::cerr << "Couldn't set buffer size: " << pcap_geterr(handle) << std::endl;
        pcap_freealldevs(all_devs);
        return 1;
    }

    if (pcap_set_promisc(handle, 1) != 0) {
        std::cerr << "Couldn't set promiscuous mode: " << pcap_geterr(handle) << std::endl;
        pcap_freealldevs(all_devs);
        return 1;
    }

    if (pcap_activate(handle) != 0) {
        std::cerr << "Couldn't activate handle: " << pcap_geterr(handle) << std::endl;
        pcap_freealldevs(all_devs);
        return 1;
    }

    std::cout << "Listening on " << device->name << " with buffer size " << buffer_size << " bytes..." << std::endl;

    // Start capturing packets
    pcap_loop(handle, 1, packet_handler, nullptr);

    // Close the handle
    pcap_close(handle);
    pcap_freealldevs(all_devs);

    return 0;
}
