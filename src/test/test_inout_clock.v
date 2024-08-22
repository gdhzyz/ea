// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * FPGA top-level module
 */
module test_inout_clock #(
    localparam I2S_CN = 1   // I2S channel number
)(
    /*
     * Clock: 50MHz
     * Reset: Push button, active high
     */
    input  wire                 clk_50mhz,

    (* mark_debug = "false" *)inout  wire [I2S_CN-1:0]    i2s_in_bclk,
    (* mark_debug = "false" *)input  wire [I2S_CN-1:0]    i2s_in_bclkt,
    (* mark_debug = "false" *)output wire [I2S_CN-1:0]    i2s_out_datout
);

// Clock and reset
wire clk_50mhz_ibufg;

// Internal 125 MHz clock
wire clk_mmcm_out;
wire clk_int;
wire clk90_mmcm_out;
wire clk90_int;
(* mark_debug = "false" *)wire rst_int;

wire clk_200mhz_mmcm_out;
wire clk_200mhz_int;

wire mmcm_rst = 1'b0;
(* mark_debug = "false" *)wire mmcm_locked;
wire mmcm_clkfb;

IBUFG
clk_50mhz_ibufg_inst(
    .I(clk_50mhz),
    .O(clk_50mhz_ibufg)
);

// MMCM instance
// 50 MHz in, 125 MHz out
// PFD range: 10 MHz to 500 MHz
// VCO range: 600 MHz to 1440 MHz
// M = 20, D = 1 sets Fvco = 1000 MHz (in range)
// Divide by 8 to get output frequency of 125 MHz
// Need two 125 MHz outputs with 90 degree offset
// Also need 200 MHz out for IODELAY
// 1000 / 5 = 200 MHz
// The goal is to make D and M values as small as possible while keeping ƒVCO as high as possible.
// Dmin = ceil(50 / 500) = 1; Dmax = floor(50 / 10) = 5
// Mmin = ceil(600 / 50 * 1) = 12, Mmax = floor(1440 / 50 * 5) = 144, Mideal = 1 * 1000 / 50 = 20

MMCME2_BASE #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKOUT0_DIVIDE_F(8),
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT0_PHASE(0),
    .CLKOUT1_DIVIDE(8),
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT1_PHASE(90),
    .CLKOUT2_DIVIDE(5),
    .CLKOUT2_DUTY_CYCLE(0.5),
    .CLKOUT2_PHASE(0),
    .CLKOUT3_DIVIDE(1),
    .CLKOUT3_DUTY_CYCLE(0.5),
    .CLKOUT3_PHASE(0),
    .CLKOUT4_DIVIDE(1),
    .CLKOUT4_DUTY_CYCLE(0.5),
    .CLKOUT4_PHASE(0),
    .CLKOUT5_DIVIDE(1),
    .CLKOUT5_DUTY_CYCLE(0.5),
    .CLKOUT5_PHASE(0),
    .CLKOUT6_DIVIDE(1),
    .CLKOUT6_DUTY_CYCLE(0.5),
    .CLKOUT6_PHASE(0),
    .CLKFBOUT_MULT_F(20),
    .CLKFBOUT_PHASE(0),
    .DIVCLK_DIVIDE(1),
    .REF_JITTER1(0.010),
    .CLKIN1_PERIOD(5.0),
    .STARTUP_WAIT("FALSE"),
    .CLKOUT4_CASCADE("FALSE")
)
clk_mmcm_inst (
    .CLKIN1(clk_50mhz_ibufg),
    .CLKFBIN(mmcm_clkfb),
    .RST(mmcm_rst),
    .PWRDWN(1'b0),
    .CLKOUT0(clk_mmcm_out),
    .CLKOUT0B(),
    .CLKOUT1(clk90_mmcm_out),
    .CLKOUT1B(),
    .CLKOUT2(clk_200mhz_mmcm_out),
    .CLKOUT2B(),
    .CLKOUT3(),
    .CLKOUT3B(),
    .CLKOUT4(),
    .CLKOUT5(),
    .CLKOUT6(),
    .CLKFBOUT(mmcm_clkfb),
    .CLKFBOUTB(),
    .LOCKED(mmcm_locked)
);

BUFG
clk_bufg_inst (
    .I(clk_mmcm_out),
    .O(clk_int)
);

BUFG
clk90_bufg_inst (
    .I(clk90_mmcm_out),
    .O(clk90_int)
);

BUFG
clk_200mhz_bufg_inst (
    .I(clk_200mhz_mmcm_out),
    .O(clk_200mhz_int)
);

sync_reset #(
    .N(4)
)
sync_reset_inst (
    .clk(clk_int),
    .rst(~mmcm_locked),
    .out(rst_int)
);




wire clk_31_25m;
freq_divider #(
    .MAX_FACTOR(4)
) freq_divider_inst (
    .rst(rst_int),
    .clk(clk_int),
    .enable(1'b1),
    .oclk(clk_31_25m),
    .factor(4)
);


assign i2s_in_bclk[0] = i2s_in_bclkt[0] ? clk_31_25m : 1'bz;

wire bclk = i2s_in_bclk[0];

wire bclk_bufr;
BUFR bclk_bufr_inst (
    .I(bclk),
    .O(bclk_bufr),
    .CE(1'b1),
    .CLR(1'b0)
);

//wire bclk_bufr;
//BUFR bclk_bufr_inst(
//    .I(bclk),
//    .CE(1'b1),
//    .CLR(1'b0),
//    .O(bclk_bufr)
//);

wire bclk_bufgmux;
BUFGMUX #(
)
bclk_bufgmux_inst (
   .O(bclk_bufgmux),   // 1-bit output: Clock output
   .I0(bclk_bufr), // 1-bit input: Clock input (S=0)
   .I1(clk_31_25m), // 1-bit input: Clock input (S=1)
   .S(i2s_in_bclkt[0])    // 1-bit input: Clock select
);

(* mark_debug = "false" *)reg [3:0] bclk_count=0;
always @(posedge bclk_bufgmux) begin
    bclk_count <= bclk_count + 1;
end

(* mark_debug = "false" *)reg [3:0] clk_bclk_count=0;
always @(posedge bclk_bufgmux) begin
    clk_bclk_count <= clk_bclk_count + 1;
end

assign i2s_out_datout[0] = bclk_count[3];


endmodule

`resetall
