// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * I2S to ADC
 */
module i2s_phy_out
(
    /* Clock: 24.576MHz * 8 = 
     * Asynchronous reset
     */
    input  wire         mclk,
    input  wire         rst,

    /*
     * I2S IOs
     */
    input  wire         bclk,
    input  wire         bclk_180,
    input  wire         lrck,
    output wire         datao,

    /*
     * I2S parallel output, synchronized with bclk.
     */
    input  wire         m_axis_tvalid,
    input  wire [7:0]   m_axis_tdata, // lower bits are always valid.
    input  wire         m_axis_tlast,
    output wire         m_axis_tready,

    /*
     * configuration, do not need to have been synchronized to system clock.
     */
    input  wire         i_enable,
    input  wire [4:0]   i_tdm_num,
    input  wire [5:0]   i_valid_word_width,
    input  wire         i_lrck_polarity,  // edge of starting flag, 1'b0: posedge, 1'b1: negedge.
    input  wire         i_lrck_alignment, // MSB alignment with lrck, 1'b0: aligned, 1'b1: one clock delay
    output wire [31:0]  o_frame_num,
    output wire         o_error
);

// ====================== synchronization ========================
// -------- reset --------
wire rst_sync;
sync_reset sync_reset (
    .clk(bclk),
    .rst(rst),
    .out(rst_sync)
);

// -------- enable --------
wire enable;
sync_signal enable_synchronizer (
    .clk(bclk),
    .in(i_enable),
    .out(enable)
);

// -------- tdm_num --------
wire [4:0] tdm_num;
assign tdm_num = i_tdm_num;

// -------- valid_word_width --------
wire [5:0] valid_word_width;
assign valid_word_width = i_valid_word_width;

// -------- lrck_polarity --------
wire lrck_polarity;
assign lrck_polarity = i_lrck_polarity;

// -------- lrck_alignment --------
wire lrck_alignment;
assign lrck_alignment = i_lrck_alignment;

// ====================== end synchronization ========================



// bclk     ___|--|__|--|__|--|__|--|__|--|__|--|__|--|__|--|__|--|__|--|__|--|__|--|__|--|__
// lrck     ______|--------------------------------------------------
// lrckd    _________|-------------------------------------------
// lrck_pos _________|-----|_________
// start    _________|-----|_________
// in_frame _________|-----------------------|_________
// bcnt_180 31          | 30  |29   | ... |0    |
// frame_last   __________________________|-----|______
// dout_180 ------------|______

reg [1:0] lrck_d;
always @(posedge bclk) begin
    if (rst_sync) begin
        lrck_d <= 2'b11;
    end else begin
        lrck_d <= {lrck_d[0], lrck};
    end
end

wire is_lrck_aligned = lrck_alignment == 1'b0;
wire first_bit_pos = is_lrck_aligned ? {lrck_d[0], lrck} == 2'b01 : lrck_d[1:0] == 2'b01;
wire first_bit_neg = is_lrck_aligned ? {lrck_d[0], lrck} == 2'b10 : lrck_d[1:0] == 2'b10;
wire start_frame = (lrck_polarity ? first_bit_neg : (first_bit_pos || first_bit_neg)) && enable;
wire frame_last;

reg in_frame = 1'b0;
always @(posedge bclk) begin
    if (rst_sync) begin
        in_frame <= 1'b0;
    end else if (start_frame) begin
        in_frame <= 1'b1;
    end else if (frame_last) begin
        in_frame <= 1'b0;
    end
end

wire ifire = m_axis_tvalid && m_axis_tready;

wire start_word = first_bit_neg || first_bit_pos;

reg [5:0] bit_counter_180=0;
always @(posedge bclk) begin
    if (rst_sync) begin
        bit_counter_180 <= 6'd31;
    end else if (start_word && (start_frame || in_frame)) begin
        bit_counter_180 <= 6'd31;
    end else if (in_frame && bit_counter_180 > 0) begin
        bit_counter_180 <= bit_counter_180 - 1;
    end else begin
        bit_counter_180 <= 6'd31;
    end
end

reg [3:0] tdm_counter=0;
wire word_last_180 = bit_counter_180 == (6'd32 - word_width);
wire is_valid = bit_counter_180 >= (6'd32 - valid_word_width);
wire slice_last = bit_counter_180[2:0] == 3'd0;
assign frame_last = tdm_counter == tdm_num-1 && word_last_180;

always @(posedge bclk) begin
    if (rst_sync) begin
        tdm_counter <= 0;
    end else if (word_last_180) begin
        if (frame_last) begin
            tdm_counter <= 0;
        end else begin
            tdm_counter <= tdm_counter + 1;
        end
    end
end

wire last_word_bit = bit_counter_180[2:0] == 3'd0 && in_frame;

reg empty=1'b1;
always @(posedge bclk) begin
    if (rst_sync) begin
        empty <= 1'b1;
    end else if (ifire) begin
        empty <= 1'b0;
    end else if (last_word_bit) begin
        empty <= 1'b1;
    end
end

reg [7:0] data_reg;
always @(posedge bclk_180) begin
    if (ifire) begin
        data_reg <= m_axis_tdata;
    end else begin
        data_reg <= {data_reg[6:0], 1'b0};
    end
end
assign datao = data_reg[7];
assign m_axis_tready = empty || last_word_bit;

endmodule

`resetall
