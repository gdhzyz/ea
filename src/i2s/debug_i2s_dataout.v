// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * test dataout pin.
 */
module debug_i2s_dataout 
(
    input  wire             bclk,
    input  wire             lrck,
    output wire             datao
);

reg lrck_d=1'b1;
always @(negedge bclk) begin
    lrck_d <= lrck;
end

reg start=1'b0;
always @(negedge bclk) begin
     if (lrck ^ lrck_d) begin
         start <= 1'b1;
     end
end

reg [32*16-1 : 0] data_arr = {
    32'h00000000,
    32'h30FBC550,
    32'h5A8279A0,
    32'h7641AF40,
    32'h7FFFFFFF,
    32'h7641AF40,
    32'h5A8279A0,
    32'h30FBC550,
    32'h00000000,
    32'hCF043AB0,
    32'hA57D8660,
    32'h89BE50C0,
    32'h80000000,
    32'h89BE50C0,
    32'hA57D8660,
    32'hCF043AB0
};

always @(negedge bclk) begin
    if (start) begin
        data_arr <= {data_arr[32*16-2:0], data_arr[32*16-1]};
    end
end

assign datao = data_arr[32*16-1];

endmodule

`resetall
