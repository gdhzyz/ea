// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * I2S from ADC
 */
module i2s_phy_in 
(
    /*
     * Asynchronous reset
     */
    input  wire         rst,

    /*
     * I2S IOs
     */
    input  wire         bclk,
    input  wire         lrck,
    input  wire         datai,

    /*
     * I2S parallel output, synchronized with bclk.
     */
    output wire         m_axis_tvalid,
    output wire [31:0]  m_axis_tdata, // lower bits are always valid.
    output wire         m_axis_tlast,

    /*
     * configuration, do not need to have been synchronized to system clock.
     */
    input  wire [4:0]   i_tdm_num,
    input  wire [5:0]   i_word_width,
    input  wire         i_lrck_polarity,  // edge of starting flag, 1'b0: posedge, 1'b1: negedge.
    input  wire         i_lrck_alignment, // MSB alignment with lrck, 1'b0: aligned, 1'b1: one clock delay
    output wire [31:0]  o_frame_num,

    // synchronized with bclk
    input  wire         i_enable
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
//sync_signal #(
//    .WIDTH(5)
//) tdm_num_synchronizer (
//    .clk(bclk),
//    .in(i_tdm_num),
//    .out(tdm_num)
//);
assign tdm_num = i_tdm_num;

// -------- word_width --------
wire [5:0] word_width;
//sync_signal #(
//    .WIDTH(6)
//) word_width_synchronizer (
//    .clk(bclk),
//    .in(i_word_width),
//    .out(word_width)
//);
assign word_width = i_word_width;

// -------- lrck_polarity --------
wire lrck_polarity;
//sync_signal #(
//    .WIDTH(1)
//) lrck_polarity_synchronizer (
//    .clk(bclk),
//    .in(i_lrck_polarity),
//    .out(lrck_polarity)
//);
assign lrck_polarity = i_lrck_polarity;

// -------- lrck_alignment --------
wire lrck_alignment;
//sync_signal #(
//    .WIDTH(1)
//) lrck_alignment_synchronizer (
//    .clk(bclk),
//    .in(i_lrck_alignment),
//    .out(lrck_alignment)
//);
assign lrck_alignment = i_lrck_alignment;
// ====================== end synchronization ========================


reg [2:0] lrck_d;
always @(posedge bclk) begin
    if (rst_sync) begin
        lrck_d <= 3'b111;
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
wire start_word = (lrck_polarity ? lrck_neg : (lrck_pos || lrck_neg)) && i_enable;

reg [3:0] datai_d;
always @(posedge bclk) begin
    datai_d <= {datai_d[2:0], datai};
end
wire data = datai_d[1];

reg in_frame = 1'b0;
reg [3:0] tdm_counter=0;
reg [5:0] bit_counter=0;
wire word_last = bit_counter == (6'd32 - word_width);
wire frame_last = tdm_counter == tdm_num-1 && word_last;
always @(posedge bclk) begin
    if (rst_sync) begin
        in_frame <= 1'b0;
    end else if (start_word) begin
        in_frame <= 1'b1;
    end else if (frame_last) begin
        in_frame <= 1'b0;
    end
end

always @(posedge bclk) begin
    if (rst_sync) begin
        bit_counter <= 6'd31;
    end else if (start_word) begin
        bit_counter <= 6'd31;
    end else if (in_frame && bit_counter > 0) begin
        bit_counter <= bit_counter - 1;
    end else begin
        bit_counter <= 6'd31;
    end
end

always @(posedge bclk) begin
    if (rst_sync) begin
        tdm_counter <= 0;
    end else if (word_last) begin
        if (frame_last) begin
            tdm_counter <= 0;
        end else begin
            tdm_counter <= tdm_counter + 1;
        end
    end
end

reg [31:0] data_reg;
integer i;
always @(posedge bclk) begin
    for (i = 0; i < 32; i = i + 1) begin
        if (i == bit_counter) begin
            data_reg[i] <= data;
        end
    end
end

reg ovalid = 0;
always @(posedge bclk) begin
    if (rst_sync) begin
        ovalid <= 1'b0;
    end else if (word_last) begin
        ovalid <= 1'b1;
    end else begin
        ovalid <= 1'b0;
    end
end

reg olast=0;
always @(posedge bclk) begin
    if (rst_sync) begin
        olast <= 1'b0;
    end else begin
        olast <= frame_last;
    end
end

assign m_axis_tvalid = ovalid;
assign m_axis_tdata = data_reg;
assign m_axis_tlast = olast;

endmodule

`resetall
