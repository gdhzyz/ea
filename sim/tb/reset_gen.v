
module reset_gen 
#(
    parameter RESET_CYCLES = 100
)
(
    input   wire clk,
    output  wire reset
);

reg reset_reg = 0;
integer i;

initial begin
    reset_reg <= 1;
    @(posedge clk) reset_reg = 1;
    i = 0;
    for (i = 0; i < RESET_CYCLES; i = i + 1) begin
        @(posedge clk);
    end
    reset_reg <= 0;
end

assign reset = reset_reg;

endmodule