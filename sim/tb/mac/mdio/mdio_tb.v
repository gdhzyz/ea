
`timescale 1ns/100ps
  
module mdio_tb ();
 
wire clk;     
wire reset;

reg clk_2_5m=1;




reg          mdio_valid;
reg          mdio_write;
wire         mdio_ready;
reg  [4:0]   mdio_addr;
reg  [15:0]  mdio_wdata;
wire [15:0]  mdio_rdata;
wire         mdio_phy_i;
wire         mdio_phy_o;
wire         mdio_phy_t;
wire         mdio_phy_c;
mdio_if dut (
    .Clk(clk),
    .Rst(reset),
    .MDIO_Clk(clk_2_5m),
    .MDIO_en(mdio_valid),
    .MDIO_OP(~mdio_write),
    .MDIO_Req(mdio_valid),
    .MDIO_PHY_AD(5'b00100),
    .MDIO_REG_AD(mdio_addr),
    .MDIO_WR_DATA(mdio_wdata),
    .MDIO_RD_DATA(mdio_rdata),
    .MDIO_done(mdio_ready),
    .PHY_MDIO_I(mdio_phy_i),
    .PHY_MDIO_O(mdio_phy_o),
    .PHY_MDIO_T(mdio_phy_t),
    .PHY_MDC(mdio_phy_c)
);

// divide 125MHz into 2.5MHz.
localparam F125MHz = 125 * 1000 * 1000;
localparam F2_5MHz = 25 * 1000 * 1000 / 10;
localparam FRATIO_HALF = F125MHz / F2_5MHz / 2;
localparam FRATIO_WIDTH = $clog2(FRATIO_HALF);
reg [FRATIO_WIDTH-1:0] fcounter=0;
always @(posedge clk) begin
    if (reset) begin
        fcounter <= 0;
    end else if (fcounter == FRATIO_HALF-1) begin
        fcounter <= 0;
    end else begin
        fcounter <= fcounter + 1;
    end
end

always @(posedge clk) begin
    if (reset) begin
        clk_2_5m <= 1;
    end else if (fcounter == FRATIO_HALF-1) begin
        clk_2_5m <= ~clk_2_5m;
    end
end

wire mdio_d;
assign mdio_d = mdio_phy_t ? 1'bz : mdio_phy_o;
assign mdio_phy_i = mdio_d;

phy_mdio_port phy_mdio_port (
    .mdio(mdio_d),
    .mdc(mdio_phy_c)
);

clock_gen 
#(.PERIOD(10)) 
clock_gen 
(
    .clk(clk)
);
reset_gen reset_gen (
    .clk(clk),
    .reset(reset)
);

`include "mdio_tb_case1.vh"

   
endmodule