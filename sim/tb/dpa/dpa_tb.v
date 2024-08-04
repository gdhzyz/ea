

`timescale 1ns/1ps
  
module dpa_tb ();
 
   
wire clk;     
wire clk90;     
wire clk_200m;
wire reset;

wire         phy_rx_clk;
wire [3:0]   phy_rxd;
wire         phy_rx_ctl;
wire         phy_tx_clk;
wire [3:0]   phy_txd;
wire         phy_tx_ctl;

assign #(2) clk90 = clk;

dpa #(
    .TIME_200MS(125*1000) // to accelerate simulation
)dut (
.clk_200m(clk_200m),
.clk(clk),
.clk90(clk90),
.rst(reset),
.phy_reset_n(),

.phy_rx_clk(phy_rx_clk),
.phy_rxd(phy_rxd),
.phy_rx_ctl(phy_rx_ctl),
.phy_tx_clk(phy_tx_clk),
.phy_txd(phy_txd),
.phy_tx_ctl(phy_tx_ctl)
);

assign phy_rx_clk = phy_tx_clk;
assign #8   phy_rxd[0] = phy_txd[0];
assign #9.8 phy_rxd[1] = phy_txd[1];
assign #9.9 phy_rxd[2] = phy_txd[2];
assign #6.1 phy_rxd[3] = phy_txd[3];
assign #6.2 phy_rx_ctl = phy_tx_ctl;


clock_gen 
#(.PERIOD(8)) 
clock_gen 
(
    .clk(clk)
);
clock_gen 
#(.PERIOD(5.0)) 
clock200_gen 
(
    .clk(clk_200m)
);
reset_gen reset_gen (
    .clk(clk),
    .reset(reset)
);


   
endmodule