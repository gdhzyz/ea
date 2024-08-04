// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

module dpa_pat_gen (
    input  wire         clk, // 125mhz
    input  wire         rst,

    output wire [1:0]   data,  // ddr
    input  wire         enable // output one data while enable is high.
);

parameter PATTERN = 20'b0000_0000_0011_1111_1111;

reg [19:0] data_reg = PATTERN;
always @(posedge clk) begin
    if (rst) begin
        data_reg <= PATTERN;
    end else if (enable) begin
        data_reg <= {data_reg[17:0], data_reg[19:18]};
    end
end

assign data = data_reg;
endmodule

`resetall
