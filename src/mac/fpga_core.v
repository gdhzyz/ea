
// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none
`include "../head.vh"

/*
 * FPGA core logic
 */
module fpga_core #
(
    parameter TARGET = "GENERIC"
)
(
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    input  wire         clk,
    input  wire         clk90,
    input  wire       rst,

    /*
     * Ethernet: 1000BASE-T RGMII
     */
    input  wire         phy_rx_clk,
    input  wire [3:0]   phy_rxd,
    input  wire         phy_rx_ctl,
    output wire         phy_tx_clk,
    output wire [3:0]   phy_txd,
    output wire         phy_tx_ctl,
    output reg          phy_reset_n,

    /*
     * Ethernet: 1000BASE-T RGMII
     */
    output wire         debug_led,
    
    input  wire         enable_jumbo_test,
    output wire [4:0]   jumbo_errors,
    input  wire [4:0]   jumbo_error_clears
);

localparam TIME_200MS = 125 * 1000 * 100 * 2;

// AXI between MAC and Ethernet modules
wire [7:0] rx_axis_tdata;
(* mark_debug = "true" *)wire rx_axis_tvalid;
(* mark_debug = "true" *)wire rx_axis_tready;
(* mark_debug = "true" *)wire rx_axis_tlast;
(* mark_debug = "true" *)wire rx_axis_tuser;

wire [7:0] tx_axis_tdata;
(* mark_debug = "true" *)wire tx_axis_tvalid;
(* mark_debug = "true" *)wire tx_axis_tready;
(* mark_debug = "true" *)wire tx_axis_tlast;
(* mark_debug = "true" *)wire tx_axis_tuser;

// Ethernet frame between Ethernet modules and UDP stack
(* mark_debug = "true" *)wire rx_eth_hdr_ready;
(* mark_debug = "true" *)wire rx_eth_hdr_valid;
wire [47:0] rx_eth_dest_mac;
wire [47:0] rx_eth_src_mac;
wire [15:0] rx_eth_type;
(* mark_debug = "true" *)wire [7:0] rx_eth_payload_axis_tdata;
(* mark_debug = "true" *)wire rx_eth_payload_axis_tvalid;
(* mark_debug = "true" *)wire rx_eth_payload_axis_tready;
(* mark_debug = "true" *)wire rx_eth_payload_axis_tlast;
(* mark_debug = "true" *)wire rx_eth_payload_axis_tuser;

(* mark_debug = "true" *)wire tx_eth_hdr_ready;
(* mark_debug = "true" *)wire tx_eth_hdr_valid;
wire [47:0] tx_eth_dest_mac;
wire [47:0] tx_eth_src_mac;
wire [15:0] tx_eth_type;
(* mark_debug = "true" *)wire [7:0] tx_eth_payload_axis_tdata;
(* mark_debug = "true" *)wire tx_eth_payload_axis_tvalid;
(* mark_debug = "true" *)wire tx_eth_payload_axis_tready;
(* mark_debug = "true" *)wire tx_eth_payload_axis_tlast;
(* mark_debug = "true" *)wire tx_eth_payload_axis_tuser;

wire [23:0] num_1us;

localparam TIME_200MS_BITS = $clog2(TIME_200MS);
reg [TIME_200MS_BITS - 1:0] phy_reset_counter = 0;
always @(posedge clk) begin
    if (rst) begin
        phy_reset_counter <= 'd0;
        phy_reset_n <= 1'b0;
    end else if (phy_reset_counter < TIME_200MS-1) begin
        phy_reset_counter <= phy_reset_counter + 'd1;
        phy_reset_n <= 1'b0;
    end else begin
       phy_reset_counter <= phy_reset_counter;
       phy_reset_n <= 1'b1;
    end
end

/*
 * count packet
 */
(* mark_debug = "true" *)reg [31:0] tx_packet_num=0;
always @(posedge clk) begin
    if (rst) begin
        tx_packet_num <= 0;
    end else if (tx_eth_hdr_valid && tx_eth_hdr_ready) begin
        tx_packet_num <= tx_packet_num + 1;
    end
end

(* mark_debug = "true" *)reg [31:0] rx_packet_num=0;
always @(posedge clk) begin
    if (rst) begin
        rx_packet_num <= 0;
    end else if (rx_eth_hdr_valid 
                 && rx_eth_hdr_ready 
                 && (rx_eth_type == 16'h88B6 || rx_eth_type == 16'h88B5)) begin
        rx_packet_num <= rx_packet_num + 1;
    end
end

/*
 * test_sender
 */
wire [47:0] client_mac = 48'h01_02_03_04_05_06;
wire [47:0] server_mac = 48'h07_08_09_0a_0b_0c;
//wire [47:0] server_mac = 48'h00_e0_4c_60_0d_1c;  // linux usb
//wire [47:0] dst_mac = 48'hfe80_59db_ff3c_edf4_c582;

`ifdef IS_CLIENT
`ifdef DO_DPA_INSIDE_MAC

gen_dpa_pattern #(
    .DATA_LENGTH(64), // actually needs to minus 8, for payload info.
    .DATA_WIDTH(8)
)
gen_dpa_pattern (
    .clk(clk),
    .rst(rst),
    .enable(enable_jumbo_test),

    .src_mac(client_mac),
    .dst_mac(server_mac),

    .m_eth_hdr_valid(tx_eth_hdr_valid),
    .m_eth_hdr_ready(tx_eth_hdr_ready),
    .m_eth_dest_mac(tx_eth_dest_mac),
    .m_eth_src_mac(tx_eth_src_mac),
    .m_eth_type(tx_eth_type),
    .m_eth_payload_axis_tdata(tx_eth_payload_axis_tdata),
    .m_eth_payload_axis_tvalid(tx_eth_payload_axis_tvalid),
    .m_eth_payload_axis_tready(tx_eth_payload_axis_tready),
    .m_eth_payload_axis_tlast(tx_eth_payload_axis_tlast),
    .m_eth_payload_axis_tuser(tx_eth_payload_axis_tuser)
);

assign rx_eth_hdr_ready = 1'b1;
assign rx_eth_payload_axis_tready = 1'b1;

`else // DO_DPA_INSIDE_MAC
test_gen_pattern #(
    .DATA_LENGTH(64), // actually needs to minus 8, for payload info.
    .DATA_WIDTH(8)
)
test_gen_pattern (
    .clk(clk),
    .rst(rst),
    .enable(enable_jumbo_test),

    .packet_index(tx_packet_num),
    .src_mac(client_mac),
    .dst_mac(server_mac),
    .timestamp(num_1us),
    .is_data(),
    .is_timestamp0(),
    .is_timestamp1(),
    .is_timestamp2(),

    .m_eth_hdr_valid(tx_eth_hdr_valid),
    .m_eth_hdr_ready(tx_eth_hdr_ready),
    .m_eth_dest_mac(tx_eth_dest_mac),
    .m_eth_src_mac(tx_eth_src_mac),
    .m_eth_type(tx_eth_type),
    .m_eth_payload_axis_tdata(tx_eth_payload_axis_tdata),
    .m_eth_payload_axis_tvalid(tx_eth_payload_axis_tvalid),
    .m_eth_payload_axis_tready(tx_eth_payload_axis_tready),
    .m_eth_payload_axis_tlast(tx_eth_payload_axis_tlast),
    .m_eth_payload_axis_tuser(tx_eth_payload_axis_tuser)
);

