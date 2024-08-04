`timescale 1ns/1ps
module clock_gen #
(
    parameter PERIOD = 10.0  // in nanoseconds
)(
    output reg clk
);

    initial begin
        clk <= 0;
        forever #(PERIOD/2) clk = ~clk; // 每5个时间单位翻转一次信号
    end

endmodule