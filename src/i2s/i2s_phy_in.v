
// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none
`include "../head.vh"

/*
 * I2S from ADC
 */
module i2s_phy_in 
(
    /*
     * Clock: 24.576MHz * 8 = 196.608
     * Synchronous reset
     */
    input  wire         clk,
    input  wire         rst,

    /*
     * I2S IOs
     */
    input  wire         bclk,
    input  wire         lrck,
    input  wire         datai,

    /*
     * I2S parallel output.
     */
    output wire         ovalid,
    output wire [31:0]  odata, // lower bits are always valid.

    /*
     * configuration, do not need to have been synchronized to bclk.
     */
    input  wire [4:0]   i_tdm_num,
    input  wire         i_is_master,
    input  wire [5:0]   i_word_width,
    input  wire         i_lrck_polarity,  // edge of starting flag, 1'b0: posedge, 1'b1: negedge.
    input  wire         i_lrck_alignment, // MSB alignment with lrck, 1'b0: aligned, 1'b1: one clock delay
    output wire [31:0]  o_frame_num
);

// ====================== synchronization ========================
// -------- reset --------
wire rst_sync;
sync_reset sync_reset (
    .clk(bclk),
    .rst(rst),
    .out(rst_sync)
);

// -------- tdm_num --------
wire [4:0] tdm_num;
sync_signal #(
    .WIDTH(5)
) tdm_num_synchronizer (
    .clk(bclk),
    .in(i_tdm_num),
    .out(tdm_num)
);

// -------- is_master --------
wire is_master;
sync_signal #(
    .WIDTH(1)
) is_master_synchronizer (
    .clk(bclk),
    .in(i_is_master),
    .out(is_master)
);

// -------- word_width --------
wire word_width;
sync_signal #(
    .WIDTH(6)
) word_width_synchronizer (
    .clk(bclk),
    .in(i_word_width),
    .out(word_width)
);

// -------- lrck_polarity --------
wire lrck_polarity;
sync_signal #(
    .WIDTH(1)
) lrck_polarity_synchronizer (
    .clk(bclk),
    .in(i_lrck_polarity),
    .out(lrck_polarity)
);

// -------- lrck_alignment --------
wire lrck_alignment;
sync_signal #(
    .WIDTH(1)
) lrck_alignment_synchronizer (
    .clk(bclk),
    .in(i_lrck_alignment),
    .out(lrck_alignment)
);
// ====================== end synchronization ========================


reg [2:0] lrck_d;
always @(posedge bclk) begin
    if (rst_sync) begin
        lrck_d <= 0;
    end else begin
        lrck_d <= {lrck_d[1:0], lrck};
    end
end

// use delay[1] data.
// bclk     ___|--|__|--|__|--|__|--|__|--|__|--|__|--|__|--|__|--|__|--|__|--|__|--|__|--|__
// lrck     ___|--------------------------------------------------
// lrckd0   ______|-------------------------------------------
// lrckd1   _________|------------------------------------
// lrck_pos _________|--|_______
// datai    ___|MSB
// datai_d0 ______|MSB
// datai_d1 _________|MSB
// datai_d2 ____________|MSB
// in_frame_reg ________|--------
wire [1:0] lrck_pos_array = {lrck_d[2:1] == 2'b01, lrck_d[1:0] == 2'b01};
wire [1:0] lrck_neg_array = {lrck_d[2:1] == 2'b10, lrck_d[1:0] == 2'b10};
wire is_lrck_aligned = lrck_alignment == 1'b0;
wire lrck_pos = is_lrck_aligned ? lrck_pos_array[0] : lrck_pos_array[1];
wire lrck_neg = is_lrck_aligned ? lrck_neg_array[0] : lrck_neg_array[1];
wire start_word = lrck_polarity ? lrck_pos : (lrck_pos || lrck_neg);

reg [3:0] datai_d;
always @(posedge bclk) begin
    datai_d <= {datai_d[2:0], datai};
end
wire data = is_lrck_aligned ? datai_d[2] : datai_d[3];

reg in_frame = 1'b0;
reg [3:0] tdm_counter=0;
reg [5:0] bit_counter=0;
wire end_word = bit_counter == word_width-1;
wire end_frame = tdm_counter == tdm_num-1 && end_word;
always @(posedge bclk) begin
    if (rst_sync) begin
        in_frame <= 1'b0;
    end else if (start_word) begin
        in_frame <= 1'b1;
    end else if (end_frame) begin
        in_frame <= 1'b0;
    end
end

always @(posedge bclk) begin
    if (rst_sync) begin
        bit_counter <= 0;
    end else if (start_word) begin
        bit_counter <= 0;
    end else begin
        bit_counter <= bit_counter + 1;
    end
end

always @(posedge bclk) begin
    if (rst_sync) begin
        tdm_counter <= 0;
    end else if (end_word) begin
        if (end_frame) begin
            tdm_counter <= 0;
        end else begin
            tdm_counter <= tdm_counter + 1;
        end
    end
end

reg [31:0] data_reg;
always @(posedge bclk) begin
    data_reg <= {data_reg[30:0], data};
end

endmodule

`resetall
