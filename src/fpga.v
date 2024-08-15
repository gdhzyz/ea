



// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

`include "head.vh"

/*
 * FPGA top-level module
 */
module fpga (
    /*
     * Clock: 50MHz
     * Reset: Push button, active high
     */
    input  wire         clk_50mhz,
    input  wire         reset,

    /*
     * Ethernet: 1000BASE-T RGMII
     */
    input  wire         phy_rx_clk,
    input  wire [3:0]   phy_rxd,
    input  wire         phy_rx_ctl,
    output wire         phy_tx_clk,
    output wire [3:0]   phy_txd,
    output wire         phy_tx_ctl,
    output wire         phy_reset_n,  // 100ms for YT8511(document require 10us)
    //input  wire       phy_int_n,

    output wire         mdio_c,
    inout  wire         mdio_d,


    /*
     * Leds
     */
    output reg          led1 = 1'b1,
    output reg          led2 = 1'b1,

    ///*
    // * keys
    // */
    //input  wire       key1,
    //input  wire       key2

    /*
     * uart
     */
    input  wire         uart_rx,
    output wire         uart_tx,

    /*
     * i2s
     */
    input  wire         i2s_in_mclki,
    inout  wire [15:0]  i2s_in_bclk,
    inout  wire [15:0]  i2s_in_lrck,
    input  wire [15:0]  i2s_in_datin,
    output wire [15:0]  i2s_out_datout
);

// Clock and reset
wire clk_50mhz_ibufg;

// Internal 125 MHz clock
wire clk_mmcm_out;
wire clk_int;
wire clk90_mmcm_out;
wire clk90_int;
wire rst_int;

wire clk_200mhz_mmcm_out;
wire clk_200mhz_int;

wire mmcm_rst = !reset;
wire mmcm_locked;
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

wire        srst; // soft reset
wire [3:0]  fpga_index;
(* mark_debug = "true" *)wire [4:0]  mac_dly_incs;
(* mark_debug = "true" *)wire [24:0] mac_dly_values;
(* mark_debug = "true" *)wire        mac_enable_jumbo_test;
wire [4:0]  mac_jumbo_errors;
wire [4:0]  mac_jumbo_error_clears;

// i2s in
wire [47:0]     i2s_in_tdm_num;
wire [15:0]     i2s_in_is_master;
wire [15:0]     i2s_in_enable;
wire [63:0]     i2s_in_fpga_index;
wire [15:0]     i2s_in_word_width;
wire [31:0]     i2s_in_valid_word_width;
wire [15:0]     i2s_in_lrck_is_pulse;
wire [15:0]     i2s_in_lrck_polarity;
wire [15:0]     i2s_in_lrck_alignment;
wire [63:0]     i2s_in_i2s_index;
wire [511:0]    i2s_in_frame_num;
wire [47:0]     i2s_in_bclk_factor;

wire        mdio_valid;
wire        mdio_write;
wire        mdio_ready;
wire [4:0]  mdio_addr;
wire [15:0] mdio_wdata;
wire [15:0] mdio_rdata;

// =================== reg ==================
reg_intf reg_intf(
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    .clk(clk_int),
    .rst(rst_int),
    .srst(srst),

    /*
     * UART
     */
    .uart_intf_rx(uart_rx),
    .uart_intf_tx(uart_tx),

    /*
     * MDIO
     */
    .mdio_valid(mdio_valid),
    .mdio_write(mdio_write),
    .mdio_ready(mdio_ready),
    .mdio_addr(mdio_addr),
    .mdio_wdata(mdio_wdata),
    .mdio_rdata(mdio_rdata),

     /*
     * configurations
     */
    .fpga_index(fpga_index),
    .mac_dly_incs(mac_dly_incs),
    .mac_dly_values(mac_dly_values),
    .mac_enable_jumbo_test(mac_enable_jumbo_test),
    .mac_jumbo_errors(mac_jumbo_errors),
    .mac_jumbo_error_clears(mac_jumbo_error_clears),
    // i2s in
    .i2s_in_tdm_num(i2s_in_tdm_num),
    .i2s_in_is_master(i2s_in_is_master),
    .i2s_in_enable(i2s_in_enable),
    .i2s_in_fpga_index(i2s_in_fpga_index),
    .i2s_in_word_width(i2s_in_word_width),
    .i2s_in_valid_word_width(i2s_in_valid_word_width),
    .i2s_in_lrck_is_pulse(i2s_in_lrck_is_pulse),
    .i2s_in_lrck_polarity(i2s_in_lrck_polarity),
    .i2s_in_lrck_alignment(i2s_in_lrck_alignment),
    .i2s_in_i2s_index(i2s_in_i2s_index),
    .i2s_in_frame_num(i2s_in_frame_num),
    .i2s_in_bclk_factor(i2s_in_bclk_factor)
);

// =================== end reg ==================

wire debug_led;
wire deskew_done;
wire mdio_i;
wire mdio_o;
wire mdio_t;

`ifdef DO_DPA
dpa dpa (
    .clk_200m(clk_200mhz_int),
    .clk(clk_int), // 125mhz
    .clk90(clk90_int), // 125mhz, shifted 90 degree
    .rst(rst_int),
    .phy_reset_n(phy_reset_n),
    
    .phy_rx_clk(phy_rx_clk),
    .phy_rxd(phy_rxd),
    .phy_rx_ctl(phy_rx_ctl),
    .phy_tx_clk(phy_tx_clk),
    .phy_txd(phy_txd),
    .phy_tx_ctl(phy_tx_ctl),
    
    .deskew_done(deskew_done)
);

