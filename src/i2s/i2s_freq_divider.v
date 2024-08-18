

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * i2s clocks divider
 */
module i2s_freq_divider (
    /*
     * Synchronous reset
     */
    input  wire             rst,

    /*
     * input clock, 24.576MHz * 4
     */
    input  wire             mclki,

    /*
     * Generated clock
     */
    input  wire             enable,
    output wire             bclk,
    output wire             lrck,

    /*
     * configuration, do not need to have been synchronized to bclk.
     */
    input  wire [4:0]       bclk_factor,
    input  wire [5:0]       word_width
);


// ==================== bclk =======================
freq_divider #(
    .MAX_FACTOR(16*4)
) bclk_freq_divider (
    .rst(rst),
    .clk(mclki),
    .enable(enable),
    .oclk(bclk),
    .factor({2'b00, bclk_factor} << 2)
);

// ==================== lrck =======================
reg [9:0] lrck_factor=0; // max 16 * 32 * 2
always @(posedge mclki) begin
    if (word_width == 16) begin
        lrck_factor <= {5'b00, bclk_factor} << 5;  // toggle every 16 bclk cycles.
    end else if (word_width == 32) begin
        lrck_factor <= {5'b0, bclk_factor} << 6;
    end
end

freq_divider #(
    .INIT_VALUE(1),
    .MAX_FACTOR(16*4*32) // tdm * 4 * word_width
) lrck_freq_divider (
    .rst(rst),
    .clk(mclki),
    .enable(enable),
    .oclk(lrck),
    .factor({2'b00, lrck_factor} << 2)
);
    
endmodule

`resetall