test_pattern_recv #(
    .DATA_LENGTH(64),
    .DATA_WIDTH(8)
) test_pattern_recv (
    .clk(clk),
    .rst(rst),
    .enable(1'b1),

    .packet_index(rx_packet_num),
    .src_mac(client_mac),
    .dst_mac(server_mac),
    .timestamp(num_1us),

    .s_eth_hdr_valid(rx_eth_hdr_valid),
    .s_eth_hdr_ready(rx_eth_hdr_ready),
    .s_eth_dest_mac(rx_eth_dest_mac),
    .s_eth_src_mac(rx_eth_src_mac),
    .s_eth_type(rx_eth_type),
    .s_eth_payload_axis_tdata(rx_eth_payload_axis_tdata),
    .s_eth_payload_axis_tvalid(rx_eth_payload_axis_tvalid),
    .s_eth_payload_axis_tready(rx_eth_payload_axis_tready),
    .s_eth_payload_axis_tlast(rx_eth_payload_axis_tlast),
    .s_eth_payload_axis_tuser(rx_eth_payload_axis_tuser)
);
`endif //DO_DPA_INSIDE_MAC

`else // IS_CLIENT. Not a client, just a loopback server.

assign tx_eth_hdr_valid = rx_eth_hdr_valid;
assign rx_eth_hdr_ready = tx_eth_hdr_ready;
assign tx_eth_dest_mac = rx_eth_src_mac;
assign tx_eth_src_mac = server_mac;
assign tx_eth_type = 16'h88b6;

assign tx_eth_payload_axis_tvalid = rx_eth_payload_axis_tvalid;
assign tx_eth_payload_axis_tdata = rx_eth_payload_axis_tdata;
assign rx_eth_payload_axis_tready = tx_eth_payload_axis_tready;
assign tx_eth_payload_axis_tlast = rx_eth_payload_axis_tlast;
assign tx_eth_payload_axis_tuser = rx_eth_payload_axis_tuser;
`endif // IS_CLIENT

//
///*
// * test_receiver
// */
//test_receiver #(
//    .LENGTH(512),
//    .LOCAL_MAC(48'h02_00_00_00_00_00),
//    .DST_MAC(48'h02_00_00_00_00_00),
//    // Width of AXI stream interfaces in bits
//    .DATA_WIDTH(8)
//)
//test_receiver (
//    .clk(clk),
//    .rst(rst),
//
//    .s_eth_hdr_valid(rx_eth_hdr_valid),
//    .s_eth_hdr_ready(rx_eth_hdr_ready),
//    .s_eth_dest_mac(rx_eth_dest_mac),
//    .s_eth_src_mac(rx_eth_src_mac),
//    .s_eth_type(rx_eth_type),
//    .s_eth_payload_axis_tdata(rx_eth_payload_axis_tdata),
//    .s_eth_payload_axis_tvalid(rx_eth_payload_axis_tvalid),
//    .s_eth_payload_axis_tready(rx_eth_payload_axis_tready),
//    .s_eth_payload_axis_tlast(rx_eth_payload_axis_tlast),
//    .s_eth_payload_axis_tuser(rx_eth_payload_axis_tuser)
//);


eth_mac_1g_rgmii_fifo #(
    .TARGET(TARGET),
    .IODDR_STYLE("IODDR"),
    .CLOCK_INPUT_STYLE("BUFR"),
    .USE_CLK90("TRUE"),
    .ENABLE_PADDING(1),
    .MIN_FRAME_LENGTH(64),
    .TX_FIFO_DEPTH(8192),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(8192),
    .RX_FRAME_FIFO(1)
)
eth_mac_inst (
    .gtx_clk(clk),
    .gtx_clk90(clk90),
    .gtx_rst(rst),
    .logic_clk(clk),
    .logic_rst(rst),

    .tx_axis_tdata(tx_axis_tdata),
    .tx_axis_tvalid(tx_axis_tvalid),
    .tx_axis_tready(tx_axis_tready),
    .tx_axis_tlast(tx_axis_tlast),
    .tx_axis_tuser(tx_axis_tuser),

    .rx_axis_tdata(rx_axis_tdata),
    .rx_axis_tvalid(rx_axis_tvalid),
    .rx_axis_tready(rx_axis_tready),
    .rx_axis_tlast(rx_axis_tlast),
    .rx_axis_tuser(rx_axis_tuser),

    .rgmii_rx_clk(phy_rx_clk),
    .rgmii_rxd(phy_rxd),
    .rgmii_rx_ctl(phy_rx_ctl),
    .rgmii_tx_clk(phy_tx_clk),
    .rgmii_txd(phy_txd),
    .rgmii_tx_ctl(phy_tx_ctl),

    .tx_fifo_overflow(),
    .tx_fifo_bad_frame(),
    .tx_fifo_good_frame(),
    .rx_error_bad_frame(),
    .rx_error_bad_fcs(),
    .rx_fifo_overflow(),
    .rx_fifo_bad_frame(),
    .rx_fifo_good_frame(),
    .speed(),

    .cfg_ifg(8'd12),
    .cfg_tx_enable(1'b1),
    .cfg_rx_enable(1'b1),
    .jumbo_errors(jumbo_errors),
    .jumbo_error_clears(jumbo_error_clears)
);

eth_axis_rx
eth_axis_rx_inst (
    .clk(clk),
    .rst(rst),
    // AXI input
    .s_axis_tdata(rx_axis_tdata),
    .s_axis_tvalid(rx_axis_tvalid),
    .s_axis_tready(rx_axis_tready),
    .s_axis_tlast(rx_axis_tlast),
    .s_axis_tuser(rx_axis_tuser),
    // Ethernet frame output
    .m_eth_hdr_valid(rx_eth_hdr_valid),
    .m_eth_hdr_ready(rx_eth_hdr_ready),
    .m_eth_dest_mac(rx_eth_dest_mac),
    .m_eth_src_mac(rx_eth_src_mac),
    .m_eth_type(rx_eth_type),
    .m_eth_payload_axis_tdata(rx_eth_payload_axis_tdata),
    .m_eth_payload_axis_tvalid(rx_eth_payload_axis_tvalid),
    .m_eth_payload_axis_tready(rx_eth_payload_axis_tready),
    .m_eth_payload_axis_tlast(rx_eth_payload_axis_tlast),
    .m_eth_payload_axis_tuser(rx_eth_payload_axis_tuser),
    // Status signals
    .busy(),
    .error_header_early_termination()
);

eth_axis_tx
eth_axis_tx_inst (
    .clk(clk),
    .rst(rst),
    // Ethernet frame input
    .s_eth_hdr_valid(tx_eth_hdr_valid),
    .s_eth_hdr_ready(tx_eth_hdr_ready),
    .s_eth_dest_mac(tx_eth_dest_mac),
    .s_eth_src_mac(tx_eth_src_mac),
    .s_eth_type(tx_eth_type),
    .s_eth_payload_axis_tdata(tx_eth_payload_axis_tdata),
    .s_eth_payload_axis_tvalid(tx_eth_payload_axis_tvalid),
    .s_eth_payload_axis_tready(tx_eth_payload_axis_tready),
    .s_eth_payload_axis_tlast(tx_eth_payload_axis_tlast),
    .s_eth_payload_axis_tuser(tx_eth_payload_axis_tuser),
    // AXI output
    .m_axis_tdata(tx_axis_tdata),
    .m_axis_tvalid(tx_axis_tvalid),
    .m_axis_tready(tx_axis_tready),
    .m_axis_tlast(tx_axis_tlast),
    .m_axis_tuser(tx_axis_tuser),
    // Status signals
    .busy()
);


gen_timestamp 
#(
    .CYCLE_NUM_1US(125)
) gen_timestamp 
(
    .clk(clk),
    .rst(rst),
    .timestamp(num_1us)
);

assign debug_led = rx_axis_tvalid;



endmodule

`resetall
