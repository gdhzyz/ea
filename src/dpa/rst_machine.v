`timescale  1 ns / 10 ps
module rst_machine
        (
        CLK_generic,
        RST_stimulus,
        IRDY,

        DOMAIN_RST
        );

input           CLK_generic;
input           RST_stimulus;
input           IRDY;

output          DOMAIN_RST;

reg             DOMAIN_RST;
reg             COUNT;
reg     [1:0]   CURRENT_STATE, NEXT_STATE;

wire    [3:0]   COUNT_VALUE;

count_to_16 machine_counter(.clk(CLK_generic), .rst(RST_stimulus),
.count(COUNT), .counter_value(COUNT_VALUE));

always@(posedge CLK_generic or posedge RST_stimulus)
begin
 if(RST_stimulus == 1'b1)
  begin
   //Initial Values
   CURRENT_STATE = 2'b00;
  end
 else
  begin
   //Transition Values
   CURRENT_STATE = NEXT_STATE;
  end
end

always@(IRDY or COUNT_VALUE or CURRENT_STATE)
 begin
  case(CURRENT_STATE)
   2'b00: begin
    //While DCM is not locked, remain in this state
    DOMAIN_RST = 1'b0;
    COUNT = 1'b0;
    if(IRDY == 1'b1)
        NEXT_STATE = 2'b01;
    else
        NEXT_STATE = 2'b00;
   end

   2'b01: begin
    //Start of DOMAIN_RST and hold for 16 clock cycles.
    DOMAIN_RST = 1'b1;
    COUNT = 1'b1;
    if(IRDY == 1'b0)
        NEXT_STATE = 2'b00;
    else
    if(COUNT_VALUE != 4'hF)
        NEXT_STATE = 2'b01;
    else
        if(COUNT_VALUE == 4'hF)
        NEXT_STATE = 2'b10;
   end

   2'b10: begin
    DOMAIN_RST = 1'b0;
    COUNT = 1'b0;
    if(IRDY == 1'b0)
        NEXT_STATE = 2'b00;
    else
        NEXT_STATE = 2'b10;
   end
   default: begin
    DOMAIN_RST = 1'b0;
    COUNT = 1'b0;
    NEXT_STATE = 2'b00;
   end
  endcase
 end

endmodule

`timescale  1 ns / 10 ps
module count_to_16(clk, rst, count, counter_value);

//This module counts from 0 to 16

input clk, rst, count;
output [3:0] counter_value;

reg [3:0] counter_value_preserver/*synthesis syn_noprune = 1*/;

assign counter_value = (count) ? counter_value_preserver + 1 : 4'h0;

always@(posedge clk or posedge rst)
 if(rst == 1'b1)
   counter_value_preserver = 4'h0;
 else
   counter_value_preserver = counter_value;

endmodule 