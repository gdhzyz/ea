//******************************************************************************
//
//  Xilinx, Inc. 2002                 www.xilinx.com
//
//
//*******************************************************************************
//
//  File name :       top_16ch_training_monitor.v
//
//  Description :     This module is the top level module for the DPA design
// 
//                    
//  Date - revision : 11/30/2004
//
//  Author :          Tze Yi Yeoh
//
//  Contact : e-mail  hotline@xilinx.com
//            phone   + 1 800 255 7778 
//
//  Disclaimer: LIMITED WARRANTY AND DISCLAMER. These designs are 
//              provided to you "as is". Xilinx and its licensors make and you 
//              receive no warranties or conditions, express, implied, 
//              statutory or otherwise, and Xilinx specifically disclaims any 
//              implied warranties of merchantability, non-infringement, or 
//              fitness for a particular purpose. Xilinx does not warrant that 
//              the functions contained in these designs will meet your 
//              requirements, or that the operation of these designs will be 
//              uninterrupted or error free, or that defects in the Designs 
//              will be corrected. Furthermore, Xilinx does not warrant or 
//              make any representations regarding use or the results of the 
//              use of the designs in terms of correctness, accuracy, 
//              reliability, or otherwise. 
//
//              LIMITATION OF LIABILITY. In no event will Xilinx or its 
//              licensors be liable for any loss of data, lost profits, cost 
//              or procurement of substitute goods or services, or for any 
//              special, incidental, consequential, or indirect damages 
//              arising from the use or operation of the designs or 
//              accompanying documentation, however caused and on any theory 
//              of liability. This limitation will apply even if Xilinx 
//              has been advised of the possibility of such damage. This 
//              limitation shall apply not-withstanding the failure of the 
//              essential purpose of any limited remedies herein. 
//
//  Copyright � 2002 Xilinx, Inc.
//  All rights reserved 
// 
//*****************************************************************************

