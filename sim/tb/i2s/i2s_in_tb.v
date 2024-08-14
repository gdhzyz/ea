

`timescale 1ns/1ps
  
module i2s_freq_divider_tb ();

wire clk;     
wire reset;   

reg  [15:0]      bclki;
reg  [15:0]      lrcki;
wire [15:0]      bclko;
wire [15:0]      lrcko;
wire [15:0]      bclkt;
wire [15:0]      lrckt;
reg  [15:0]      datai;

wire [15:0]      m_axis_tvalid;
wire [511:0]     m_axis_tdata;
wire [15:0]      m_axis_tlast;

reg  [3*16-1:0]  i_tdm_num;
reg  [15:0]      i_is_master;
reg  [15:0]      i_enable;
reg  [4*16-1:0]  i_dst_fpga_index;
reg  [15:0]      i_word_width;
reg  [2*16-1:0]  i_valid_word_width;
reg  [15:0]      i_lrck_is_pulse;
reg  [15:0]      i_lrck_polarity;
reg  [15:0]      i_lrck_alignment;
reg  [3*16-1:0]  i_bclk_factor;

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

    .i_tdm_num
    .i_is_master
    .i_enable
    .i_dst_fpga_index
    .i_word_width
    .i_valid_word_width
    .i_lrck_is_pulse
    .i_lrck_polarity
    .i_lrck_alignment
    .i_bclk_factor

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