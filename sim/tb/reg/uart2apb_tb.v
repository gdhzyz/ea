
`timescale 1ns/100ps
  
module uart2apb_tb ();
 
   
    wire clk;     
    wire reset;
    
    /*
     * UART rx
     */
    reg          s_axis_tvalid;
    reg  [7:0]   s_axis_tdata;
    reg          s_axis_tuser;
    reg          s_axis_tlast;
    wire         s_axis_tready;

    /*
     * UART tx
     */
    wire         m_axis_tvalid;
    wire [7:0]   m_axis_tdata;
    wire         m_axis_tuser;
    wire         m_axis_tlast;
    reg          m_axis_tready;

    /*
     * APB
     */
    wire         psel;
    wire         penable;
    wire [15:0]  paddr;
    wire [2:0]   pprot;
    wire         pwrite;
    wire [3:0]   pstrb;
    wire [31:0]  pwdata;
    reg          pready;
    reg  [31:0]  prdata;
    reg  [31:0]  pslverr;

    /*
     * Configuration
     */
    reg  [3:0]   local_fpga_index;
    wire         busy;
    wire         error;
       
   
    uart2apb uart2apb (
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    .clk(clk),
    .rst(reset),

    /*
     * UART rx
     */
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tuser(s_axis_tuser),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tready(s_axis_tready),

    /*
     * UART tx
     */
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tuser(m_axis_tuser),
    .m_axis_tlast(m_axis_tlast),
    .m_axis_tready(m_axis_tready),

    /*
     * APB
     */
    .psel(psel),
    .penable(penable),
    .paddr(paddr),
    .pprot(pprot),
    .pwrite(pwrite),
    .pstrb(pstrb),
    .pwdata(pwdata),
    .pready(pready),
    .prdata(prdata),
    .pslverr(pslverr),

    /*
     * Configuration
     */
    .local_fpga_index(local_fpga_index),
    .busy(busy),
    .error(error)
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
     
    `include "uart2apb_tb_case1.vh"
    //`include "uart2apb_tb_case2.vh"
   
endmodule