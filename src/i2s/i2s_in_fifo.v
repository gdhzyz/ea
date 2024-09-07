// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * I2S from ADC with output fifo.
 */
module i2s_in_fifo #(
    parameter CN = 16  // channel number
)
(
    /*
     * Clock: 125MHz
     * Synchronous reset with sys_clk
     */
    input  wire             sys_clk,
    input  wire             rst,

    /*
     * I2S master clock from outside FPGA, 24.576MHz
     */
    input  wire             mclki,

    /*
     * I2S IOs
     */
    input  wire [CN-1:0]    bclki,
    input  wire [CN-1:0]    lrcki,
    output wire [CN-1:0]    bclko,
    output wire [CN-1:0]    lrcko,
    output wire [CN-1:0]    bclkt,
    output wire [CN-1:0]    lrckt,
    input  wire [CN-1:0]    datai,
    output wire [CN-1:0]    datao,

    /*
     * I2S muxed output, synchronized with sys_clk.
     */
    output wire             m_axis_tvalid,
    output wire [7:0]       m_axis_tdata,
    output wire             m_axis_tlast,
    output wire             m_axis_tready,

    /*
     * configuration, synchronized with sys_clk.
     */
    input  wire [3*CN-1:0]  i_tdm_num,
    input  wire [CN-1:0]    i_is_master,
    input  wire [CN-1:0]    i_enable,
    input  wire [4*CN-1:0]  i_dst_fpga_index,
    input  wire [CN-1:0]    i_word_width,
    input  wire [2*CN-1:0]  i_valid_word_width,
    input  wire [CN-1:0]    i_lrck_is_pulse,
    input  wire [CN-1:0]    i_lrck_polarity,  // edge of starting flag, 1'b0: posedge, 1'b1: negedge.
    input  wire [CN-1:0]    i_lrck_alignment, // MSB alignment with lrck, 1'b0: aligned, 1'b1: one clock delay
    output wire [32*CN-1:0] o_frame_num,
    input  wire [3*CN-1:0]  i_bclk_factor
);

// ==================== i2s in =======================
wire [CN-1:0]       i2s_in_m_axis_tvalid;
wire [8*CN-1:0]     i2s_in_m_axis_tdata;
wire [CN-1:0]       i2s_in_m_axis_tlast;

wire [CN-1:0]       i2s_in_srst;

i2s_in # (
    .CN(CN)
) i2s_in (
    .arst(rst),
    .mclki(mclki),
    .srst(i2s_in_srst),
    .bclki(bclki),
    .lrcki(lrcki),
    .bclko(bclko),
    .lrcko(lrcko),
    .bclkt(bclkt),
    .lrckt(lrckt),
    .datai(datai),
    .datao(datao),
    .m_axis_tvalid(i2s_in_m_axis_tvalid),
    .m_axis_tdata(i2s_in_m_axis_tdata),
    .m_axis_tlast(i2s_in_m_axis_tlast),
    .i_tdm_num(i_tdm_num),
    .i_is_master(i_is_master),
    .i_enable(i_enable),
    .i_dst_fpga_index(i_dst_fpga_index),
    .i_word_width(i_word_width),
    .i_valid_word_width(i_valid_word_width),
    .i_lrck_is_pulse(i_lrck_is_pulse),
    .i_lrck_polarity(i_lrck_polarity),
    .i_lrck_alignment(i_lrck_alignment),
    .o_frame_num(o_frame_num),
    .i_bclk_factor(i_bclk_factor)
);

//reg datao_reg=1'b0;
//always @(posedge sys_clk) begin
//    datao_reg <= datai;
//end
//assign datao = datao_reg;



// ==================== fifo =======================
wire [CN-1:0]       fifo_out_m_axis_tvalid;
wire [8*CN-1:0]     fifo_out_m_axis_tdata;
wire [CN-1:0]       fifo_out_m_axis_tlast;
wire [CN-1:0]       fifo_out_m_axis_tready;

genvar i;
generate
for (i = 0; i < CN; i = i + 1) begin
    axis_async_fifo_adapter #(
        .DEPTH(128), // 2 frames
        .S_DATA_WIDTH(8),
        .S_KEEP_ENABLE(0),
        .M_DATA_WIDTH(8),
        .M_KEEP_ENABLE(0),
        .ID_ENABLE(0),
        .DEST_ENABLE(0),
        .USER_ENABLE(0)
    ) (
        .s_clk(bclki[i]),
        .s_rst(i2s_in_srst[i]),
        .s_axis_tdata(i2s_in_m_axis_tdata[8*i +: 8]),
        .s_axis_tkeep(1'b1),
        .s_axis_tvalid(i2s_in_m_axis_tvalid[i]),
        .s_axis_tready(),
        .s_axis_tlast(i2s_in_m_axis_tlast[i]),
        .s_axis_tid(1'b0),
        .s_axis_tdest(1'b0),
        .s_axis_tuser(1'b0),

        .m_clk(sys_clk),
        .m_rst(rst),
        .m_axis_tdata(fifo_out_m_axis_tdata[8*i +: 8]),
        .m_axis_tkeep(),
        .m_axis_tvalid(fifo_out_m_axis_tvalid[i]),
        .m_axis_tready(fifo_out_m_axis_tready[i]),
        .m_axis_tlast(fifo_out_m_axis_tlast[i]),
        .m_axis_tid(),
        .m_axis_tdest(),
        .m_axis_tuser(),

        .s_pause_req(),
        .s_pause_ack(),
        .m_pause_req(),
        .m_pause_ack(),

        .s_status_depth(),
        .s_status_depth_commit(),
        .s_status_overflow(),
        .s_status_bad_frame(),
        .s_status_good_frame(),
        .m_status_depth(),
        .m_status_depth_commit(),
        .m_status_overflow(),
        .m_status_bad_frame(),
        .m_status_good_frame()
    );
end
endgenerate

// ==================== output arbiter =======================
axis_arb_mux #(
    .S_COUNT(CN),
    .DATA_WIDTH(8),
    .KEEP_ENABLE(0),
    .ID_ENABLE(0),
    .DEST_ENABLE(0),
    .USER_ENABLE(0),
    .LAST_ENABLE(1)
) axis_arb_mux (
    .clk(sys_clk),
    .rst(rst),
    
    .s_axis_tdata(fifo_out_m_axis_tdata),
    .s_axis_tkeep(),
    .s_axis_tvalid(fifo_out_m_axis_tvalid),
    .s_axis_tready(fifo_out_m_axis_tready),
    .s_axis_tlast(fifo_out_m_axis_tlast),
    .s_axis_tid(),
    .s_axis_tdest(),
    .s_axis_tuser(),

    .m_axis_tdata(m_axis_tdata),
    .m_axis_tkeep(),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tlast(m_axis_tlast),
    .m_axis_tid(),
    .m_axis_tdest(),
    .m_axis_tuser()
);


endmodule

`resetall
