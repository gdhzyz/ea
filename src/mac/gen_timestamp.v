
`resetall
`timescale 1ns / 1ps
`default_nettype none

module gen_timestamp 
#(
    parameter CYCLE_NUM_1US = 125
)
(
    input  wire                     clk,
    input  wire                     rst,

    output wire [23:0]              timestamp
);

localparam COUNTER_BITS = $clog2(CYCLE_NUM_1US);

reg [23:0] num_1us = 0;
reg [COUNTER_BITS-1:0] counter = 0;
wire inc = counter == CYCLE_NUM_1US-1;

always @(posedge clk) begin
    if (rst) begin
        counter <= 0;
    end else if (inc) begin
        counter <= 0;
    end else begin
        counter <= counter + 1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        num_1us <= 0;
    end else if (inc) begin
        num_1us <= num_1us + 1;
    end
end

assign timestamp = num_1us;

endmodule

`resetall
