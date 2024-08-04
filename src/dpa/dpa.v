// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

module dpa (
    input  wire         clk_200m,
    input  wire         clk, // 125mhz
    input  wire         clk90, // 125mhz, shifted 90 degree
    input  wire         rst,
    (* mark_debug = "true" *)output reg          phy_reset_n, // phy reset, 100ms for YT8511

    input  wire         phy_rx_clk,
    input  wire [3:0]   phy_rxd,
    input  wire         phy_rx_ctl,
    output wire         phy_tx_clk,
    output wire [3:0]   phy_txd,
    output wire         phy_tx_ctl,

    output wire         deskew_done

);

wire enable = phy_reset_n;

// ================ phy reset ==============
parameter TIME_200MS = 125 * 1000 * 100 * 2;
//parameter TIME_200MS = 125 * 1000;
localparam TIME_200MS_BITS = $clog2(TIME_200MS);
reg [TIME_200MS_BITS - 1:0] phy_reset_counter = 0;
always @(posedge clk) begin
    if (rst) begin
        phy_reset_counter <= 'd0;
        phy_reset_n <= 1'b0;
    end else if (phy_reset_counter < TIME_200MS-1) begin
        phy_reset_counter <= phy_reset_counter + 'd1;
        phy_reset_n <= 1'b0;
    end else begin
       phy_reset_counter <= phy_reset_counter;
       phy_reset_n <= 1'b1;
    end
end

// ================ pattern generator ==============
reg tx_enable = 1'b0;
reg [4:0] counter=0;
always @(posedge clk) begin
    if (~phy_reset_n) begin
        counter <= 0;
    end else if (&counter != 1'b1) begin
        counter <= counter + 1;
    end
end

always @(posedge clk) begin
    if (~phy_reset_n) begin
        tx_enable <= 1'b0;
    end else if (&counter == 1'b1) begin
        tx_enable <= 1'b1;
    end
end

dpa_tx dpa_tx (
    .clk(clk),
    .clk90(clk90),
    .rst(~phy_reset_n),
    .enable(tx_enable),
    .phy_tx_clk(phy_tx_clk),
    .phy_txd(phy_txd),
    .phy_tx_ctl(phy_tx_ctl)
);

// ================ training module ==============
top_4ch_training_monitor top_4ch_training_monitor (
    .train_done(deskew_done),
    .idelayctrl_ready(),
    .iobclk(phy_rx_clk),
    .clk_200m(clk_200m),
    .data_in({phy_rxd, phy_rx_ctl}),
    .rst(~tx_enable),
    .train_en(1'b1),
    .inc_ext(1'b0),
    .ice_ext(1'b0)
);

endmodule

`resetall
