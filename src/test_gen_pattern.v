
`resetall
`timescale 1ns / 1ps
`default_nettype none

module test_gen_pattern # 
(
    parameter DATA_LENGTH = 64,
    parameter DATA_WIDTH = 8

)
(
    input  wire                     clk,
    input  wire                     rst,

    /*
     * Global information
     */
    input  wire  [15:0]             packet_index,
    input  wire  [47:0]             src_mac,
    input  wire  [47:0]             dst_mac,
    input  wire  [15:0]             timestamp,
    output wire                     is_data,
    output wire                     is_timestamp0,
    output wire                     is_timestamp1,

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

localparam S_IDLE = 0;
localparam S_TYPE_FLAG = 1;
localparam S_TIMESTAMP = 2;
localparam S_3ZEROS = 3;
localparam S_PACKET_INDEX = 4;
localparam S_DATA = 5;

(* mark_debug = "true" *)reg [3:0] state_reg = S_IDLE, state_next;
(* mark_debug = "true" *)reg [DATA_LENGTH_BITS-1:0] count_reg = 0, count_next;
(* mark_debug = "true" *)reg clear;
wire fire_payload = m_eth_payload_axis_tvalid && m_eth_payload_axis_tready;
reg [DATA_WIDTH-1:0] tdata;
reg [DATA_WIDTH-1:0] data_counter=0;

always @* begin
    state_next = state_reg;
    clear = 1'b1;

    case (state_reg)
        S_IDLE: begin
            state_next = S_TYPE_FLAG;
            clear = 1'b1;
        end
        S_TYPE_FLAG: begin
            if (fire_payload) begin
               state_next = S_TIMESTAMP;
               clear = 1'b1;
               tdata = 8'h7;
            end else begin
                state_next = S_TYPE_FLAG;
                clear = 1'b0;
            end
        end
        S_TIMESTAMP: begin
            if (fire_payload && count_reg == 1) begin
                state_next = S_3ZEROS;
                clear = 1'b1;
            end else begin
                state_next = S_TIMESTAMP;
                clear = 1'b0;
            end

            if (count_reg == 1) begin
                tdata = timestamp[15:8];
            end else begin
                tdata = timestamp[7:0];
            end
        end
        S_3ZEROS: begin
            if (fire_payload && count_reg == 2) begin
                state_next = S_PACKET_INDEX;
                clear = 1'b1;
            end else begin
                state_next = S_3ZEROS;
                clear = 1'b0;
            end
            tdata = 8'd0;
        end
        S_PACKET_INDEX: begin
            if (fire_payload && count_reg == 1) begin
                state_next = S_DATA;
                clear = 1'b1;
            end else begin
                state_next = S_PACKET_INDEX;
                clear = 1'b0;
            end

            if (count_reg == 1) begin
                tdata = packet_index[15:8];
            end else begin
                tdata = packet_index[7:0];
            end
        end
        S_DATA: begin
            if (fire_payload && count_reg == DATA_LENGTH - 1) begin
                state_next = S_TYPE_FLAG;
                clear = 1'b1;
            end else begin
                state_next = S_DATA;
                clear = 1'b0;
            end
            tdata = data_counter;
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

always @(posedge clk) begin
    if (rst) begin
        data_counter <= 'd0;
    end else if (fire_payload && state_reg == S_DATA) begin
        data_counter <= data_counter + 'd1;
    end
end

assign m_eth_dest_mac = dst_mac;
assign m_eth_src_mac = src_mac;
assign m_eth_type = 16'h88B5;
assign m_eth_hdr_valid = state_reg != S_IDLE;
assign m_eth_payload_axis_tvalid = state_reg != S_IDLE;
assign m_eth_payload_axis_tdata = tdata;
assign m_eth_payload_axis_tlast = state_reg == S_DATA && count_reg == DATA_LENGTH - 1;
assign m_eth_payload_axis_tuser = 1'b0;

assign is_data = state_reg == S_DATA;
assign is_timestamp0 = state_reg == S_TIMESTAMP && count_reg == 0;
assign is_timestamp1 = state_reg == S_TIMESTAMP && count_reg == 1;

endmodule

`resetall
