
`resetall
`timescale 1ns / 1ps
`default_nettype none

module gen_dpa_pattern # 
(
    parameter DATA_LENGTH = 8192,
    parameter DATA_WIDTH = 8

)
(
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     enable,

    /*
     * Global information
     */
    input  wire  [47:0]             src_mac,
    input  wire  [47:0]             dst_mac,

    /*
     * Ethernet frame output
     */
    output wire                     m_eth_hdr_valid,
    input  wire                     m_eth_hdr_ready,
    output wire [47:0]              m_eth_dest_mac,
    output wire [47:0]              m_eth_src_mac,
    output wire [15:0]              m_eth_type,
    output wire [DATA_WIDTH-1:0]    m_eth_payload_axis_tdata,
    output wire                     m_eth_payload_axis_tvalid,
    input  wire                     m_eth_payload_axis_tready,
    output wire                     m_eth_payload_axis_tlast,
    output wire                     m_eth_payload_axis_tuser
);

localparam DATA_LENGTH_BITS = $clog2(DATA_LENGTH);
localparam DPA_PATTERN = 20'b0000_0000_0011_1111_1111;

localparam S_IDLE = 0;
localparam S_DATA = 1;

reg [0:0] state_reg = S_IDLE, state_next;
reg [DATA_LENGTH_BITS-1:0] count_reg = 0, count_next;
reg clear;
wire fire_payload = m_eth_payload_axis_tvalid && m_eth_payload_axis_tready;
reg [DATA_WIDTH-1:0] tdata;
reg [DATA_WIDTH-1:0] data_counter=0;

reg [19:0] dpa_pattern=DPA_PATTERN;
wire [1:0] dpa_out_one = dpa_pattern[19:18];
wire [7:0] dpa_out = {dpa_out_one[1], dpa_out_one[1], dpa_out_one[1], dpa_out_one[1],
                      dpa_out_one[0], dpa_out_one[0], dpa_out_one[0], dpa_out_one[0]};
always @(posedge clk) begin
    if (rst) begin
        dpa_pattern <= DPA_PATTERN;
    end else if (fire_payload) begin
        dpa_pattern <= {dpa_pattern[17:0], dpa_pattern[19:18]};
    end
end

always @* begin
    tdata = dpa_out;
    state_next = state_reg;
    clear = 1'b1;

    case (state_reg)
        S_IDLE: begin
            if (enable) begin
                state_next = S_DATA;
                clear = 1'b0;
            end
        end
        S_DATA: begin
            if (fire_payload && count_reg == DATA_LENGTH - 1) begin
                state_next = S_IDLE;
                clear = 1'b1;
            end else begin
                state_next = S_DATA;
                clear = 1'b0;
            end
        end
    endcase

    count_next = count_reg;
    if (clear) begin
        count_next = 0;
    end else if (fire_payload) begin
        count_next = count_reg + 1;
    end

end

always @(posedge clk) begin
    if (rst) begin
        state_reg <= S_IDLE;
    end else begin
        state_reg <= state_next;
    end
end

always @(posedge clk) begin
    count_reg <= count_next;
end

assign m_eth_dest_mac = dst_mac;
assign m_eth_src_mac = src_mac;
assign m_eth_type = 16'h88B5;
assign m_eth_hdr_valid = state_reg == S_IDLE && enable;
assign m_eth_payload_axis_tvalid = 1'b1;
assign m_eth_payload_axis_tdata = tdata;
assign m_eth_payload_axis_tlast = state_reg == S_DATA && count_reg == DATA_LENGTH - 1;
assign m_eth_payload_axis_tuser = 1'b0;

endmodule

`resetall
