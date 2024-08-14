

`timescale 1ns/1ps
  
module i2s_freq_divider_tb ();

wire clk;     
wire reset;   
reg enable=0;
wire bclk;
wire lrck;
reg [4:0] bclk_factor=0;
reg [5:0] word_width=0;

i2s_freq_divider dut (
    /*
     * Clock: 24.576MHz
     * Synchronous reset
     */
    .mclki(clk),
    .rst(reset),
    .enable(enable),
    .bclk(bclk),
    .lrck(lrck),
    .bclk_factor(bclk_factor),
    .word_width(word_width)
);
clock_gen 
#(.PERIOD(40.690/4)) 
clock_gen 
(
    .clk(clk)
);
reset_gen reset_gen (
    .clk(clk),
    .reset(reset)
);
 
`include "i2s_freq_divider_case1.vh"
   
endmodule