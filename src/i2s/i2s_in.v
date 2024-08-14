

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * I2S from ADC
 */
module i2s_in 
(
    /* clock: 125MHz
     * Asynchronous reset
     */
    input  wire             clk,
    input  wire             arst,

    /*
     * I2S master clock from outside FPGA, 24.576MHz
     */
    input  wire             mclki,

    /*
     * I2S IOs
     */
    input  wire [15:0]      bclki,
    input  wire [15:0]      lrcki,
    output wire [15:0]      bclko,
    output wire [15:0]      lrcko,
    output wire [15:0]      bclkt,
    output wire [15:0]      lrckt,
    input  wire [15:0]      datai,

    /*
     * I2S parallel output, synchronized with bclk.
     */
    output wire [15:0]      m_axis_tvalid,
    output wire [511:0]     m_axis_tdata,
    output wire [15:0]      m_axis_tlast,

    /*
     * configuration, synchronized to clk.
     */
    input  wire [3*16-1:0]  i_tdm_num,
    input  wire [15:0]      i_is_master,
    input  wire [15:0]      i_enable,
    input  wire [4*16-1:0]  i_dst_fpga_index,
    input  wire [15:0]      i_word_width,
    input  wire [2*16-1:0]  i_valid_word_width,
    input  wire [15:0]      i_lrck_is_pulse,
    input  wire [15:0]      i_lrck_polarity,  // edge of starting flag, 1'b0: posedge, 1'b1: negedge.
    input  wire [15:0]      i_lrck_alignment, // MSB alignment with lrck, 1'b0: aligned, 1'b1: one clock delay
    output wire [32*16-1:0] o_frame_num,
    input  wire [3*16-1:0]  i_bclk_factor
);


// ==================== mmcm =======================
wire mclki_ibufg;
IBUFG
mclki_ibufg_inst(
    .I(mclki),
    .O(mclki_ibufg)
);

wire clk_mmcm_out;
wire mmcm_clkfb;
wire mmcm_rst = arst;
wire mmcm_locked;

// MMCM instance
// 24.576 MHz in, 98.304 MHz out
// PFD range: 10 MHz to 500 MHz
// VCO range: 600 MHz to 1440 MHz
// M = 40.5, D = 1 sets Fvco = 995.328 MHz (in range)
// Divide by 10.125 to get output frequency of 125 MHz
// Need two 125 MHz outputs with 90 degree offset
// Also need 200 MHz out for IODELAY
// 1000 / 5 = 200 MHz
// The goal is to make D and M values as small as possible while keeping ƒVCO as high as possible.
// Dmin = ceil(50 / 500) = 1; Dmax = floor(50 / 10) = 5
// Mmin = ceil(600 / 50 * 1) = 12, Mmax = floor(1440 / 50 * 5) = 144, Mideal = 1 * 1000 / 50 = 20

MMCME2_BASE #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKOUT0_DIVIDE_F(10.125),
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
    .CLKFBOUT_MULT_F(40.5),
    .CLKFBOUT_PHASE(0),
    .DIVCLK_DIVIDE(1),
    .REF_JITTER1(0.010),
    .CLKIN1_PERIOD(40.690),
    .CLKIN2_PERIOD(10),
    .COMPENSATION("ZHOLD"),
    .STARTUP_WAIT("FALSE"),
    .CLKOUT4_CASCADE("FALSE")
)
clk_mmcm_inst (
    .CLKIN1(mclki_ibufg),
    .CLKFBIN(mmcm_clkfb),
    .RST(mmcm_rst),
    .PWRDWN(1'b0),
    .CLKOUT0(clk_mmcm_out),
    .CLKOUT0B(),
    .CLKOUT1(),
    .CLKOUT1B(),
    .CLKOUT2(),
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

wire mclk_int;
BUFG
clk_bufg_inst (
    .I(clk_mmcm_out),
    .O(mclk_int)
);

// ==================== reset =======================
wire rst_int;
sync_reset #(
    .N(4)
)
sync_reset_inst (
    .clk(mclk_int),
    .rst(~mmcm_locked),
    .out(rst_int)
);


generate
genvar i;


for (i = 0; i < 16; i = i + 1) begin
// ================== register parsers ==================
    wire [4:0]   parsed_tdm_num;
    wire         parsed_is_master;
    wire         parsed_enable;
    wire [3:0]   parsed_dst_fpga_index;
    wire [5:0]   parsed_word_width;
    wire [5:0]   parsed_valid_word_width;
    wire         parsed_lrck_is_pulse;
    wire         parsed_lrck_polarity;
    wire         parsed_lrck_alignment;
    wire [4:0]   parsed_bclk_factor;
    
    // ---- tdm_num ----
    tdm_num_parser tdm_num_parser (
        .clk(clk),
        .tdm_num(i_tdm_num[3*i +: 3]),
        .tdm_num_real(parsed_tdm_num)
    );
    
    // ---- word_with ----
    word_with_parser word_with_parser (
        .clk(clk),
        .word_width(i_word_width[i]),
        .word_width_real(parsed_word_width)
    );
    
    // ---- valid_word_width ----
    valid_word_with_parser valid_word_with_parser (
        .clk(clk),
        .valid_word_width(i_valid_word_width[2*i +: 2]),
        .valid_word_width_real(parsed_valid_word_width)
    );
    
    // ---- bclk_factor ----
    bclk_factor_parser bclk_factor_parser (
        .clk(clk),
        .bclk_factor(i_bclk_factor[3*i +: 3]),
        .bclk_factor_real(parsed_bclk_factor)
    );

    assign parsed_is_master = i_is_master[i];
    assign parsed_enable = i_enable[i];
    assign parsed_dst_fpga_index = i_dst_fpga_index[4*i +: 4];
    assign parsed_lrck_is_pulse = i_lrck_is_pulse[i];
    assign parsed_lrck_polarity = i_lrck_polarity[i];
    assign parsed_lrck_alignment = i_lrck_alignment[i];

    // ======================== frequency divider ==========
    i2s_freq_divider i2s_freq_divider (
        /*
         * Clock: 24.576MHz * 4
         * Synchronous reset
         */
        .mclki(mclk_int),
        .rst(rst_int),
        .enable(parsed_enable),
        .bclk(bclko[i]),
        .lrck(lrcko[i]),
        .bclk_factor(parsed_bclk_factor),
        .word_width(parsed_word_width)
    );

    // ======================== i2s_phy_in ==========
    i2s_phy_in i2s_phy_in (
        .rst(rst_int),
        .bclk(bclki[i]),
        .lrck(lrcki[i]),
        .datai(datai[i]),
        .m_axis_tvalid(m_axis_tvalid[i]),
        .m_axis_tdata(m_axis_tdata[32*i +: 32]),
        .m_axis_tlast(m_axis_tlast[i]),
        .i_tdm_num(parsed_tdm_num),
        .i_word_width(parsed_word_width),
        .i_lrck_polarity(parsed_lrck_polarity),
        .i_lrck_alignment(parsed_lrck_alignment),
        .o_frame_num(o_frame_num[32*i +: 32])
    );
 
end
    
endgenerate

endmodule

`resetall
