
// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none
`include "../head.vh"

/*
 * Parse tdm number from registers to real word_with.
 */
module word_with_parser
(
    input  wire         clk,

    /*
     * configuration
     */
    input  wire         word_width,
    output wire [5:0]   word_width_real
);

reg [5:0] word_width_real_reg;
always @(posedge clk) begin
    case (word_width)
        1'd0: word_width_real_reg <= 6'd16;
        1'd1: word_width_real_reg <= 6'd32;
    endcase
end

assign word_width_real = word_width_real_reg;

endmodule

`resetall
