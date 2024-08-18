

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * clock divider
 */
module freq_divider # (
    parameter INIT_VALUE = 0,
    parameter MAX_FACTOR = 16, // out_freqency = in_freqency / factor
    localparam WIDTH = $clog2(MAX_FACTOR+1)  // need to represent MAX_FACTOR
)(
    /*
     * Synchronous reset
     */
    input  wire             rst,

    /*
     * input clock
     */
    input  wire             clk,
    input  wire             enable,

    /*
     * Generated clock
     */
    output wire             oclk,

    /*
     * configuration, do not need to have been synchronized to bclk.
     */
    input  wire [WIDTH-1:0] factor  // must be greater than or equal to 4, and must be an even number
);

wire [WIDTH-2:0] factor_half = factor >> 1;

reg [WIDTH-1:0] count={WIDTH{1'b0}};
wire wrap_back = count == factor-1;
wire toggle = count == factor_half-1 || wrap_back;
//wire toggle_neg = wrap_back;
always @(posedge clk) begin
    if (rst) begin
        count <= {WIDTH{1'b0}};
    end else if (enable) begin
        if (wrap_back) begin
            count <= {WIDTH{1'b0}};
        end else begin
            count <= count + 1;
        end
    end
end

reg oclk_reg=0;
always @(posedge clk) begin
    if (rst) begin
        oclk_reg <= INIT_VALUE;
    end else if (toggle) begin
        oclk_reg <= ~oclk_reg;
    end
end

assign oclk = oclk_reg;

endmodule

`resetall
