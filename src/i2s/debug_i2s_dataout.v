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
    output wire             datao,
    input  wire             mclki,
    input  wire             srst,
    input  wire [4:0]       tdm_num
);

reg lrck_d=1'b1;
always @(negedge bclk) begin
    if (srst) begin
        lrck_d <= 1'b1;
    end else begin
        lrck_d <= lrck;
    end
end

reg start=1'b0;
always @(negedge bclk) begin
    if (srst) begin
        start <= 1'b0;
    end
    else if (lrck_d == 1'b0) begin
        start <= 1'b1;
    end
end

wire shift = start;

wire channel_start = lrck == 1'b0 && lrck_d == 1'b1;

reg [4:0] tdm_num_count=0;
wire tdm_wrap_back = tdm_num_count + 1 == tdm_num;
always @(negedge bclk) begin
    if (srst) begin
        tdm_num_count <= 0;
    end
    else if (channel_start) begin
        if (tdm_wrap_back) begin
            tdm_num_count <= 0;
        end else begin
            tdm_num_count <= tdm_num_count + 1;
        end
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

reg [31:0] data_reg;
always @(negedge bclk) begin
    if (channel_start) begin
        data_reg <= data_arr[32*15 +: 32];
    end else if (shift) begin
        data_reg <= {data_reg[30:0], data_reg[31]};
    end
end

always @(negedge bclk) begin
    if (channel_start && tdm_wrap_back) begin
        data_arr <= {data_arr[32*15-1:0], data_arr[32*16-1:32*15]};
    end
end

assign datao = data_reg[31];

ila_debug_i2s_in ila_debug_i2s_in(
    .clk(mclki),
    .probe0(start),
    .probe1(data_reg),
    .probe2(lrck),
    .probe3(tdm_num_count)
);

endmodule

`resetall
