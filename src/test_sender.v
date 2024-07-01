
module test_sender #
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
    parameter KEEP_WIDTH = (DATA_WIDTH/8),
    parameter TIME_1S = 125000000
) 
(
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    input  wire       clk,
    input  wire       rst,

    /*
     * Ethernet frame output
     */
    output wire                  m_eth_hdr_valid,
    input  wire                  m_eth_hdr_ready,
    output wire [47:0]           m_eth_dest_mac,
    output wire [47:0]           m_eth_src_mac,
    output wire [15:0]           m_eth_type,
    output wire [DATA_WIDTH-1:0] m_eth_payload_axis_tdata,
    output wire                  m_eth_payload_axis_tvalid,
    input  wire                  m_eth_payload_axis_tready,
    output wire                  m_eth_payload_axis_tlast,
    output wire                  m_eth_payload_axis_tuser
);

    localparam LENGTH_BITS = $clog2(LENGTH);

    (* mark_debug = "true" *) reg [31:0] frame_count = 'd0;
    (* mark_debug = "true" *) reg [31:0] hdr_count = 'd0;
    (* mark_debug = "true" *) reg [31:0] beat_count = 'd0;
    reg let_go = 1'b0;
    reg [31:0] timer = 'd0;

    wire hdr_fire = m_eth_hdr_valid && m_eth_hdr_ready;
    wire payload_fire = m_eth_payload_axis_tvalid && m_eth_payload_axis_tready;

    assign m_eth_dest_mac = DST_MAC;
    assign m_eth_src_mac = LOCAL_MAC;
    assign m_eth_type = 16'h88B5;

    assign m_eth_payload_axis_tdata = beat_count[DATA_WIDTH - 1 : 0];
    assign m_eth_payload_axis_tlast = beat_count[LENGTH_BITS - 1 : 0] == LENGTH - 1;
    assign m_eth_payload_axis_tuser = 1'b0;

    always @(posedge clk) begin
        if (rst) begin
            hdr_count <= 'd0;
        end else if (hdr_fire) begin
            hdr_count <= hdr_count + 'd1;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
           beat_count <= 'd0;
           frame_count <= 'd0;
        end else if (payload_fire) begin
            beat_count <= beat_count + 'd1;
            if (m_eth_payload_axis_tlast) begin
                frame_count <= frame_count + 'd1;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            let_go <= 1'b0;
            timer <= 'd0;
        end else if (timer == TIME_1S * 10) begin
            let_go <= 1'b1;
        end else if (timer < TIME_1S * 10) begin
            let_go <= 1'b0;
            timer <= timer + 'd1;
        end
    end
    
    assign m_eth_hdr_valid = let_go;
    assign m_eth_payload_axis_tvalid = let_go;


endmodule