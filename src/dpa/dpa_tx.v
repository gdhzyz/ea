// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

module dpa_tx (
    input  wire         clk, // 125mhz
    input  wire         clk90, // 125mhz, shifted 90 degree
    input  wire         rst,
    (* mark_debug = "true" *)input  wire         enable,

    output wire         phy_tx_clk,
    output wire [3:0]   phy_txd,
    output wire         phy_tx_ctl
);

localparam NUM_CHAN = 5;

// ================ txclk generator ================
oddr #(
    .TARGET("XILINX"),
    .IODDR_STYLE("IODDR"),
    .WIDTH(1)
)
clk_oddr_inst (
    .clk(clk90),
    .d1(1'b1),
    .d2(1'b0),
    .q(phy_tx_clk)
);

// ================ pattern generator ==============
(* mark_debug = "true" *)wire [NUM_CHAN-1:0] phy_tx1;
(* mark_debug = "true" *)wire [NUM_CHAN-1:0] phy_tx2;
wire [1:0] pattern;


dpa_pat_gen pat_gen (
    .clk(clk),
    .rst(rst),
    .data(pattern),
    .enable(enable)
);

assign phy_tx1 = {NUM_CHAN{pattern[1]}};
assign phy_tx2 = {NUM_CHAN{pattern[0]}};

// ================ data tx ==============
oddr #(
    .TARGET("XILINX"),
    .IODDR_STYLE("IODDR"),
    .WIDTH(5)
)
data_oddr_inst (
    .clk(clk),
    .d1(phy_tx1),
    .d2(phy_tx2),
    .q({phy_tx_ctl, phy_txd})
);

endmodule

`resetall
