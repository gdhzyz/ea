
// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

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
    input  wire       clk,
    input  wire       clk90,
    (* mark_debug = "true" *)input  wire       rst,

    /*
     * Ethernet: 1000BASE-T RGMII
     */
    input  wire       phy_rx_clk,
    input  wire [3:0] phy_rxd,
    input  wire       phy_rx_ctl,
    output wire       phy_tx_clk,
    output wire [3:0] phy_txd,
    output wire       phy_tx_ctl,
    output wire       phy_reset_n
);

// AXI between MAC and Ethernet modules
(* mark_debug = "true" *)wire [7:0] rx_axis_tdata;
(* mark_debug = "true" *)wire rx_axis_tvalid;
(* mark_debug = "true" *)wire rx_axis_tready;
(* mark_debug = "true" *)wire rx_axis_tlast;
(* mark_debug = "true" *)wire rx_axis_tuser;

(* mark_debug = "true" *)wire [7:0] tx_axis_tdata;
(* mark_debug = "true" *)wire tx_axis_tvalid;
(* mark_debug = "true" *)wire tx_axis_tready;
(* mark_debug = "true" *)wire tx_axis_tlast;
(* mark_debug = "true" *)wire tx_axis_tuser;

// Ethernet frame between Ethernet modules and UDP stack
(* mark_debug = "true" *)wire rx_eth_hdr_ready;
(* mark_debug = "true" *)wire rx_eth_hdr_valid;
(* mark_debug = "true" *)wire [47:0] rx_eth_dest_mac;
(* mark_debug = "true" *)wire [47:0] rx_eth_src_mac;
(* mark_debug = "true" *)wire [15:0] rx_eth_type;
(* mark_debug = "true" *)wire [7:0] rx_eth_payload_axis_tdata;
(* mark_debug = "true" *)wire rx_eth_payload_axis_tvalid;
(* mark_debug = "true" *)wire rx_eth_payload_axis_tready;
(* mark_debug = "true" *)wire rx_eth_payload_axis_tlast;
(* mark_debug = "true" *)wire rx_eth_payload_axis_tuser;

(* mark_debug = "true" *)wire tx_eth_hdr_ready;
(* mark_debug = "true" *)wire tx_eth_hdr_valid;
(* mark_debug = "true" *)wire [47:0] tx_eth_dest_mac;
(* mark_debug = "true" *)wire [47:0] tx_eth_src_mac;
(* mark_debug = "true" *)wire [15:0] tx_eth_type;
(* mark_debug = "true" *)wire [7:0] tx_eth_payload_axis_tdata;
(* mark_debug = "true" *)wire tx_eth_payload_axis_tvalid;
(* mark_debug = "true" *)wire tx_eth_payload_axis_tready;
(* mark_debug = "true" *)wire tx_eth_payload_axis_tlast;
(* mark_debug = "true" *)wire tx_eth_payload_axis_tuser;

assign phy_reset_n = !rst;

/*
 * test_sender
 */
test_sender #(
    .LENGTH(512),
    .LOCAL_MAC(48'h02_00_00_00_00_00),
    .DST_MAC(48'h54_14_A7_12_4D_B3),
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(8)
)
test_sender (
    .clk(clk),
    .rst(rst),

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


/*
 * test_receiver
 */
test_receiver #(
    .LENGTH(512),
    .LOCAL_MAC(48'h02_00_00_00_00_00),
    .DST_MAC(48'h02_00_00_00_00_00),
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(8)
)
test_receiver (
    .clk(clk),
    .rst(rst),

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


eth_mac_1g_rgmii_fifo #(
    .TARGET(TARGET),
    .IODDR_STYLE("IODDR"),
    .CLOCK_INPUT_STYLE("BUFR"),
    .USE_CLK90("TRUE"),
    .ENABLE_PADDING(1),
    .MIN_FRAME_LENGTH(64),
    .TX_FIFO_DEPTH(4096),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(4096),
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
    .cfg_rx_enable(1'b1)
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

endmodule

`resetall
