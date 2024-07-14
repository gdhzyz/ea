
`timescale 1ns/100ps
  
module decouple_tb ();

    // Width of AXI stream interfaces in bits
    parameter DATA_WIDTH = 32;
    // Propagate tkeep signal
    // If disabled, tkeep assumed to be 1'b1
    parameter KEEP_ENABLE = 1;
    // tkeep signal width (words per cycle)
    parameter KEEP_WIDTH = 4;
 
   
    wire clk;     
    wire reset;

    // inputs
    reg [DATA_WIDTH-1:0]  data;
    reg [KEEP_WIDTH-1:0]  keep;
    reg                   valid;
    reg                   last;
    reg                   user;
    wire                  ready;

    // outputs
    wire [DATA_WIDTH-1:0] odata;
    wire [KEEP_WIDTH-1:0] okeep;
    wire                  ovalid;
    wire                  olast;
    wire                  ouser;
    reg                   oready;
       
   
    decouple #(
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(KEEP_WIDTH)
    ) dut (
        .clk(clk),
        .rst(reset),
        .s_axis_tdata  (data),
        .s_axis_tkeep  (keep),
        .s_axis_tvalid (valid),
        .s_axis_tready (ready),
        .s_axis_tlast  (last),
        .s_axis_tuser  (user),
        .m_axis_tdata  (odata),
        .m_axis_tkeep  (okeep),
        .m_axis_tvalid (ovalid),
        .m_axis_tready (oready),
        .m_axis_tlast  (olast),
        .m_axis_tuser  (ouser)
    );
 
   


    clock_gen 
    #(.PERIOD(10)) 
    clock_gen 
    (
        .clk(clk)
    );

    reset_gen reset_gen (
        .clk(clk),
        .reset(reset)
    );
 
   
    `include "decouple_tb_case1.vh"
   
endmodule