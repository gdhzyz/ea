
`timescale 1ns/100ps
  
module test_gen_pattern_tb ();

    parameter DATA_LENGTH = 256;
    parameter DATA_WIDTH = 8;
 
   
    wire clk;     
    wire reset;

    reg   [15:0]             packet_index = 5;
    reg   [47:0]             mac0 = 48'hAB_CD_EF_01_23_45;
    reg   [47:0]             mac1 = 48'hAB_CD_EF_67_89_01;
    wire                     is_data;
    wire                     is_timestamp0;
    wire                     is_timestamp1;

    wire                     m_eth_hdr_valid;
    wire                     m_eth_hdr_ready;
    wire [47:0]              m_eth_dest_mac;
    wire [47:0]              m_eth_src_mac;
    wire [15:0]              m_eth_type;
    wire [DATA_WIDTH-1:0]    m_eth_payload_axis_tdata;
    wire                     m_eth_payload_axis_tvalid;
    wire                     m_eth_payload_axis_tready;
    wire                     m_eth_payload_axis_tlast;
    wire                     m_eth_payload_axis_tuser;
    
    wire                     s_eth_hdr_valid;
    wire                     s_eth_hdr_ready;
    wire [47:0]              s_eth_dest_mac;
    wire [47:0]              s_eth_src_mac;
    wire [15:0]              s_eth_type;
    wire [DATA_WIDTH-1:0]    s_eth_payload_axis_tdata;
    wire                     s_eth_payload_axis_tvalid;
    wire                     s_eth_payload_axis_tready;
    wire                     s_eth_payload_axis_tlast;
    wire                     s_eth_payload_axis_tuser;

    reg [15:0]               timestamp;
    wire                     error;

    reg [1:0]                ctrl_count=0;
    wire                     enable_payload = ctrl_count == 2;
       
   
    test_gen_pattern #(
        .DATA_LENGTH(DATA_LENGTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) test_gen_pattern (
        .clk(clk),
        .rst(reset),

        .packet_index(packet_index),
        .src_mac(mac0),
        .dst_mac(mac1),
        .timestamp(timestamp),
        .is_data(is_data),
        .is_timestamp0(is_timestamp0),
        .is_timestamp1(is_timestamp1),

        .m_eth_hdr_valid(m_eth_hdr_valid),
        .m_eth_hdr_ready(m_eth_hdr_ready),
        .m_eth_dest_mac(m_eth_dest_mac),
        .m_eth_src_mac(m_eth_src_mac),
        .m_eth_type(m_eth_type),
        .m_eth_payload_axis_tdata(m_eth_payload_axis_tdata),
        .m_eth_payload_axis_tvalid(m_eth_payload_axis_tvalid),
        .m_eth_payload_axis_tready(m_eth_payload_axis_tready),
        .m_eth_payload_axis_tlast(m_eth_payload_axis_tlast),
        .m_eth_payload_axis_tuser(m_eth_payload_axis_tuser) 
    );

    test_pattern_recv #(
        .DATA_LENGTH(DATA_LENGTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) test_pattern_recv (
        .clk(clk),
        .rst(reset),

        .packet_index(packet_index),
        .src_mac(mac1),
        .dst_mac(mac0),
        .timestamp(timestamp),
        .error(error),
        .max_time_gap(),

        .s_eth_hdr_valid(s_eth_hdr_valid),
        .s_eth_hdr_ready(s_eth_hdr_ready),
        .s_eth_dest_mac(s_eth_dest_mac),
        .s_eth_src_mac(s_eth_src_mac),
        .s_eth_type(s_eth_type),
        .s_eth_payload_axis_tdata(s_eth_payload_axis_tdata),
        .s_eth_payload_axis_tvalid(s_eth_payload_axis_tvalid),
        .s_eth_payload_axis_tready(s_eth_payload_axis_tready),
        .s_eth_payload_axis_tlast(s_eth_payload_axis_tlast),
        .s_eth_payload_axis_tuser(s_eth_payload_axis_tuser) 
    );


    assign s_eth_hdr_valid = m_eth_hdr_valid;
    assign m_eth_hdr_ready = s_eth_hdr_ready;
    assign s_eth_dest_mac = m_eth_dest_mac;
    assign s_eth_src_mac = m_eth_src_mac;
    assign s_eth_type = m_eth_type;
    assign s_eth_payload_axis_tvalid = m_eth_payload_axis_tvalid && enable_payload;
    assign m_eth_payload_axis_tready = s_eth_payload_axis_tready && enable_payload;
    assign s_eth_payload_axis_tdata = m_eth_payload_axis_tdata;
    assign s_eth_payload_axis_tlast = m_eth_payload_axis_tlast;
    assign s_eth_payload_axis_tuser = m_eth_payload_axis_tuser;
 
   


    clock_gen 
    #(.PERIOD(10)) 
    clock_gen 
    (
        .clk(clk)
    );

    reset_gen reset_gen (
        .clk(clk),
        .reset(reset)
    );
 
    integer i;
    initial begin
        @(negedge reset);
        @(posedge clk);

        for (i = 0; i < 1000; i = i + 1) begin
            @(posedge clk);
        end

        $finish;

    end

    always @(posedge clk) begin
        if (reset) begin
            timestamp <= 0;
        end else begin
            timestamp <= timestamp + 1;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            ctrl_count = 0;
        end else begin
            ctrl_count = ctrl_count == 2 ? 0 : ctrl_count + 1;
        end
    end
   
endmodule