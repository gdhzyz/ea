
// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none
`include "../head.vh"

/*
 * Parse tdm number from registers to real tdm number.
 */
module tdm_num_parser
(
    input  wire         clk,

    /*
     * configuration
     */
    input  wire [2:0]   tdm_num,
    output wire [4:0]   tdm_num_real
);

reg [4:0] tdm_num_real_reg;
always @(posedge clk) begin
    case (tdm_num)
        3'd1: tdm_num_real_reg <= 5'd2;
        3'd2: tdm_num_real_reg <= 5'd4;
        3'd3: tdm_num_real_reg <= 5'd8;
        3'd4: tdm_num_real_reg <= 5'd16;
        default: tdm_num_real_reg <= 5'd2;
    endcase
end

assign tdm_num_real = tdm_num_real_reg;

endmodule

`resetall
