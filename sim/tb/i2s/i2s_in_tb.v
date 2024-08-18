


`timescale 1ns/1ps
  
module i2s_in_tb ();

wire clk;     
wire reset;   

wire [15:0]      bclki;
wire [15:0]      lrcki;
wire [15:0]      bclko;
wire [15:0]      lrcko;
wire [15:0]      bclkt;
wire [15:0]      lrckt;
reg  [15:0]      datai;

wire [15:0]      m_axis_tvalid;
wire [511:0]     m_axis_tdata;
wire [15:0]      m_axis_tlast;

reg  [3*16-1:0]  tdm_num;
reg  [15:0]      is_master;
reg  [15:0]      enable;
reg  [4*16-1:0]  dst_fpga_index;
reg  [15:0]      word_width;
reg  [2*16-1:0]  valid_word_width;
reg  [15:0]      lrck_is_pulse; // TODO for 1'b1.
reg  [15:0]      lrck_polarity;
reg  [15:0]      lrck_alignment;
reg  [3*16-1:0]  bclk_factor;

i2s_in dut (
    /*
     * Clock: 24.576MHz
     * Asynchronous reset
     */
    .mclki(clk),
    .arst(reset),

    .bclki(bclki),
    .lrcki(lrcki),
    .bclko(bclko),
    .lrcko(lrcko),
    .bclkt(bclkt),
    .lrckt(lrckt),
    .datai(datai),

    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tlast(m_axis_tlast),

    .i_tdm_num(tdm_num),
    .i_is_master(is_master),
    .i_enable(enable),
    .i_dst_fpga_index(dst_fpga_index),
    .i_word_width(word_width),
    .i_valid_word_width(valid_word_width),
    .i_lrck_is_pulse(lrck_is_pulse),
    .i_lrck_polarity(lrck_polarity),
    .i_lrck_alignment(lrck_alignment),
    .i_bclk_factor(bclk_factor),
    .srst(),
    .o_frame_num()
);
clock_gen 
#(.PERIOD(40.690)) 
clock_gen 
(
    .clk(clk)
);
reset_gen reset_gen (
    .clk(clk),
    .reset(reset)
);
 
`include "i2s_in_case1.vh"
   
endmodule