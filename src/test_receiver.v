
module test_receiver #
(
    parameter LENGTH = 512,
    parameter LOCAL_MAC = 48'h02_00_00_00_00_00,
    parameter DST_MAC = 48'h02_00_00_00_00_00,
    // Width of AXI stream interfaces in bits
    parameter DATA_WIDTH = 8,
    // Propagate tkeep signal
    // If disabled, tkeep assumed to be 1'b1
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    // tkeep signal width (words per cycle)
    parameter KEEP_WIDTH = (DATA_WIDTH/8)
) 
(
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    input  wire       clk,
    input  wire       rst,

    /*
     * Ethernet frame input
     */
    input  wire                  s_eth_hdr_valid,
    output wire                  s_eth_hdr_ready,
    input  wire [47:0]           s_eth_dest_mac,
    input  wire [47:0]           s_eth_src_mac,
    input  wire [15:0]           s_eth_type,
    input  wire [DATA_WIDTH-1:0] s_eth_payload_axis_tdata,
    input  wire                  s_eth_payload_axis_tvalid,
    output wire                  s_eth_payload_axis_tready,
    input  wire                  s_eth_payload_axis_tlast,
    input  wire                  s_eth_payload_axis_tuser
);

    localparam LENGTH_BITS = $clog2(LENGTH);

    (* mark_debug = "true" *) reg [31:0] frame_count = 'd0;
    (* mark_debug = "true" *) reg [31:0] hdr_count = 'd0;
    (* mark_debug = "true" *) reg [31:0] beat_count = 'd0;
    (* mark_debug = "true" *) reg [31:0] error_count = 'd0;

    wire hdr_fire = s_eth_hdr_valid && s_eth_hdr_ready;
    wire payload_fire = s_eth_payload_axis_tvalid && s_eth_payload_axis_tready;

    assign s_eth_hdr_ready = 1'b1;

    assign s_eth_payload_axis_tready = 1'b1;

    always @(posedge clk) begin
        if (hdr_fire) begin
            hdr_count <= hdr_count + 'd1;
        end
    end

    always @(posedge clk) begin
        if (payload_fire) begin
            beat_count <= beat_count + 'd1;
            if (s_eth_payload_axis_tlast) begin
                frame_count <= frame_count + 'd1;
            end
        end
    end

    wire hdr_err = hdr_fire && (s_eth_dest_mac != LOCAL_MAC || s_eth_src_mac != DST_MAC);
    wire payload_err = payload_fire && 
                       (
                        (beat_count[DATA_WIDTH - 1 : 0] != s_eth_payload_axis_tdata) || 
                        (s_eth_payload_axis_tlast ^ (beat_count[LENGTH_BITS - 1 : 0] == LENGTH - 1))
                       );
    (* mark_debug = "true" *)reg hdr_err_reg = 1'b0;
    (* mark_debug = "true" *)reg payload_err_reg = 1'b0;

    always @(posedge clk) begin
        hdr_err_reg <= hdr_err;
        payload_err_reg <= payload_err;
        error_count <= error_count + ({1'b0, hdr_err_reg} + {1'b0, payload_err_reg});
    end


endmodule