assign     debug_led = 1'b1;

`else  // DO_DPA

// =================== mac ==================

// IODELAY elements for RGMII interface to PHY
wire [3:0] phy_rxd_delay;
wire       phy_rx_ctl_delay;
wire       phy_rx_clk_delay = phy_rx_clk;

localparam PHY_RX_DATA_DELAY_TAGS = 5'd25; // each tags is 78ps, 25 tags is 1950ps

IDELAYCTRL
idelayctrl_inst (
    .REFCLK(clk_200mhz_int),
    .RST(rst_int),
    .RDY()
);

IDELAYE2 #(
    .IDELAY_TYPE("VARIABLE")
)
phy_rxd_idelay_0 (
    .IDATAIN(phy_rxd[0]),
    .DATAOUT(phy_rxd_delay[0]),
    .DATAIN(1'b0),
    .C(clk_int),
    .CE(mac_dly_incs[0]),
    .INC(mac_dly_incs[0]),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(mac_dly_values[5*0 +: 5]),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

IDELAYE2 #(
    .IDELAY_TYPE("VARIABLE")
)
phy_rxd_idelay_1 (
    .IDATAIN(phy_rxd[1]),
    .DATAOUT(phy_rxd_delay[1]),
    .DATAIN(1'b0),
    .C(clk_int),
    .CE(mac_dly_incs[1]),
    .INC(mac_dly_incs[1]),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(mac_dly_values[5*1 +: 5]),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

IDELAYE2 #(
    .IDELAY_TYPE("VARIABLE")
)
phy_rxd_idelay_2 (
    .IDATAIN(phy_rxd[2]),
    .DATAOUT(phy_rxd_delay[2]),
    .DATAIN(1'b0),
    .C(clk_int),
    .CE(mac_dly_incs[2]),
    .INC(mac_dly_incs[2]),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(mac_dly_values[5*2 +: 5]),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

IDELAYE2 #(
    .IDELAY_TYPE("VARIABLE")
)
phy_rxd_idelay_3 (
    .IDATAIN(phy_rxd[3]),
    .DATAOUT(phy_rxd_delay[3]),
    .DATAIN(1'b0),
    .C(clk_int),
    .CE(mac_dly_incs[3]),
    .INC(mac_dly_incs[3]),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(mac_dly_values[5*3 +: 5]),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

IDELAYE2 #(
    .IDELAY_TYPE("VARIABLE")
)
phy_rx_ctl_idelay (
    .IDATAIN(phy_rx_ctl),
    .DATAOUT(phy_rx_ctl_delay),
    .DATAIN(1'b0),
    .C(clk_int),
    .CE(mac_dly_incs[4]),
    .INC(mac_dly_incs[4]),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(mac_dly_values[5*4 +: 5]),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

fpga_core #(
    .TARGET("XILINX")
)
core_inst (
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    .clk(clk_int),
    .clk90(clk90_int),
    .rst(rst_int),
    
    /*
     * Ethernet: 1000BASE-T RGMII
     */
    .phy_rx_clk(phy_rx_clk_delay),
    .phy_rxd(phy_rxd_delay),
    .phy_rx_ctl(phy_rx_ctl_delay),
    .phy_tx_clk(phy_tx_clk),
    .phy_txd(phy_txd),
    .phy_tx_ctl(phy_tx_ctl),
    .phy_reset_n(phy_reset_n),

    .debug_led(debug_led),
    .enable_jumbo_test(mac_enable_jumbo_test),
    .jumbo_errors(mac_jumbo_errors),
    .jumbo_error_clears(mac_jumbo_error_clears)
);
// =================== end mac ==================
`endif // DO_DPA

