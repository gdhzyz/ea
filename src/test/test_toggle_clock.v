module test_toggle_clock (
    /*
     * Clock: 50MHz
     * Reset: Push button, active high
     */
    input  wire         clk_50mhz,
    input  wire         clk_sel,

    inout  wire         mdio_c,
    input  wire         mdio_t,
    input  wire         mdio_d,
    output wire         mdio_o
);


wire clk;
reg toggle_clk = 0;

//wire mdio_c_ibuf;
//IBUF #(
//   .IBUF_LOW_PWR("TRUE"),  // Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
//   .IOSTANDARD("DEFAULT")  // Specify the input I/O standard
//) IBUF_inst (
//   .O(mdio_c_ibuf),     // Buffer output
//   .I(mdio_c)      // Buffer input (connect directly to top-level port)
//);
//
//
//wire mdio_c_bufg;
//BUFG BUFG_inst (
//   .O(mdio_c_bufg), // 1-bit output: Clock output
//   .I(mdio_c_ibuf)  // 1-bit input: Clock input
//);
//
//BUFGMUX_CTRL BUFGMUX_CTRL_inst (
//   .O(clk),   // 1-bit output: Clock output
//   .I0(toggle_clk), // 1-bit input: Clock input (S=0)
//   .I1(mdio_c_bufg), // 1-bit input: Clock input (S=1)
//   .S(clk_sel)    // 1-bit input: Clock select
//);

wire clk_50mhz_ibufg;
IBUFG
clk_50mhz_ibufg_inst(
    .I(clk_50mhz),
    .O(clk_50mhz_ibufg)
);

assign clk = mdio_c;
always @(posedge clk_50mhz_ibufg) begin
    toggle_clk <= ~toggle_clk;
end
assign mdio_c = mdio_t ? toggle_clk : 1'bz;

reg data = 0;
always @(posedge clk) begin
    data <= mdio_d;
end

assign mdio_o = data;

endmodule
