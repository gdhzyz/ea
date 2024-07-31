

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

`include "header.vh"

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
    output wire         phy_reset_n,  // 10ms for YT8511(document require 10us)
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
    output wire         uart_tx
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
    .fpga_index(fpga_index)
);

// =================== end reg ==================


`ifdef DO_DPA
`else  // DO_DPA
// =================== mac ==================

// IODELAY elements for RGMII interface to PHY
wire [3:0] phy_rxd_delay;
wire       phy_rx_ctl_delay;

IDELAYCTRL
idelayctrl_inst (
    .REFCLK(clk_200mhz_int),
    .RST(rst_int),
    .RDY()
);

IDELAYE2 #(
    .IDELAY_TYPE("FIXED")
)
phy_rxd_idelay_0 (
    .IDATAIN(phy_rxd[0]),
    .DATAOUT(phy_rxd_delay[0]),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

IDELAYE2 #(
    .IDELAY_TYPE("FIXED")
)
phy_rxd_idelay_1 (
    .IDATAIN(phy_rxd[1]),
    .DATAOUT(phy_rxd_delay[1]),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

IDELAYE2 #(
    .IDELAY_TYPE("FIXED")
)
phy_rxd_idelay_2 (
    .IDATAIN(phy_rxd[2]),
    .DATAOUT(phy_rxd_delay[2]),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

IDELAYE2 #(
    .IDELAY_TYPE("FIXED")
)
phy_rxd_idelay_3 (
    .IDATAIN(phy_rxd[3]),
    .DATAOUT(phy_rxd_delay[3]),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

IDELAYE2 #(
    .IDELAY_TYPE("FIXED")
)
phy_rx_ctl_idelay (
    .IDATAIN(phy_rx_ctl),
    .DATAOUT(phy_rx_ctl_delay),
    .DATAIN(1'b0),
    .C(1'b0),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(5'd0),
    .CNTVALUEOUT(),
    .LD(1'b0),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

wire debug_led;
wire mdio_i;
wire mdio_o;
wire mdio_t;

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
    .phy_rx_clk(phy_rx_clk),
    .phy_rxd(phy_rxd_delay),
    .phy_rx_ctl(phy_rx_ctl_delay),
    .phy_tx_clk(phy_tx_clk),
    .phy_txd(phy_txd),
    .phy_tx_ctl(phy_tx_ctl),
    .phy_reset_n(phy_reset_n),

    /*
     * MDIO
     */
    .mdio_valid(mdio_valid),
    .mdio_write(mdio_write),
    .mdio_ready(mdio_ready),
    .mdio_addr(mdio_addr),
    .mdio_wdata(mdio_wdata),
    .mdio_rdata(mdio_rdata),
    .mdio_phy_i(mdio_i),
    .mdio_phy_o(mdio_o),
    .mdio_phy_t(mdio_t),
    .mdio_phy_c(mdio_c),

    .debug_led(debug_led)
);

assign mdio_d = mdio_t ? 1'bz : mdio_o;
assign mdio_i = mdio_d;

// =================== end mac ==================
`endif // DO_DPA


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



endmodule

`resetall