// =================== mdio ==================
reg clk_2_5m=1;
mdio_if mdio_if (
    .Clk(clk_int),
    .Rst(rst_int),
    .MDIO_Clk(clk_2_5m),
    .MDIO_en(mdio_valid),
    .MDIO_OP(~mdio_write),
    .MDIO_Req(mdio_valid),
    .MDIO_PHY_AD(5'b00100),
    .MDIO_REG_AD(mdio_addr),
    .MDIO_WR_DATA(mdio_wdata),
    .MDIO_RD_DATA(mdio_rdata),
    .MDIO_done(mdio_ready),
    .PHY_MDIO_I(mdio_i),
    .PHY_MDIO_O(mdio_o),
    .PHY_MDIO_T(mdio_t),
    .PHY_MDC(mdio_c)
);

// divide 125MHz into 2.5MHz.
localparam F125MHz = 125 * 1000 * 1000;
localparam F2_5MHz = 25 * 1000 * 1000 / 10;
localparam FRATIO_HALF = F125MHz / F2_5MHz / 2;
localparam FRATIO_WIDTH = $clog2(FRATIO_HALF);
reg [FRATIO_WIDTH-1:0] fcounter=0;
always @(posedge clk_int) begin
    if (rst_int) begin
        fcounter <= 0;
    end else if (fcounter == FRATIO_HALF-1) begin
        fcounter <= 0;
    end else begin
        fcounter <= fcounter + 1;
    end
end

always @(posedge clk_int) begin
    if (rst_int) begin
        clk_2_5m <= 1;
    end else if (fcounter == FRATIO_HALF-1) begin
        clk_2_5m <= ~clk_2_5m;
    end
end

assign mdio_d = mdio_t ? 1'bz : mdio_o;
assign mdio_i = mdio_d;

// =================== end mdio ==================

// =================== i2s ==================
localparam I2S_CN = 16;   // I2S channel number

wire [I2S_CN-1:0] i2s_in_bclki;
wire [I2S_CN-1:0] i2s_in_bclko;
wire [I2S_CN-1:0] i2s_in_bclkt;
wire [I2S_CN-1:0] i2s_in_lrcki;
wire [I2S_CN-1:0] i2s_in_lrcko;
wire [I2S_CN-1:0] i2s_in_lrckt;

wire i2s_in_m_axis_tvalid;
wire [7:0] i2s_in_m_axis_tdata;
wire i2s_in_m_axis_tlast;

i2s_in_fifo #(
    .CN(I2S_CN)
) i2s_in_fifo (
    .sys_clk(clk_int),
    .arst(rst_int),

    .mclki(i2s_in_mclki),
    .bclki(i2s_in_bclki),
    .lrcki(i2s_in_lrcki),
    .bclko(i2s_in_bclko),
    .lrcko(i2s_in_lrcko),
    .bclkt(i2s_in_bclkt),
    .lrckt(i2s_in_lrckt),
    .datai(i2s_in_datin),
    
    .m_axis_tvalid(i2s_in_m_axis_tvalid),
    .m_axis_tdata(i2s_in_m_axis_tdata),
    .m_axis_tlast(i2s_in_m_axis_tlast)


);

genvar i;
generate 

    for (i = 0; i < 16; i = i + 1) begin
        assign i2s_in_bclk[i] = i2s_in_bclkt ? i2s_in_bclko : 1'bz;
        assign i2s_in_lrck[i] = i2s_in_lrckt ? i2s_in_lrcko : 1'bz;
        assign i2s_in_bclki = i2s_in_bclk;
        assign i2s_in_lrcki = i2s_in_lrck;
    end
endgenerate

// =================== end i2s ==================

// =================== debug ==================
/*
 * Leds
 */

always @(posedge clk_int) begin
    led1 <= !debug_led; // 0: on, 1: off.
end

localparam time_1s = 125000000;
reg [31 : 0] led2_count = 'd0;
always @(posedge clk_int) begin
    if (rst_int) begin
        led2_count <= 'd0;
    end else if (led2_count == time_1s) begin
        led2_count <= 'd0;
    end else begin
        led2_count <= led2_count + 'd1;
    end
end

always @(posedge clk_int) begin
    if (led2_count == time_1s) begin
        led2 <= !led2;
    end
end

///*
// * switch and bottons
// */
//
//wire key1_int;
//wire key2_int;
// 
//debounce_switch #(
//    .WIDTH(2),
//    .N(4),
//    .RATE(125000)
//)
//debounce_switch_inst (
//    .clk(clk_int),
//    .rst(rst_int),
//    .in({key1,
//         key2}
//        ),
//    .out({key1_int,
//        key2_int})
//);


reg [31:0] time_seconds='d0;
reg [31:0] time_counter='d0;
always @(posedge clk_int) begin
    if (rst_int) begin
        time_seconds <= 'd0;
        time_counter <= 'd0;
    end else if (time_counter == time_1s - 1) begin
        time_seconds <= time_seconds + 'd1;
        time_counter <= 'd0;
    end else begin
        time_counter <= time_counter + 'd1;
    end
end
// =================== end debug ==================


endmodule

`resetall
