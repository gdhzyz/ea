
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

    input wire  [15:0]              packet_num,
    input wire  [47:0]              src_mac,
    input wire  [47:0]              dst_mac,

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
localparam S_PACKET_NUM = 4;
localparam S_DATA = 5;

reg [3:0] state_reg = S_IDLE, state_next;
reg [DATA_LENGTH_BITS-1:0] count = 0;
reg clear;
wire fire = m_eth_hdr_valid && m_eth_hdr_ready;

always @* begin
    state_next = state_reg;
    clear = 1'b1;

    case (state_reg)
        S_IDLE: begin
            state_next = S_TYPE_FLAG;
            clear = 1'b1;
        end
        S_TYPE_FLAG: begin
            state_next = S_TIMESTAMP;
            clear = 1'b1;
        end
        S_TIMESTAMP: begin
            if (count == 1) begin // send 2Bytes timestamp
                state_next = S_3ZEROS;
                clear = 1'b1;
            end else begin
                state_next = S_TIMESTAMP;
            end
        end
        S_3ZEROS: begin
            if (count == 2) begin
                state_next = S_PACKET_NUM;
                clear = 1'b1;
            end else begin
                state_next = S_3ZEROS;
            end
        end
        S_PACKET_NUM: begin
            if (count == 1) begin
                state_next = S_DATA;
                clear = 1'b1;
            end else begin
                state_next = S_PACKET_NUM;
            end
        end
        S_DATA: begin
            if (count == DATA_LENGTH - 1) begin
                state_next = S_TYPE_FLAG;
                clear = 1'b1;
            end else begin
                state_next = S_DATA;
            end
        end
    endcase
end

always @(posedge clk) begin
    if (rst) begin
        state_reg <= S_IDLE;
    end else begin
        state_reg <= state_next;
    end
end

always @(posedge clk) begin
    if (clear) begin
        count <= 'd0;
    end else if (fire) begin
        count <= count + 'd1;
    end
end

endmodule

`resetall
