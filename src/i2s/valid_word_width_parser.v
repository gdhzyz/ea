
// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none
`include "../head.vh"

/*
 * Parse tdm number from registers to real valid_word_with.
 */
module valid_word_with_parser
(
    input  wire         clk,

    /*
     * configuration
     */
    input  wire         valid_word_width,
    output wire [5:0]   valid_word_width_real
);

reg [5:0] valid_word_width_real_reg;
always @(posedge clk) begin
    case (valid_word_width)
        2'd1: valid_word_width_real_reg <= 6'd16;
        2'd2: valid_word_width_real_reg <= 6'd24;
        2'd3: valid_word_width_real_reg <= 6'd32;
        default: valid_word_width_real_reg <= 6'd0;
    endcase
end

assign valid_word_width_real = valid_word_width_real_reg;

endmodule

`resetall
