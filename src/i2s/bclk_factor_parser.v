
// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none
`include "../head.vh"

/*
 * Parse tdm number from registers to real bclk_factor.
 */
module bclk_factor_parser
(
    input  wire         clk,

    /*
     * configuration
     */
    input  wire [2:0]   bclk_factor,
    output wire [4:0]   bclk_factor_real
);

reg [5:0] bclk_factor_real_reg;
always @(posedge clk) begin
    case (bclk_factor)
        3'd1: bclk_factor_real_reg <= 5'd1;
        3'd2: bclk_factor_real_reg <= 5'd2;
        3'd3: bclk_factor_real_reg <= 5'd4;
        3'd4: bclk_factor_real_reg <= 5'd8;
        3'd5: bclk_factor_real_reg <= 5'd16;
        default: bclk_factor_real_reg <= 5'd1;
    endcase
end

assign bclk_factor_real = bclk_factor_real_reg;

endmodule

`resetall
