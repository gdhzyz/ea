
`resetall
`timescale 1ns / 1ps
`default_nettype none

module test_pattern_recv # 
(
    parameter DATA_LENGTH = 64,
    parameter DATA_WIDTH = 8

)
(
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     enable,

    /*
     * Global information
     */
    input wire  [15:0]              packet_index,
    input wire  [47:0]              src_mac,
    input wire  [47:0]              dst_mac,
    input wire  [23:0]              timestamp,

    (* mark_debug = "true" *)output reg                      error=0,
    (* mark_debug = "true" *)output reg  [23:0]              max_time_gap=0,

    /*
     * Ethernet frame input
     */
    input  wire                     s_eth_hdr_valid,
    output wire                     s_eth_hdr_ready,
    input  wire [47:0]              s_eth_dest_mac,
    input  wire [47:0]              s_eth_src_mac,
    input  wire [15:0]              s_eth_type,
    (* mark_debug = "true" *)input  wire [DATA_WIDTH-1:0]    s_eth_payload_axis_tdata,
    input  wire                     s_eth_payload_axis_tvalid,
    output wire                     s_eth_payload_axis_tready,
    input  wire                     s_eth_payload_axis_tlast,
    input  wire                     s_eth_payload_axis_tuser
);

wire                     gen_is_data;
wire                     gen_is_timestamp0;
wire                     gen_is_timestamp1;
wire                     gen_is_timestamp2;

wire                     gen_eth_hdr_valid;
wire                     gen_eth_hdr_ready;
wire [47:0]              gen_eth_dest_mac;
wire [47:0]              gen_eth_src_mac;
wire [15:0]              gen_eth_type;
(* mark_debug = "true" *)wire [DATA_WIDTH-1:0]    gen_eth_payload_axis_tdata;
wire                     gen_eth_payload_axis_tvalid;
wire                     gen_eth_payload_axis_tready;
wire                     gen_eth_payload_axis_tlast;
wire                     gen_eth_payload_axis_tuser;

test_gen_pattern 
#(
    .DATA_LENGTH(DATA_LENGTH),
    .DATA_WIDTH(DATA_WIDTH)
) test_gen_pattern 
(
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .packet_index(packet_index),
    .timestamp(24'd0),
    .src_mac(src_mac),
    .dst_mac(dst_mac),
    .is_data(gen_is_data),
    .is_timestamp0(gen_is_timestamp0),
    .is_timestamp1(gen_is_timestamp1),
    .is_timestamp2(gen_is_timestamp2),
    .m_eth_hdr_valid(gen_eth_hdr_valid),
    .m_eth_hdr_ready(gen_eth_hdr_ready),
    .m_eth_dest_mac(gen_eth_dest_mac),
    .m_eth_src_mac(gen_eth_src_mac),
    .m_eth_type(gen_eth_type),
    .m_eth_payload_axis_tdata(gen_eth_payload_axis_tdata),
    .m_eth_payload_axis_tvalid(gen_eth_payload_axis_tvalid),
    .m_eth_payload_axis_tready(gen_eth_payload_axis_tready),
    .m_eth_payload_axis_tlast(gen_eth_payload_axis_tlast),
    .m_eth_payload_axis_tuser(gen_eth_payload_axis_tuser)
);

assign gen_eth_payload_axis_tready = s_eth_payload_axis_tvalid;
assign s_eth_payload_axis_tready = gen_eth_payload_axis_tvalid;
assign gen_eth_hdr_ready = s_eth_hdr_valid;
assign s_eth_hdr_ready = gen_eth_hdr_valid;

wire fire = s_eth_payload_axis_tvalid && s_eth_payload_axis_tready;
always @(posedge clk) begin
    if (rst) begin
        error <= 1'b0;
    end else if (fire) begin
        if (gen_eth_payload_axis_tdata != s_eth_payload_axis_tdata && gen_is_data) begin
            error <= 1'b1;
        end
    end
end

reg [23:0] rx_timestamp=0;
always @(posedge clk) begin
    if (gen_is_timestamp0 && fire) begin
        rx_timestamp[7:0] <= s_eth_payload_axis_tdata;
    end
    if (gen_is_timestamp1 && fire) begin
        rx_timestamp[15:8] <= s_eth_payload_axis_tdata;
    end
    if (gen_is_timestamp2 && fire) begin
        rx_timestamp[23:16] <= s_eth_payload_axis_tdata;
    end
end

(* mark_debug = "true" *)reg rx_timestamp_valid=0;
always @(posedge clk) begin
    if (rst) begin
        rx_timestamp_valid <= 0;
    end else begin
        rx_timestamp_valid <= gen_is_timestamp2 && fire;
    end
end

reg [23:0] time_gap=0;
wire [23:0] time_gap_w = timestamp - rx_timestamp;
always @(posedge clk) begin
    if (rst) begin
        time_gap <= 0;
    end else if (rx_timestamp_valid) begin
        if (time_gap_w < 24'h0FFFFF) begin // overflow because of timestamp wrapback.
            time_gap <= time_gap_w;
        end else begin
            time_gap <= time_gap;
        end
    end
end

always @(posedge clk) begin
    if (rst) begin
        max_time_gap <= 0;
    end
    else if (time_gap > max_time_gap) begin
        max_time_gap <= time_gap;
    end
end

endmodule

`resetall