`timescale 1ps/1ps

module top_16ch_training_monitor (
	 data_out,
	 train_done,
	 iobclk,
	 clk_200m,
	 clkdiv,
	 data_in,
	 dlyrst,
	 rst,
 	 train_en,
	 sce,
	 inc_ext,
	 ice_ext
	);

// Parameter that determines the number of channels instantiated.
parameter num_chan = 4;

output [num_chan*4-1:0] data_out;
output train_done;
input  iobclk;
input  clk_200m;
input  clkdiv;
input  [num_chan-1:0] data_in;
input  dlyrst;
input  rst;
input  train_en;
input  sce;
input  inc_ext;
input  ice_ext;

wire [num_chan*4-1:0] data_out;
wire [num_chan-1:0] window_in;
reg [num_chan-1:0] chan_sel;
reg [num_chan-1:0] chan_sel1;
wire [num_chan-1:0] dataout_sel;
reg [num_chan-1:0] dataout_sel_int;
reg dataout_sel_invert;
wire deskew_done;
wire bitslip_done;
wire monitor_done;
wire bitslip_error;
reg  train_done;
wire [num_chan-1:0] dlyce;
wire [num_chan-1:0] dlyinc;
wire [num_chan-1:0] dlyce_to_data_iserdes;
wire [num_chan-1:0] dlyinc_to_data_iserdes;
wire [num_chan-1:0] dlyce_iserdes_window;
wire [num_chan-1:0] dlyinc_iserdes_window;
wire [num_chan-1:0] dlyce_to_monitor_iserdes;
wire [num_chan-1:0] dlyinc_to_monitor_iserdes;
wire dlyce_training;
wire dlyinc_training;
reg dlyce_training_R1;
reg dlyinc_training_R1;
reg dlyce_monitor_R1;
reg dlyinc_monitor_R1;
reg dlyce_window_R1;
reg dlyinc_window_R1;
wire dlyce_window;
wire dlyinc_window;
reg dlyce_iserdes_window1;
reg dlyinc_iserdes_window1;
reg dlyce1;
reg dlyinc1;
wire [num_chan-1:0] bitslip;
wire bitslip_training;
wire iobclk;
wire iobclk_ibuf;
wire clkdiv;
wire refclk;
wire refclk_ibufg;
wire [num_chan-1:0] q1;
wire [num_chan-1:0] q2;
wire [num_chan-1:0] q3;
wire [num_chan-1:0] q4;
wire [num_chan-1:0] w1;
wire [num_chan-1:0] w2;
wire [num_chan-1:0] w3;
wire [num_chan-1:0] w4;
wire [3:0] datain;
wire [3:0] datain_monitor;
wire [3:0] dataout[num_chan-1:0];
reg [3:0] dataout_R1[num_chan-1:0];
wire [3:0] dataout_int[num_chan-1:0];
wire [3:0] windowout[num_chan-1:0];

reg [3:0] windowout_R1[num_chan-1:0];

// Dataout Channel Select Mux
wire [3:0] muxout_d0d1; // TODO
wire [3:0] muxout_d2d3;
wire [3:0] muxout_d4d5;
wire [3:0] muxout_d6d7;
wire [3:0] muxout_d8d9;
wire [3:0] muxout_d10d11;
wire [3:0] muxout_d12d13;
wire [3:0] muxout_d14d15;

wire [3:0] muxout_d0_to_d3;
wire [3:0] muxout_d4_to_d7;
wire [3:0] muxout_d8_to_d11;
wire [3:0] muxout_d12_to_d15;

reg [3:0] muxout_d0_to_d3_R1;
reg [3:0] muxout_d4_to_d7_R1;
reg [3:0] muxout_d8_to_d11_R1;
reg [3:0] muxout_d12_to_d15_R1;

wire [3:0] muxout_d0_to_d7;
wire [3:0] muxout_d8_to_d15;

// Window Monitor Channel Select Mux
wire [3:0] muxout_w0w1;
wire [3:0] muxout_w2w3;
wire [3:0] muxout_w4w5;
wire [3:0] muxout_w6w7;
wire [3:0] muxout_w8w9;
wire [3:0] muxout_w10w11;
wire [3:0] muxout_w12w13;
wire [3:0] muxout_w14w15;

wire [3:0] muxout_w0_to_w3;
wire [3:0] muxout_w4_to_w7;
wire [3:0] muxout_w8_to_w11;
wire [3:0] muxout_w12_to_w15;

reg [3:0] muxout_w0_to_w3_R1;
reg [3:0] muxout_w4_to_w7_R1;
reg [3:0] muxout_w8_to_w11_R1;
reg [3:0] muxout_w12_to_w15_R1;

wire [3:0] muxout_w0_to_w7;
wire [3:0] muxout_w8_to_w15;

wire [2:0] edgei_training;
reg [7:0] counter;
reg cnt_rst;
reg [3:0] op_sel;


assign window_in = data_in;

wire [num_chan-1:0] delayed_data_in;
wire [4:0] delayed_count_value[num_chan-1:0];

// Instantiate the IDELAY
IDELAYE2 data_idelay[num_chan-1:0] (
	.C(clkdiv),
	.REGRST(rst),
	.LD(1'b0), // update when in product.
	.CE(dlyce_to_data_iserdes[num_chan-1:0]),
	.INC(dlyinc_to_data_iserdes[num_chan-1:0]),
	.CINVCTRL(1'b0),
	.CNTVALUEIN(4'd0),
	.IDATAIN(data_in[num_chan-1:0]),
	.LDPIPEEN(1'b0),
	.DATAIN({num_chan{1'b0}}),
	.DATAOUT(delayed_data_in[num_chan-1:0]),
	.CNTVALUEOUT(delayed_count_value[num_chan-1:0]);
);
// synthesis translate_off
generate
genvar i;
for (i=0; i<=num_chan-1; i=i+1)
begin :  data_idelay_defparam
defparam data_idelay[i].IDELAY_TYPE = "VARIABLE";
defparam data_idelay[i].DELAY_SRC = "IDATAIN";
defparam data_idelay[i].IDELAY_VALUE = 0;
defparam data_idelay[i].HIGH_PERFORMANCE_MODE = "TRUE";
defparam data_idelay[i].SIGNAL_PATTERN = "DATA";
defparam data_idelay[i].REFCLK_FREQENCY = 200; // IDELAYCTRL clock input frequency in MHz
defparam data_idelay[i].CINVCTRL_SEL = "FALSE";
defparam data_idelay[i].PIPE_SEL = "FALSE";
end
endgenerate
// synthesis translate_on

ISERDESE2 data_chan_master_[num_chan-1:0] (
		                  .O(), 
				            .Q1(q1[num_chan-1:0]), 
				            .Q2(q2[num_chan-1:0]), 
				            .Q3(q3[num_chan-1:0]), 
		                  .Q4(q4[num_chan-1:0]), 
				            .Q5(),
				            .Q6(),
							.Q7(),
							.Q8(),
		                  .SHIFTOUT1(), 
				            .SHIFTOUT2(),
				            .BITSLIP(bitslip[num_chan-1:0]),
				            .CE1(sce), 
				            .CE2(1'b1),
		                  .CLK(iobclk), 
                          .CLKB(),
				            .CLKDIV(clkdiv), 	
							.CLKDIVP(),
							.DYNCLKSEL(),			   
                        .D(delayed_data_in[num_chan-1:0]), 
				            .DLYCE(dlyce_to_data_iserdes[num_chan-1:0]),
		                  .DLYINC(dlyinc_to_data_iserdes[num_chan-1:0]),
				            .DLYRST(dlyrst),
				            .OCLK(1'b0), 
							.OCLKB(),
				            .REV(1'b0),
		                  .SHIFTIN1(1'b0), 
				            .SHIFTIN2(1'b0),
							.RST(),
							.DDLY(),
							.OFB(),
		                  .SR(rst)		  
		                     );
// synthesis translate_off
generate
genvar i;
for (i=0; i<=num_chan-1; i=i+1)
begin :  data_chan_master_defparam
defparam data_chan_master_[i].BITSLIP_ENABLE = "TRUE";
defparam data_chan_master_[i].DATA_RATE = "DDR";  // OK
defparam data_chan_master_[i].DATA_WIDTH = 4;     // OK
defparam data_chan_master_[i].INIT_Q1 = 1'b0;  // OK
defparam data_chan_master_[i].INIT_Q2 = 1'b0;  // OK
defparam data_chan_master_[i].INIT_Q3 = 1'b0;  // OK
defparam data_chan_master_[i].INIT_Q4 = 1'b0;  // OK
defparam data_chan_master_[i].INTERFACE_TYPE = "NETWORKING"; // OK
defparam data_chan_master_[i].IOBDELAY = "IFD";
defparam data_chan_master_[i].IOBDELAY_TYPE = "VARIABLE";
defparam data_chan_master_[i].IOBDELAY_VALUE = 0;
defparam data_chan_master_[i].NUM_CE = 1;  // OK
defparam data_chan_master_[i].SERDES_MODE = "MASTER"; // OK
defparam data_chan_master_[i].SRVAL_Q1 = 1'b0; // OK
defparam data_chan_master_[i].SRVAL_Q2 = 1'b0;  // OK
defparam data_chan_master_[i].SRVAL_Q3 = 1'b0; // OK
defparam data_chan_master_[i].SRVAL_Q4 = 1'b0;  // OK
defparam data_chan_master_[i].DYN_CLKDIV_INV_EN = "FALSE"; // OK
defparam data_chan_master_[i].DYN_CLK_INV_EN = "FALSE";   // OK
defparam data_chan_master_[i].OFB_USED = "FALSE";    // OK
end
endgenerate
// synthesis translate_on

// Instantiate the window monitor data channel ISERDES 
ISERDES2 window_monitor_[num_chan-1:0] (
		                  .O(), 
				            .Q1(w1[num_chan-1:0]), 
				            .Q2(w2[num_chan-1:0]), 
				            .Q3(w3[num_chan-1:0]), 
		                  .Q4(w4[num_chan-1:0]), 
				            .Q5(),
				            .Q6(),
		                  .SHIFTOUT1(), 
				            .SHIFTOUT2(),
				            .BITSLIP(bitslip[num_chan-1:0]),
				            .CE1(1'b1), 
				            .CE2(1'b1),
		                  .CLK(iobclk), 
				            .CLKDIV(clkdiv), 				   
                        .D(window_in[num_chan-1:0]), 
				            .DLYCE(dlyce_to_monitor_iserdes[num_chan-1:0]),
		                  .DLYINC(dlyinc_to_monitor_iserdes[num_chan-1:0]),
				            .DLYRST(dlyrst),
				            .OCLK(1'b0), 
				            .REV(1'b0),
		                  .SHIFTIN1(1'b0), 
				            .SHIFTIN2(1'b0),
		                  .SR(rst)			  
		                     );
// synthesis translate_off
generate
genvar j;
for (j=0; j<=num_chan-1; j=j+1)
begin :  window_monitor_defparam
defparam window_monitor_[j].BITSLIP_ENABLE = "TRUE";
defparam window_monitor_[j].DATA_RATE = "DDR";
defparam window_monitor_[j].DATA_WIDTH = 4;
defparam window_monitor_[j].INIT_Q1 = 1'b0;
defparam window_monitor_[j].INIT_Q2 = 1'b0;
defparam window_monitor_[j].INIT_Q3 = 1'b0;
defparam window_monitor_[j].INIT_Q4 = 1'b0;
defparam window_monitor_[j].INTERFACE_TYPE = "NETWORKING";
defparam window_monitor_[j].IOBDELAY = "IFD";
defparam window_monitor_[j].IOBDELAY_TYPE = "VARIABLE";
defparam window_monitor_[j].IOBDELAY_VALUE = 3;
defparam window_monitor_[j].NUM_CE = 1;
defparam window_monitor_[j].SERDES_MODE = "MASTER";
defparam window_monitor_[j].SRVAL_Q1 = 1'b0;
defparam window_monitor_[j].SRVAL_Q2 = 1'b0;
defparam window_monitor_[j].SRVAL_Q3 = 1'b0;
defparam window_monitor_[j].SRVAL_Q4 = 1'b0; 
end
endgenerate						 
// synthesis translate_on

// Synthesis Attributes for Data Chan

// synthesis attribute BITSLIP_ENABLE of data_chan_master_[0] is "TRUE"
// synthesis attribute DATA_RATE of data_chan_master_[0] is "DDR"
// synthesis attribute DATA_WIDTH of data_chan_master_[0] is 4
// synthesis attribute INTERFACE_TYPE of data_chan_master_[0] is "NETWORKING"
// synthesis attribute IOBDELAY of data_chan_master_[0] is "IFD"
// synthesis attribute IOBDELAY_TYPE of data_chan_master_[0] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of data_chan_master_[0] is 0
// synthesis attribute NUM_CE of data_chan_master_[0] is 1
// synthesis attribute SERDES_MODE of data_chan_master_[0] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of data_chan_master_[1] is "TRUE"
// synthesis attribute DATA_RATE of data_chan_master_[1] is "DDR"
// synthesis attribute DATA_WIDTH of data_chan_master_[1] is 4
// synthesis attribute INTERFACE_TYPE of data_chan_master_[1] is "NETWORKING"
// synthesis attribute IOBDELAY of data_chan_master_[1] is "IFD"
// synthesis attribute IOBDELAY_TYPE of data_chan_master_[1] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of data_chan_master_[1] is 0
// synthesis attribute NUM_CE of data_chan_master_[1] is 1
// synthesis attribute SERDES_MODE of data_chan_master_[1] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of data_chan_master_[2] is "TRUE"
// synthesis attribute DATA_RATE of data_chan_master_[2] is "DDR"
// synthesis attribute DATA_WIDTH of data_chan_master_[2] is 4
// synthesis attribute INTERFACE_TYPE of data_chan_master_[2] is "NETWORKING"
// synthesis attribute IOBDELAY of data_chan_master_[2] is "IFD"
// synthesis attribute IOBDELAY_TYPE of data_chan_master_[2] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of data_chan_master_[2] is 0
// synthesis attribute NUM_CE of data_chan_master_[2] is 1
// synthesis attribute SERDES_MODE of data_chan_master_[2] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of data_chan_master_[3] is "TRUE"
// synthesis attribute DATA_RATE of data_chan_master_[3] is "DDR"
// synthesis attribute DATA_WIDTH of data_chan_master_[3] is 4
// synthesis attribute INTERFACE_TYPE of data_chan_master_[3] is "NETWORKING"
// synthesis attribute IOBDELAY of data_chan_master_[3] is "IFD"
// synthesis attribute IOBDELAY_TYPE of data_chan_master_[3] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of data_chan_master_[3] is 0
// synthesis attribute NUM_CE of data_chan_master_[3] is 1
// synthesis attribute SERDES_MODE of data_chan_master_[3] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of data_chan_master_[4] is "TRUE"
// synthesis attribute DATA_RATE of data_chan_master_[4] is "DDR"
// synthesis attribute DATA_WIDTH of data_chan_master_[4] is 4
// synthesis attribute INTERFACE_TYPE of data_chan_master_[4] is "NETWORKING"
// synthesis attribute IOBDELAY of data_chan_master_[4] is "IFD"
// synthesis attribute IOBDELAY_TYPE of data_chan_master_[4] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of data_chan_master_[4] is 0
// synthesis attribute NUM_CE of data_chan_master_[4] is 1
// synthesis attribute SERDES_MODE of data_chan_master_[4] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of data_chan_master_[5] is "TRUE"
// synthesis attribute DATA_RATE of data_chan_master_[5] is "DDR"
// synthesis attribute DATA_WIDTH of data_chan_master_[5] is 4
// synthesis attribute INTERFACE_TYPE of data_chan_master_[5] is "NETWORKING"
// synthesis attribute IOBDELAY of data_chan_master_[5] is "IFD"
// synthesis attribute IOBDELAY_TYPE of data_chan_master_[5] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of data_chan_master_[5] is 0
// synthesis attribute NUM_CE of data_chan_master_[5] is 1
// synthesis attribute SERDES_MODE of data_chan_master_[5] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of data_chan_master_[6] is "TRUE"
// synthesis attribute DATA_RATE of data_chan_master_[6] is "DDR"
// synthesis attribute DATA_WIDTH of data_chan_master_[6] is 4
// synthesis attribute INTERFACE_TYPE of data_chan_master_[6] is "NETWORKING"
// synthesis attribute IOBDELAY of data_chan_master_[6] is "IFD"
// synthesis attribute IOBDELAY_TYPE of data_chan_master_[6] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of data_chan_master_[6] is 0
// synthesis attribute NUM_CE of data_chan_master_[6] is 1
// synthesis attribute SERDES_MODE of data_chan_master_[6] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of data_chan_master_[7] is "TRUE"
// synthesis attribute DATA_RATE of data_chan_master_[7] is "DDR"
// synthesis attribute DATA_WIDTH of data_chan_master_[7] is 4
// synthesis attribute INTERFACE_TYPE of data_chan_master_[7] is "NETWORKING"
// synthesis attribute IOBDELAY of data_chan_master_[7] is "IFD"
// synthesis attribute IOBDELAY_TYPE of data_chan_master_[7] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of data_chan_master_[7] is 0
// synthesis attribute NUM_CE of data_chan_master_[7] is 1
// synthesis attribute SERDES_MODE of data_chan_master_[7] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of data_chan_master_[8] is "TRUE"
// synthesis attribute DATA_RATE of data_chan_master_[8] is "DDR"
// synthesis attribute DATA_WIDTH of data_chan_master_[8] is 4
// synthesis attribute INTERFACE_TYPE of data_chan_master_[8] is "NETWORKING"
// synthesis attribute IOBDELAY of data_chan_master_[8] is "IFD"
// synthesis attribute IOBDELAY_TYPE of data_chan_master_[8] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of data_chan_master_[8] is 0
// synthesis attribute NUM_CE of data_chan_master_[8] is 1
// synthesis attribute SERDES_MODE of data_chan_master_[8] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of data_chan_master_[9] is "TRUE"
// synthesis attribute DATA_RATE of data_chan_master_[9] is "DDR"
// synthesis attribute DATA_WIDTH of data_chan_master_[9] is 4
// synthesis attribute INTERFACE_TYPE of data_chan_master_[9] is "NETWORKING"
// synthesis attribute IOBDELAY of data_chan_master_[9] is "IFD"
// synthesis attribute IOBDELAY_TYPE of data_chan_master_[9] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of data_chan_master_[9] is 0
// synthesis attribute NUM_CE of data_chan_master_[9] is 1
// synthesis attribute SERDES_MODE of data_chan_master_[9] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of data_chan_master_[10] is "TRUE"
// synthesis attribute DATA_RATE of data_chan_master_[10] is "DDR"
// synthesis attribute DATA_WIDTH of data_chan_master_[10] is 4
// synthesis attribute INTERFACE_TYPE of data_chan_master_[10] is "NETWORKING"
// synthesis attribute IOBDELAY of data_chan_master_[10] is "IFD"
// synthesis attribute IOBDELAY_TYPE of data_chan_master_[10] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of data_chan_master_[10] is 0
// synthesis attribute NUM_CE of data_chan_master_[10] is 1
// synthesis attribute SERDES_MODE of data_chan_master_[10] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of data_chan_master_[11] is "TRUE"
// synthesis attribute DATA_RATE of data_chan_master_[11] is "DDR"
// synthesis attribute DATA_WIDTH of data_chan_master_[11] is 4
// synthesis attribute INTERFACE_TYPE of data_chan_master_[11] is "NETWORKING"
// synthesis attribute IOBDELAY of data_chan_master_[11] is "IFD"
// synthesis attribute IOBDELAY_TYPE of data_chan_master_[11] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of data_chan_master_[11] is 0
// synthesis attribute NUM_CE of data_chan_master_[11] is 1
// synthesis attribute SERDES_MODE of data_chan_master_[11] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of data_chan_master_[12] is "TRUE"
// synthesis attribute DATA_RATE of data_chan_master_[12] is "DDR"
// synthesis attribute DATA_WIDTH of data_chan_master_[12] is 4
// synthesis attribute INTERFACE_TYPE of data_chan_master_[12] is "NETWORKING"
// synthesis attribute IOBDELAY of data_chan_master_[12] is "IFD"
// synthesis attribute IOBDELAY_TYPE of data_chan_master_[12] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of data_chan_master_[12] is 0
// synthesis attribute NUM_CE of data_chan_master_[12] is 1
// synthesis attribute SERDES_MODE of data_chan_master_[12] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of data_chan_master_[13] is "TRUE"
// synthesis attribute DATA_RATE of data_chan_master_[13] is "DDR"
// synthesis attribute DATA_WIDTH of data_chan_master_[13] is 4
// synthesis attribute INTERFACE_TYPE of data_chan_master_[13] is "NETWORKING"
// synthesis attribute IOBDELAY of data_chan_master_[13] is "IFD"
// synthesis attribute IOBDELAY_TYPE of data_chan_master_[13] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of data_chan_master_[13] is 0
// synthesis attribute NUM_CE of data_chan_master_[13] is 1
// synthesis attribute SERDES_MODE of data_chan_master_[13] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of data_chan_master_[14] is "TRUE"
// synthesis attribute DATA_RATE of data_chan_master_[14] is "DDR"
// synthesis attribute DATA_WIDTH of data_chan_master_[14] is 4
// synthesis attribute INTERFACE_TYPE of data_chan_master_[14] is "NETWORKING"
// synthesis attribute IOBDELAY of data_chan_master_[14] is "IFD"
// synthesis attribute IOBDELAY_TYPE of data_chan_master_[14] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of data_chan_master_[14] is 0
// synthesis attribute NUM_CE of data_chan_master_[14] is 1
// synthesis attribute SERDES_MODE of data_chan_master_[14] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of data_chan_master_[15] is "TRUE"
// synthesis attribute DATA_RATE of data_chan_master_[15] is "DDR"
// synthesis attribute DATA_WIDTH of data_chan_master_[15] is 4
// synthesis attribute INTERFACE_TYPE of data_chan_master_[15] is "NETWORKING"
// synthesis attribute IOBDELAY of data_chan_master_[15] is "IFD"
// synthesis attribute IOBDELAY_TYPE of data_chan_master_[15] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of data_chan_master_[15] is 0
// synthesis attribute NUM_CE of data_chan_master_[15] is 1
// synthesis attribute SERDES_MODE of data_chan_master_[15] is "MASTER"

// Synthesis Attributes for Window Monitor

// synthesis attribute BITSLIP_ENABLE of window_monitor_[0] is "TRUE"
// synthesis attribute DATA_RATE of window_monitor_[0] is "DDR"
// synthesis attribute DATA_WIDTH of window_monitor_[0] is 4
// synthesis attribute INTERFACE_TYPE of window_monitor_[0] is "NETWORKING"
// synthesis attribute IOBDELAY of window_monitor_[0] is "IFD"
// synthesis attribute IOBDELAY_TYPE of window_monitor_[0] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of window_monitor_[0] is 2
// synthesis attribute NUM_CE of window_monitor_[0] is 1
// synthesis attribute SERDES_MODE of window_monitor_[0] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of window_monitor_[1] is "TRUE"
// synthesis attribute DATA_RATE of window_monitor_[1] is "DDR"
// synthesis attribute DATA_WIDTH of window_monitor_[1] is 4
// synthesis attribute INTERFACE_TYPE of window_monitor_[1] is "NETWORKING"
// synthesis attribute IOBDELAY of window_monitor_[1] is "IFD"
// synthesis attribute IOBDELAY_TYPE of window_monitor_[1] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of window_monitor_[1] is 2
// synthesis attribute NUM_CE of window_monitor_[1] is 1
// synthesis attribute SERDES_MODE of window_monitor_[1] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of window_monitor_[2] is "TRUE"
// synthesis attribute DATA_RATE of window_monitor_[2] is "DDR"
// synthesis attribute DATA_WIDTH of window_monitor_[2] is 4
// synthesis attribute INTERFACE_TYPE of window_monitor_[2] is "NETWORKING"
// synthesis attribute IOBDELAY of window_monitor_[2] is "IFD"
// synthesis attribute IOBDELAY_TYPE of window_monitor_[2] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of window_monitor_[2] is 2
// synthesis attribute NUM_CE of window_monitor_[2] is 1
// synthesis attribute SERDES_MODE of window_monitor_[2] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of window_monitor_[3] is "TRUE"
// synthesis attribute DATA_RATE of window_monitor_[3] is "DDR"
// synthesis attribute DATA_WIDTH of window_monitor_[3] is 4
// synthesis attribute INTERFACE_TYPE of window_monitor_[3] is "NETWORKING"
// synthesis attribute IOBDELAY of window_monitor_[3] is "IFD"
// synthesis attribute IOBDELAY_TYPE of window_monitor_[3] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of window_monitor_[3] is 2
// synthesis attribute NUM_CE of window_monitor_[3] is 1
// synthesis attribute SERDES_MODE of window_monitor_[3] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of window_monitor_[4] is "TRUE"
// synthesis attribute DATA_RATE of window_monitor_[4] is "DDR"
// synthesis attribute DATA_WIDTH of window_monitor_[4] is 4
// synthesis attribute INTERFACE_TYPE of window_monitor_[4] is "NETWORKING"
// synthesis attribute IOBDELAY of window_monitor_[4] is "IFD"
// synthesis attribute IOBDELAY_TYPE of window_monitor_[4] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of window_monitor_[4] is 2
// synthesis attribute NUM_CE of window_monitor_[4] is 1
// synthesis attribute SERDES_MODE of window_monitor_[4] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of window_monitor_[5] is "TRUE"
// synthesis attribute DATA_RATE of window_monitor_[5] is "DDR"
// synthesis attribute DATA_WIDTH of window_monitor_[5] is 4
// synthesis attribute INTERFACE_TYPE of window_monitor_[5] is "NETWORKING"
// synthesis attribute IOBDELAY of window_monitor_[5] is "IFD"
// synthesis attribute IOBDELAY_TYPE of window_monitor_[5] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of window_monitor_[5] is 2
// synthesis attribute NUM_CE of window_monitor_[5] is 1
// synthesis attribute SERDES_MODE of window_monitor_[5] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of window_monitor_[6] is "TRUE"
// synthesis attribute DATA_RATE of window_monitor_[6] is "DDR"
// synthesis attribute DATA_WIDTH of window_monitor_[6] is 4
// synthesis attribute INTERFACE_TYPE of window_monitor_[6] is "NETWORKING"
// synthesis attribute IOBDELAY of window_monitor_[6] is "IFD"
// synthesis attribute IOBDELAY_TYPE of window_monitor_[6] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of window_monitor_[6] is 2
// synthesis attribute NUM_CE of window_monitor_[6] is 1
// synthesis attribute SERDES_MODE of window_monitor_[6] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of window_monitor_[7] is "TRUE"
// synthesis attribute DATA_RATE of window_monitor_[7] is "DDR"
// synthesis attribute DATA_WIDTH of window_monitor_[7] is 4
// synthesis attribute INTERFACE_TYPE of window_monitor_[7] is "NETWORKING"
// synthesis attribute IOBDELAY of window_monitor_[7] is "IFD"
// synthesis attribute IOBDELAY_TYPE of window_monitor_[7] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of window_monitor_[7] is 2
// synthesis attribute NUM_CE of window_monitor_[7] is 1
// synthesis attribute SERDES_MODE of window_monitor_[7] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of window_monitor_[8] is "TRUE"
// synthesis attribute DATA_RATE of window_monitor_[8] is "DDR"
// synthesis attribute DATA_WIDTH of window_monitor_[8] is 4
// synthesis attribute INTERFACE_TYPE of window_monitor_[8] is "NETWORKING"
// synthesis attribute IOBDELAY of window_monitor_[8] is "IFD"
// synthesis attribute IOBDELAY_TYPE of window_monitor_[8] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of window_monitor_[8] is 2
// synthesis attribute NUM_CE of window_monitor_[8] is 1
// synthesis attribute SERDES_MODE of window_monitor_[8] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of window_monitor_[9] is "TRUE"
// synthesis attribute DATA_RATE of window_monitor_[9] is "DDR"
// synthesis attribute DATA_WIDTH of window_monitor_[9] is 4
// synthesis attribute INTERFACE_TYPE of window_monitor_[9] is "NETWORKING"
// synthesis attribute IOBDELAY of window_monitor_[9] is "IFD"
// synthesis attribute IOBDELAY_TYPE of window_monitor_[9] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of window_monitor_[9] is 2
// synthesis attribute NUM_CE of window_monitor_[9] is 1
// synthesis attribute SERDES_MODE of window_monitor_[9] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of window_monitor_[10] is "TRUE"
// synthesis attribute DATA_RATE of window_monitor_[10] is "DDR"
// synthesis attribute DATA_WIDTH of window_monitor_[10] is 4
// synthesis attribute INTERFACE_TYPE of window_monitor_[10] is "NETWORKING"
// synthesis attribute IOBDELAY of window_monitor_[10] is "IFD"
// synthesis attribute IOBDELAY_TYPE of window_monitor_[10] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of window_monitor_[10] is 2
// synthesis attribute NUM_CE of window_monitor_[10] is 1
// synthesis attribute SERDES_MODE of window_monitor_[10] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of window_monitor_[11] is "TRUE"
// synthesis attribute DATA_RATE of window_monitor_[11] is "DDR"
// synthesis attribute DATA_WIDTH of window_monitor_[11] is 4
// synthesis attribute INTERFACE_TYPE of window_monitor_[11] is "NETWORKING"
// synthesis attribute IOBDELAY of window_monitor_[11] is "IFD"
// synthesis attribute IOBDELAY_TYPE of window_monitor_[11] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of window_monitor_[11] is 2
// synthesis attribute NUM_CE of window_monitor_[11] is 1
// synthesis attribute SERDES_MODE of window_monitor_[11] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of window_monitor_[12] is "TRUE"
// synthesis attribute DATA_RATE of window_monitor_[12] is "DDR"
// synthesis attribute DATA_WIDTH of window_monitor_[12] is 4
// synthesis attribute INTERFACE_TYPE of window_monitor_[12] is "NETWORKING"
// synthesis attribute IOBDELAY of window_monitor_[12] is "IFD"
// synthesis attribute IOBDELAY_TYPE of window_monitor_[12] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of window_monitor_[12] is 2
// synthesis attribute NUM_CE of window_monitor_[12] is 1
// synthesis attribute SERDES_MODE of window_monitor_[12] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of window_monitor_[13] is "TRUE"
// synthesis attribute DATA_RATE of window_monitor_[13] is "DDR"
// synthesis attribute DATA_WIDTH of window_monitor_[13] is 4
// synthesis attribute INTERFACE_TYPE of window_monitor_[13] is "NETWORKING"
// synthesis attribute IOBDELAY of window_monitor_[13] is "IFD"
// synthesis attribute IOBDELAY_TYPE of window_monitor_[13] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of window_monitor_[13] is 2
// synthesis attribute NUM_CE of window_monitor_[13] is 1
// synthesis attribute SERDES_MODE of window_monitor_[13] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of window_monitor_[14] is "TRUE"
// synthesis attribute DATA_RATE of window_monitor_[14] is "DDR"
// synthesis attribute DATA_WIDTH of window_monitor_[14] is 4
// synthesis attribute INTERFACE_TYPE of window_monitor_[14] is "NETWORKING"
// synthesis attribute IOBDELAY of window_monitor_[14] is "IFD"
// synthesis attribute IOBDELAY_TYPE of window_monitor_[14] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of window_monitor_[14] is 2
// synthesis attribute NUM_CE of window_monitor_[14] is 1
// synthesis attribute SERDES_MODE of window_monitor_[14] is "MASTER"

// synthesis attribute BITSLIP_ENABLE of window_monitor_[15] is "TRUE"
// synthesis attribute DATA_RATE of window_monitor_[15] is "DDR"
// synthesis attribute DATA_WIDTH of window_monitor_[15] is 4
// synthesis attribute INTERFACE_TYPE of window_monitor_[15] is "NETWORKING"
// synthesis attribute IOBDELAY of window_monitor_[15] is "IFD"
// synthesis attribute IOBDELAY_TYPE of window_monitor_[15] is "VARIABLE"
// synthesis attribute IOBDELAY_VALUE of window_monitor_[15] is 2
// synthesis attribute NUM_CE of window_monitor_[15] is 1
// synthesis attribute SERDES_MODE of window_monitor_[15] is "MASTER"

/*
assign dataout15 = {{q4[15],q3[15]},{q2[15],q1[15]}};
assign dataout14 = {{q4[14],q3[14]},{q2[14],q1[14]}};
assign dataout13 = {{q4[13],q3[13]},{q2[13],q1[13]}};
assign dataout12 = {{q4[12],q3[12]},{q2[12],q1[12]}};
assign dataout11 = {{q4[11],q3[11]},{q2[11],q1[11]}};
assign dataout10 = {{q4[10],q3[10]},{q2[10],q1[10]}};
assign dataout9 = {{q4[9],q3[9]},{q2[9],q1[9]}};
assign dataout8 = {{q4[8],q3[8]},{q2[8],q1[8]}};
assign dataout7 = {{q4[7],q3[7]},{q2[7],q1[7]}};
assign dataout6 = {{q4[6],q3[6]},{q2[6],q1[6]}};
assign dataout5 = {{q4[5],q3[5]},{q2[5],q1[5]}};
assign dataout4 = {{q4[4],q3[4]},{q2[4],q1[4]}};
assign dataout3 = {{q4[3],q3[3]},{q2[3],q1[3]}};
assign dataout2 = {{q4[2],q3[2]},{q2[2],q1[2]}};
assign dataout1 = {{q4[1],q3[1]},{q2[1],q1[1]}};
assign dataout0 = {{q4[0],q3[0]},{q2[0],q1[0]}};
*/

assign dataout15 = {{q1[15],q2[15]},{q3[15],q4[15]}};
assign dataout14 = {{q1[14],q2[14]},{q3[14],q4[14]}};
assign dataout13 = {{q1[13],q2[13]},{q3[13],q4[13]}};
assign dataout12 = {{q1[12],q2[12]},{q3[12],q4[12]}};
assign dataout11 = {{q1[11],q2[11]},{q3[11],q4[11]}};
assign dataout10 = {{q1[10],q2[10]},{q3[10],q4[10]}};
assign dataout9 = {{q1[9],q2[9]},{q3[9],q4[9]}};
assign dataout8 = {{q1[8],q2[8]},{q3[8],q4[8]}};
assign dataout7 = {{q1[7],q2[7]},{q3[7],q4[7]}};
assign dataout6 = {{q1[6],q2[6]},{q3[6],q4[6]}};
assign dataout5 = {{q1[5],q2[5]},{q3[5],q4[5]}};
assign dataout4 = {{q1[4],q2[4]},{q3[4],q4[4]}};
assign dataout3 = {{q1[3],q2[3]},{q3[3],q4[3]}};
assign dataout2 = {{q1[2],q2[2]},{q3[2],q4[2]}};
assign dataout1 = {{q1[1],q2[1]},{q3[1],q4[1]}};
assign dataout0 = {{q1[0],q2[0]},{q3[0],q4[0]}};


assign data_out = {dataout15, dataout14, dataout13, dataout12,
                   dataout11, dataout10, dataout9, dataout8,
						 dataout7, dataout6, dataout5, dataout4,
						 dataout3, dataout2, dataout1, dataout0};

/*
assign windowout15 = {{w4[15],w3[15]},{w2[15],w1[15]}};
assign windowout14 = {{w4[14],w3[14]},{w2[14],w1[14]}};
assign windowout13 = {{w4[13],w3[13]},{w2[13],w1[13]}};
assign windowout12 = {{w4[12],w3[12]},{w2[12],w1[12]}};
assign windowout11 = {{w4[11],w3[11]},{w2[11],w1[11]}};
assign windowout10 = {{w4[10],w3[10]},{w2[10],w1[10]}};
assign windowout9 = {{w4[9],w3[9]},{w2[9],w1[9]}};
assign windowout8 = {{w4[8],w3[8]},{w2[8],w1[8]}};
assign windowout7 = {{w4[7],w3[7]},{w2[7],w1[7]}};
assign windowout6 = {{w4[6],w3[6]},{w2[6],w1[6]}};
assign windowout5 = {{w4[5],w3[5]},{w2[5],w1[5]}};
assign windowout4 = {{w4[4],w3[4]},{w2[4],w1[4]}};
assign windowout3 = {{w4[3],w3[3]},{w2[3],w1[3]}};
assign windowout2 = {{w4[2],w3[2]},{w2[2],w1[2]}};
assign windowout1 = {{w4[1],w3[1]},{w2[1],w1[1]}};
assign windowout0 = {{w4[0],w3[0]},{w2[0],w1[0]}};
*/

assign windowout15 = {{w1[15],w2[15]},{w3[15],w4[15]}};
assign windowout14 = {{w1[14],w2[14]},{w3[14],w4[14]}};
assign windowout13 = {{w1[13],w2[13]},{w3[13],w4[13]}};
assign windowout12 = {{w1[12],w2[12]},{w3[12],w4[12]}};
assign windowout11 = {{w1[11],w2[11]},{w3[11],w4[11]}};
assign windowout10 = {{w1[10],w2[10]},{w3[10],w4[10]}};
assign windowout9 = {{w1[9],w2[9]},{w3[9],w4[9]}};
assign windowout8 = {{w1[8],w2[8]},{w3[8],w4[8]}};
assign windowout7 = {{w1[7],w2[7]},{w3[7],w4[7]}};
assign windowout6 = {{w1[6],w2[6]},{w3[6],w4[6]}};
assign windowout5 = {{w1[5],w2[5]},{w3[5],w4[5]}};
assign windowout4 = {{w1[4],w2[4]},{w3[4],w4[4]}};
assign windowout3 = {{w1[3],w2[3]},{w3[3],w4[3]}};
assign windowout2 = {{w1[2],w2[2]},{w3[2],w4[2]}};
assign windowout1 = {{w1[1],w2[1]},{w3[1],w4[1]}};
assign windowout0 = {{w1[0],w2[0]},{w3[0],w4[0]}};


// Pipeline ISERDES outputs
always @(posedge rst or posedge clkdiv)
begin
   if (rst)
   begin	  
	 dataout15_R1 <= 1'h0;
	 dataout14_R1 <= 1'h0;
	 dataout13_R1 <= 1'h0;
	 dataout12_R1 <= 1'h0;
	 dataout11_R1 <= 1'h0;
	 dataout10_R1 <= 1'h0;
	 dataout9_R1 <= 1'h0;
	 dataout8_R1 <= 1'h0;
	 dataout7_R1 <= 1'h0;
	 dataout6_R1 <= 1'h0;
	 dataout5_R1 <= 1'h0;
	 dataout4_R1 <= 1'h0;
	 dataout3_R1 <= 1'h0;
	 dataout2_R1 <= 1'h0;
	 dataout1_R1 <= 1'h0;
	 dataout0_R1 <= 1'h0;

	 windowout15_R1 <= 1'h0;
	 windowout14_R1 <= 1'h0;
	 windowout13_R1 <= 1'h0;
	 windowout12_R1 <= 1'h0;
	 windowout11_R1 <= 1'h0;
	 windowout10_R1 <= 1'h0;
	 windowout9_R1 <= 1'h0;
	 windowout8_R1 <= 1'h0;
	 windowout7_R1 <= 1'h0;
	 windowout6_R1 <= 1'h0;
	 windowout5_R1 <= 1'h0;
	 windowout4_R1 <= 1'h0;
	 windowout3_R1 <= 1'h0;
	 windowout2_R1 <= 1'h0;
	 windowout1_R1 <= 1'h0;
	 windowout0_R1 <= 1'h0;

   end
   else
   begin
	 dataout15_R1 <= dataout15;
	 dataout14_R1 <= dataout14;
	 dataout13_R1 <= dataout13;
	 dataout12_R1 <= dataout12;
	 dataout11_R1 <= dataout11;
	 dataout10_R1 <= dataout10;
	 dataout9_R1 <= dataout9;
	 dataout8_R1 <= dataout8;
	 dataout7_R1 <= dataout7;
	 dataout6_R1 <= dataout6;
	 dataout5_R1 <= dataout5;
	 dataout4_R1 <= dataout4;
	 dataout3_R1 <= dataout3;
	 dataout2_R1 <= dataout2;
	 dataout1_R1 <= dataout1;
	 dataout0_R1 <= dataout0;
 
	 windowout15_R1 <= windowout15;
	 windowout14_R1 <= windowout14;
	 windowout13_R1 <= windowout13;
	 windowout12_R1 <= windowout12;
	 windowout11_R1 <= windowout11;
	 windowout10_R1 <= windowout10;
	 windowout9_R1 <= windowout9;
	 windowout8_R1 <= windowout8;
	 windowout7_R1 <= windowout7;
	 windowout6_R1 <= windowout6;
	 windowout5_R1 <= windowout5;
	 windowout4_R1 <= windowout4;
	 windowout3_R1 <= windowout3;
	 windowout2_R1 <= windowout2;
	 windowout1_R1 <= windowout1;
	 windowout0_R1 <= windowout0;

   end	    	              
end

// Bitslip adjust Mux that selects between ISERDES and pipeline outputs
assign dataout_int15 = dataout_sel[15] ? dataout15_R1 : dataout15; 
assign dataout_int14 = dataout_sel[14] ? dataout14_R1 : dataout14; 
assign dataout_int13 = dataout_sel[13] ? dataout13_R1 : dataout13; 
assign dataout_int12 = dataout_sel[12] ? dataout12_R1 : dataout12; 
assign dataout_int11 = dataout_sel[11] ? dataout11_R1 : dataout11; 
assign dataout_int10 = dataout_sel[10] ? dataout10_R1 : dataout10; 
assign dataout_int9 = dataout_sel[9] ? dataout9_R1 : dataout9; 
assign dataout_int8 = dataout_sel[8] ? dataout8_R1 : dataout8; 
assign dataout_int7 = dataout_sel[7] ? dataout7_R1 : dataout7; 
assign dataout_int6 = dataout_sel[6] ? dataout6_R1 : dataout6; 
assign dataout_int5 = dataout_sel[5] ? dataout5_R1 : dataout5; 
assign dataout_int4 = dataout_sel[4] ? dataout4_R1 : dataout4; 
assign dataout_int3 = dataout_sel[3] ? dataout3_R1 : dataout3; 
assign dataout_int2 = dataout_sel[2] ? dataout2_R1 : dataout2; 
assign dataout_int1 = dataout_sel[1] ? dataout1_R1 : dataout1; 
assign dataout_int0 = dataout_sel[0] ? dataout0_R1 : dataout0; 

// Instantiate deskew module that implements bit alignment algorithm
deskew deskew_module (
      .datain(datain),
	 .edgei(edgei_training),
	 .rst(rst),
	 .deskew_en(op_sel[0]), 
	 .clkdiv(clkdiv),
	 .dlyce(dlyce_training),
	 .dlyinc(dlyinc_training),
	 .done(deskew_done)	  
	); 
    
// Instantiate the control module that implements the word alignment algorithm
bitslip_ctrl bitslip_control_module (
      .datain(datain),
	 .rst(rst),
	 .bitslip_en(op_sel[1]), 
	 .clkdiv(clkdiv),
	 .bitslip(bitslip_training),
	 .done(bitslip_done),
	 .error(bitslip_error)	  
	); 

// Instantiate the control module that implements the real-time window monitoring algorithm
   monitor_ctrl monitor_ctrl_module (      
      .datain(datain), 
      .datain_monitor(datain_monitor), 
	 .rst(rst),
	 //.monitor_en(train_done), 
	 .monitor_en(1'b0),
	 .clkdiv(clkdiv),
	 .dlyce_window(dlyce_window),
	 .dlyinc_window(dlyinc_window),
	 .dlyce(dlyce_monitor),
	 .dlyinc(dlyinc_monitor),
	 .monitor_done(monitor_done)	  
	);

// Multi-purpose Counter
always @(posedge cnt_rst or posedge clkdiv)
begin
   if (cnt_rst)
      counter <= 8'h00;
   else if (counter[2])
      counter <= 8'h00;
   else
      counter <= counter + 1'b1;
end      

// Module that controls the operation select (bit align, word align, bitslip adjust
// or window monitoring) and channel select.
always @(posedge rst or posedge clkdiv)
begin
   if (rst)
   begin	  
      op_sel <= 4'b0000;
	 train_done <= 1'b0;
      chan_sel <= 16'b0000_0000_0000_0000;
	 cnt_rst <= 1'b1;
	 dataout_sel_invert <= 1'b0;
   end
   else if (train_en)
   begin
      if (~|op_sel)
      begin	  
         op_sel <= 4'b0001;
	    train_done <= 1'b0;
         chan_sel <= 16'b0000_0000_0000_0001;
	    cnt_rst <= 1'b1;
	    dataout_sel_invert <= 1'b0;
      end 
      else if (op_sel[0])
      begin
         if (~|chan_sel)
	    begin
	       op_sel <= op_sel << 1;
	       train_done <= 1'b0;
            chan_sel <= 16'b0000_0000_0000_0001;
	       cnt_rst <= 1'b1;
	       dataout_sel_invert <= 1'b0;	    	    	     	    
	    end
	    else if (deskew_done)
	    begin
            op_sel <= op_sel;
            train_done <= 1'b0;
            chan_sel <= chan_sel << 1; 
	       cnt_rst <= 1'b1;
	       dataout_sel_invert <= 1'b0;	    	    	    
	    end
	    else
	    begin
            op_sel <= op_sel;
            train_done <= 1'b0;
            chan_sel <= chan_sel; 
	       cnt_rst <= 1'b1;
	       dataout_sel_invert <= 1'b0;	    	    	    
	    end
      end      
      else if (op_sel[1])
      begin
         if (~|chan_sel)
	    begin
	       op_sel <= op_sel << 1;
	       train_done <= 1'b0;
            chan_sel <= 16'b1000_0000_0000_0000;
	       cnt_rst <= 1'b0;
	       dataout_sel_invert <= 1'b0;	    	    	     	    
	    end
	    else if (bitslip_done)
	    begin
            op_sel <= op_sel;
            train_done <= 1'b0;
            chan_sel <= chan_sel << 1; 
	       cnt_rst <= 1'b1;
	       dataout_sel_invert <= 1'b0;	    	    	    
	     end
	    else
	    begin
            op_sel <= op_sel;
            train_done <= 1'b0;
            chan_sel <= chan_sel; 
	       cnt_rst <= 1'b1;
	       dataout_sel_invert <= 1'b0;	    	    	    
	    end
      end
      else if (op_sel[2])
      begin
         if (~|chan_sel)
	    begin
	       op_sel <= op_sel << 1;
	       train_done <= 1'b1;
            chan_sel <= 16'b0000_0000_0000_0001;	    
	       cnt_rst <= 1'b1;
		  dataout_sel_invert <= dataout_sel_invert;     		  	   	     	    	    
	    end
	    // If counter = 2
	    else if (counter[1] && ~counter[0]) 
	    begin
            op_sel <= op_sel;
            train_done <= 1'b0;
            chan_sel <= chan_sel;
		  cnt_rst <= 1'b0; 
	       if (~edgei_training[1])		  
	          dataout_sel_invert <= ~datain[3];
	       else
	          dataout_sel_invert <= dataout_sel_invert;	   	    	    
	    end
	    // If counter = 3, increment chan sel
	    else if (counter[1] & counter[0]) 
	    begin
            op_sel <= op_sel;
            train_done <= 1'b0;
            chan_sel <= chan_sel >> 1; 
	       cnt_rst <= 1'b0;
	       dataout_sel_invert <= dataout_sel_invert;	    	    	    
	    end
	    else
	    begin
            op_sel <= op_sel;
            train_done <= 1'b0;
            chan_sel <= chan_sel; 
	       cnt_rst <= 1'b0;
	       dataout_sel_invert <= dataout_sel_invert;	    	    	    
	    end
      end
      else if (op_sel[3])
      begin
	    op_sel <= op_sel;
	    train_done <= 1'b1;
	    cnt_rst <= 1'b1;
	    dataout_sel_invert <= dataout_sel_invert;	
         if (~|chan_sel)
            chan_sel <= 16'b0000_0000_0000_0001;    	    	     	    
	    else if (monitor_done)
            chan_sel <= chan_sel << 1; 	    	    	    
	    else
	    begin
            chan_sel <= chan_sel; 	    	    	    
	    end
	 end
      else
      begin
         op_sel <= 4'b0000;
	    train_done <= 1'b0;
         chan_sel <= 16'b0000_0000_0000_0000;
	    cnt_rst <= 1'b1;
	    dataout_sel_invert <= 1'b0;
	 end
   end
   else // !train_en
   begin 
      if (op_sel[3])
      begin
	    op_sel <= op_sel;
	    train_done <= 1'b1;
	    cnt_rst <= 1'b1;
	    dataout_sel_invert <= dataout_sel_invert;	
         if (~|chan_sel)
            chan_sel <= 16'b0000_0000_0000_0001;    	    	     	    
	    else if (monitor_done)
            chan_sel <= chan_sel << 1; 	    	    	    
	    else
	    begin
            chan_sel <= chan_sel; 	    	    	    
	    end
      end
      else
      begin
         op_sel <= 4'b0000;
	    train_done <= 1'b0;
         chan_sel <= 16'b0000_0000_0000_0000;
	    cnt_rst <= 1'b1;
	    dataout_sel_invert <= 1'b0;
      end
   end
end		

assign dataout_sel = dataout_sel_invert ? ~dataout_sel_int : dataout_sel_int;

// Dataout Channel Select Mux
assign muxout_d0d1 = chan_sel[1] ? dataout1_R1 : dataout0_R1;
assign muxout_d2d3 = chan_sel[3] ? dataout3_R1 : dataout2_R1;
assign muxout_d4d5 = chan_sel[5] ? dataout5_R1 : dataout4_R1;
assign muxout_d6d7 = chan_sel[7] ? dataout7_R1 : dataout6_R1;
assign muxout_d8d9 = chan_sel[9] ? dataout9_R1 : dataout8_R1;
assign muxout_d10d11 = chan_sel[11] ? dataout11_R1 : dataout10_R1;
assign muxout_d12d13 = chan_sel[13] ? dataout13_R1 : dataout12_R1;
assign muxout_d14d15 = chan_sel[15] ? dataout15_R1 : dataout14_R1;

assign muxout_d0_to_d3 = (chan_sel[2] | chan_sel[3]) ?  muxout_d2d3: muxout_d0d1;
assign muxout_d4_to_d7 = (chan_sel[6] | chan_sel[7]) ?  muxout_d6d7: muxout_d4d5;
assign muxout_d8_to_d11 = (chan_sel[10] | chan_sel[11]) ?  muxout_d10d11: muxout_d8d9;
assign muxout_d12_to_d15 = (chan_sel[14] | chan_sel[15]) ?  muxout_d14d15: muxout_d12d13;

// Pipeline Registers inserted in this stage
assign muxout_d0_to_d7 = (chan_sel[4] | chan_sel[5] | chan_sel[6] | chan_sel[7]) ?  muxout_d4_to_d7_R1: muxout_d0_to_d3_R1;
assign muxout_d8_to_d15 = (chan_sel[12] | chan_sel[13] | chan_sel[14] | chan_sel[15]) ?  muxout_d12_to_d15_R1: muxout_d8_to_d11_R1;

assign datain = (chan_sel[8] | chan_sel[9] | chan_sel[10] | chan_sel[11] | 
       chan_sel[12] | chan_sel[13] | chan_sel[14] | chan_sel[15]) ?  
       muxout_d8_to_d15: muxout_d0_to_d7;

// Window Monitor Channel Select Mux
assign muxout_w0w1 = chan_sel[1] ? windowout1_R1 : windowout0_R1;
assign muxout_w2w3 = chan_sel[3] ? windowout3_R1 : windowout2_R1;
assign muxout_w4w5 = chan_sel[5] ? windowout5_R1 : windowout4_R1;
assign muxout_w6w7 = chan_sel[7] ? windowout7_R1 : windowout6_R1;
assign muxout_w8w9 = chan_sel[9] ? windowout9_R1 : windowout8_R1;
assign muxout_w10w11 = chan_sel[11] ? windowout11_R1 : windowout10_R1;
assign muxout_w12w13 = chan_sel[13] ? windowout13_R1 : windowout12_R1;
assign muxout_w14w15 = chan_sel[15] ? windowout15_R1 : windowout14_R1;

assign muxout_w0_to_w3 = (chan_sel[2] | chan_sel[3]) ?  muxout_w2w3: muxout_w0w1;
assign muxout_w4_to_w7 = (chan_sel[6] | chan_sel[7]) ?  muxout_w6w7: muxout_w4w5;
assign muxout_w8_to_w11 = (chan_sel[10] | chan_sel[11]) ?  muxout_w10w11: muxout_w8w9;
assign muxout_w12_to_w15 = (chan_sel[14] | chan_sel[15]) ?  muxout_w14w15: muxout_w12w13;

// Pipeline Registers inserted in this stage
assign muxout_w0_to_w7 = (chan_sel[4] | chan_sel[5] | chan_sel[6] | chan_sel[7]) ?  muxout_w4_to_w7_R1: muxout_w0_to_w3_R1;
assign muxout_w8_to_w15 = (chan_sel[12] | chan_sel[13] | chan_sel[14] | chan_sel[15]) ?  muxout_w12_to_w15_R1: muxout_w8_to_w11_R1;

assign datain_monitor = (chan_sel[8] | chan_sel[9] | chan_sel[10] | chan_sel[11] | 
       chan_sel[12] | chan_sel[13] | chan_sel[14] | chan_sel[15]) ?  
       muxout_w8_to_w15: muxout_w0_to_w7;


// Pipline Registers for Mux
always @(posedge rst or posedge clkdiv)
begin
   if (rst)
   begin	
      muxout_d0_to_d3_R1 <= 4'b0;   
      muxout_d4_to_d7_R1 <= 4'b0;
      muxout_d8_to_d11_R1 <= 4'b0;
      muxout_d12_to_d15_R1 <= 4'b0;

      muxout_w0_to_w3_R1 <= 4'b0;   
      muxout_w4_to_w7_R1 <= 4'b0;
      muxout_w8_to_w11_R1 <= 4'b0;
      muxout_w12_to_w15_R1 <= 4'b0;

   end
   else
   begin
      muxout_d0_to_d3_R1 <= muxout_d0_to_d3;   
      muxout_d4_to_d7_R1 <= muxout_d4_to_d7;
      muxout_d8_to_d11_R1 <= muxout_d8_to_d11;
      muxout_d12_to_d15_R1 <= muxout_d12_to_d15;

      muxout_w0_to_w3_R1 <= muxout_w0_to_w3;   
      muxout_w4_to_w7_R1 <= muxout_w4_to_w7;
      muxout_w8_to_w11_R1 <= muxout_w8_to_w11;
      muxout_w12_to_w15_R1 <= muxout_w12_to_w15;

   end
end

// Instantiate muxes that route the bitslip, dlyce and dlyinc control signals to 
// the data ISERDES and monitor ISERDES.
generate
genvar k;
   for (k=0; k<=num_chan-1; k=k+1)
   begin :  bitslip_generate
      assign bitslip[k] = chan_sel[k] ? bitslip_training : 1'b0;	
      assign dlyce[k] = chan_sel[k] ? dlyce1 : 1'b0;
      assign dlyinc[k] = chan_sel[k] ? dlyinc1 : 1'b0;
      //assign dlyce[k] = chan_sel[k] ? dlyce_training : 1'b0;
      //assign dlyinc[k] = chan_sel[k] ? dlyinc_training : 1'b0;
		assign dlyce_to_data_iserdes[k] = dlyce[k] | ice_ext;
		assign dlyinc_to_data_iserdes[k] = dlyinc[k] | inc_ext;					
      assign dlyce_iserdes_window[k] = chan_sel[k] ? dlyce_iserdes_window1 : 1'b0;
      assign dlyinc_iserdes_window[k] = chan_sel[k] ? dlyinc_iserdes_window1 : 1'b0; 
		assign dlyce_to_monitor_iserdes[k] = dlyce_iserdes_window[k] | ice_ext;
		assign dlyinc_to_monitor_iserdes[k] = dlyinc_iserdes_window[k] | inc_ext;		 	 	 		   

	 // If counter = 2 and no edge found, select chan_sel
      always @(posedge rst or posedge clkdiv)
      begin
         if (rst)
	    begin
	       chan_sel1[k] <= 1'b0;
	    end
	    else if ((counter[1] && ~counter[0]) && ~edgei_training[1])
	    begin
	       chan_sel1[k] <= chan_sel[k];
	    end	        
	    else
	    begin
	       chan_sel1[k] <= 1'b0;
	    end
	 end	  	          

      always @(posedge rst or posedge clkdiv)
      begin
         if (rst)
	       dataout_sel_int[k] <= 1'b0;  
	    else	       
	       dataout_sel_int[k] <= dataout_sel_int[k] | chan_sel1[k];
	 end	  		   	    	 
   end 
endgenerate

always @(posedge rst or posedge clkdiv)
begin
   if (rst)
	begin
	   dlyce_training_R1 <= 1'b0;
		dlyinc_training_R1 <= 1'b0;
      dlyce1 <= 1'b0;
      dlyinc1 <= 1'b0;
      dlyce_iserdes_window1 <= 1'b0;			   
      dlyinc_iserdes_window1 <= 1'b0;	
   end
	else
	begin
	dlyce_training_R1 <= dlyce_training;
	dlyinc_training_R1 <= dlyinc_training;
	dlyce_monitor_R1 <= dlyce_monitor;
	dlyinc_monitor_R1 <= dlyinc_monitor;
	dlyce_window_R1 <= dlyce_window;
	dlyinc_window_R1 <= dlyinc_window;
      dlyce1 <= train_done ? dlyce_monitor_R1 : dlyce_training_R1;
      dlyinc1 <= train_done ? dlyinc_monitor_R1 : dlyinc_training_R1;
      dlyce_iserdes_window1 <= train_done ? dlyce_window_R1 : dlyce_training_R1;			   
      dlyinc_iserdes_window1 <= train_done ? dlyinc_window_R1 : dlyinc_training_R1;	
	end
end
	  	    			   
endmodule
