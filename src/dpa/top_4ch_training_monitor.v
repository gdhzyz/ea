`timescale 1ns/1ps

module top_4ch_training_monitor (
     data_out,
     train_done,
     iobclk,
     clk_200m,
     clkdiv, // TODO
     data_in,
     rst,
     train_en,
     inc_ext,
     ice_ext
    );

// Parameter that determines the number of channels instantiated.
parameter num_chan = 5;

output [num_chan*4-1:0] data_out;
output train_done;
input  iobclk;
input  clk_200m;
input  clkdiv;
input  [num_chan-1:0] data_in;
input  rst;
input  train_en;
input  inc_ext;
input  ice_ext;

wire [num_chan*4-1:0] data_out;
wire [num_chan-1:0] window_in;
reg [num_chan-1:0] chan_sel;
reg [num_chan-1:0] chan_sel1;
wire [num_chan-1:0] dataout_sel;
reg [num_chan-1:0] dataout_sel_int;
wire deskew_done;
wire bitslip_done;
wire monitor_done;
wire bitslip_error;
reg  train_done;
wire [num_chan-1:0] dlyce;
wire [num_chan-1:0] dlyinc;
wire [num_chan-1:0] dlyce_to_data_iserdes;
wire [num_chan-1:0] dlyinc_to_data_iserdes;
wire [num_chan-1:0] dlyce_iserdes_window;
wire [num_chan-1:0] dlyinc_iserdes_window;
wire [num_chan-1:0] dlyce_to_monitor_iserdes;
wire [num_chan-1:0] dlyinc_to_monitor_iserdes;
wire dlyce_training;
wire dlyinc_training;
reg dlyce_training_R1;
reg dlyinc_training_R1;
reg dlyce_monitor_R1;
reg dlyinc_monitor_R1;
reg dlyce_window_R1;
reg dlyinc_window_R1;
wire dlyce_window;
wire dlyinc_window;
reg dlyce_iserdes_window1;
reg dlyinc_iserdes_window1;
reg dlyce1;
reg dlyinc1;
wire [num_chan-1:0] bitslip;
wire bitslip_training;
wire iobclk;
wire iobclk_ibuf;
wire clkdiv;
wire refclk;
wire refclk_ibufg;
wire [num_chan-1:0] q1;
wire [num_chan-1:0] q2;
wire [num_chan-1:0] q3;
wire [num_chan-1:0] q4;
wire [num_chan-1:0] w1;
wire [num_chan-1:0] w2;
wire [num_chan-1:0] w3;
wire [num_chan-1:0] w4;
wire [3:0] datain;
wire [3:0] datain_monitor;
wire [3:0] dataout[num_chan-1:0];
reg [3:0] dataout_R1[num_chan-1:0];
wire [3:0] dataout_int[num_chan-1:0];
wire [2:0] edgei_training;
reg [7:0] counter;
reg cnt_rst;
reg [3:0] op_sel;

wire bufio_clk;
BUFIO RX_CLK_BUFIO(.O(bufio_clk), .I(iobclk));
BUFR RX_CLK_BUFR(.O(clkdiv), .CE(1'b1), .CLR(1'b0), .I(bufio_clk));
//synopsys translate_off
defparam RX_CLK_BUFR.BUFR_DIVIDE = "4";
//synopsys translate_on

wire idelayctrl_ready;
wire domain_reset;
rst_machine RST_CTRL1   //PRODUCES RST FOR RX LOGIC (must be synchronous to TX clock, though)
 (
 .CLK_generic(clkdiv),
 .RST_stimulus(rst),
 .IRDY(idelayctrl_ready),
 .DOMAIN_RST(domain_reset)
 ); 

IDELAYCTRL RX_IDELAYCTRL(.RDY(idelayctrl_ready), .REFCLK(clk_200m), .RST(rst));

// Instantiate the IDELAY
wire [num_chan-1:0] delayed_data_in;
wire [4:0] delayed_count_value[num_chan-1:0];
// synthesis translate_off
generate
genvar i;
for (i=0; i<=num_chan-1; i=i+1)
begin :  data_idelay_defparam

    IDELAYE2 data_idelay (
        .C(clkdiv),
        .REGRST(domain_reset),
        .LD(1'b0), // update when in product.
        .CE(dlyce_to_data_iserdes[i]),
        .INC(dlyinc_to_data_iserdes[i]),
        .CINVCTRL(1'b0),
        .CNTVALUEIN(4'd0),
        .IDATAIN(data_in[i]),
        .LDPIPEEN(1'b0),
        .DATAIN(),
        .DATAOUT(delayed_data_in[i]),
        .CNTVALUEOUT(delayed_count_value[i])
    );
    
    defparam data_idelay[i].IDELAY_TYPE = "VARIABLE";
    defparam data_idelay[i].DELAY_SRC = "IDATAIN";
    defparam data_idelay[i].IDELAY_VALUE = 0;
    defparam data_idelay[i].HIGH_PERFORMANCE_MODE = "TRUE";
    defparam data_idelay[i].SIGNAL_PATTERN = "DATA";
    defparam data_idelay[i].REFCLK_FREQENCY = 200; // IDELAYCTRL clock input frequency in MHz
    defparam data_idelay[i].CINVCTRL_SEL = "FALSE";
    defparam data_idelay[i].PIPE_SEL = "FALSE";
end
endgenerate
// synthesis translate_on

ISERDESE2 data_chan_master_[num_chan-1:0] (
    .O(),  // OK
    .Q1(q1[num_chan-1:0]), // OK
    .Q2(q2[num_chan-1:0]),  // OK
    .Q3(q3[num_chan-1:0]),  // OK
    .Q4(q4[num_chan-1:0]),  // OK
    .Q5(), // OK
    .Q6(), // OK
    .Q7(), // OK
    .Q8(), // OK
    .BITSLIP(bitslip[num_chan-1:0]), // OK
    .CE1(1'b1),  // OK
    .CE2(1'b0), // OK
    .CLK(bufio_clk),  // OK
    .CLKB(~bufio_clk), // OK
    .CLKDIV(clkdiv), // OK         
    .D(),  // OK
    .DDLY(delayed_data_in[num_chan-1:0]),  // OK
    .OCLK(1'b0),  // OK
    .RST(~domain_reset), // OK, TODO, should be synchronoused with clkdiv
    .OFB() // OK
);
// synthesis translate_off
generate
genvar i;
for (i=0; i<=num_chan-1; i=i+1)
begin :  data_chan_master_defparam
defparam data_chan_master_[i].DATA_RATE = "DDR";  // OK
defparam data_chan_master_[i].DATA_WIDTH = 4;     // OK
defparam data_chan_master_[i].INIT_Q1 = 1'b0;  // OK
defparam data_chan_master_[i].INIT_Q2 = 1'b0;  // OK
defparam data_chan_master_[i].INIT_Q3 = 1'b0;  // OK
defparam data_chan_master_[i].INIT_Q4 = 1'b0;  // OK
defparam data_chan_master_[i].INTERFACE_TYPE = "NETWORKING"; // OK
defparam data_chan_master_[i].NUM_CE = 1;  // OK
defparam data_chan_master_[i].SERDES_MODE = "MASTER"; // OK
defparam data_chan_master_[i].SRVAL_Q1 = 1'b0; // OK
defparam data_chan_master_[i].SRVAL_Q2 = 1'b0;  // OK
defparam data_chan_master_[i].SRVAL_Q3 = 1'b0; // OK
defparam data_chan_master_[i].SRVAL_Q4 = 1'b0;  // OK
defparam data_chan_master_[i].DYN_CLKDIV_INV_EN = "FALSE"; // OK
defparam data_chan_master_[i].DYN_CLK_INV_EN = "FALSE";   // OK
defparam data_chan_master_[i].OFB_USED = "FALSE";    // OK
defparam data_chan_master_[i].IOBDELAY = "BOTH";    // OK
end
endgenerate
// synthesis translate_on

generate
genvar i;
for (i=0; i<=num_chan-1; i=i+1) begin
    assign dataout[i] = {{q1[i],q2[i]},{q3[i],q4[i]}};
    //assign data_out[num_chan*i+:4] = dataout[i];
    assign data_out[num_chan*(i+1)-1 : num_chan*i] = dataout[i];

    always @(posedge domain_reset or posedge clkdiv) begin
        if (domain_reset) begin
            dataout_R1[i] <= 0;
        end else begin
            dataout_R1[i] <= dataout[i];
        end
    end
end
endgenerate


// Instantiate deskew module that implements bit alignment algorithm
deskew deskew_module (
      .datain(datain),
     .edgei(edgei_training),
     .rst(domain_reset),
     .deskew_en(op_sel[0]), 
     .clkdiv(clkdiv),
     .dlyce(dlyce_training),
     .dlyinc(dlyinc_training),
     .done(deskew_done)   
    ); 
    
// Instantiate the control module that implements the word alignment algorithm
bitslip_ctrl bitslip_control_module (
      .datain(datain),
     .rst(domain_reset),
     .bitslip_en(op_sel[1]), 
     .clkdiv(clkdiv),
     .bitslip(bitslip_training),
     .done(bitslip_done),
     .error(bitslip_error)    
    ); 

// Multi-purpose Counter
always @(posedge cnt_rst or posedge clkdiv)
begin
   if (cnt_rst)
      counter <= 8'h00;
   else if (counter[2])
      counter <= 8'h00;
   else
      counter <= counter + 1'b1;
end      

// Module that controls the operation select (bit align, word align, bitslip adjust
// or window monitoring) and channel select.
always @(posedge domain_reset or posedge clkdiv)
begin
   if (domain_reset)
   begin      
      op_sel <= 4'b0000;
     train_done <= 1'b0;
      chan_sel <= {num_chan{1'b0}};
     cnt_rst <= 1'b1;
   end
   else if (train_en)
   begin
      if (~|op_sel)
      begin   
         op_sel <= 4'b0001;
        train_done <= 1'b0;
         chan_sel <= 1;
        cnt_rst <= 1'b1;
      end 
      else if (op_sel[0])
      begin
         if (~|chan_sel)
        begin
           op_sel <= op_sel << 1;
           train_done <= 1'b0;
            chan_sel <= 1;
           cnt_rst <= 1'b1;                         
        end
        else if (deskew_done)
        begin
            op_sel <= op_sel;
            train_done <= 1'b0;
            chan_sel <= chan_sel << 1; 
           cnt_rst <= 1'b1;                         
        end
        else
        begin
            op_sel <= op_sel;
            train_done <= 1'b0;
            chan_sel <= chan_sel; 
           cnt_rst <= 1'b1;                         
        end
      end      
      else if (op_sel[1])
      begin
         if (~|chan_sel)
        begin
           op_sel <= op_sel << 1;
           train_done <= 1'b0;
            chan_sel <= 0;
           cnt_rst <= 1'b0;                                 
        end
        else if (bitslip_done)
        begin
            op_sel <= op_sel;
            train_done <= 1'b0;
            chan_sel <= chan_sel << 1; 
           cnt_rst <= 1'b1;                         
         end
        else
        begin
            op_sel <= op_sel;
            train_done <= 1'b0;
            chan_sel <= chan_sel; 
           cnt_rst <= 1'b1;                         
        end
      end
      else if (op_sel[2])
      begin
         if (~|chan_sel)
        begin
           op_sel <= op_sel << 1;
           train_done <= 1'b1;
            chan_sel <= 1;      
           cnt_rst <= 1'b1;                                     
        end
        // If counter = 2
        else if (counter[1] && ~counter[0]) 
        begin
            op_sel <= op_sel;
            train_done <= 1'b0;
            chan_sel <= chan_sel;
          cnt_rst <= 1'b0;                  
        end
        // If counter = 3, increment chan sel
        else if (counter[1] & counter[0]) 
        begin
            op_sel <= op_sel;
            train_done <= 1'b0;
            chan_sel <= chan_sel >> 1; 
           cnt_rst <= 1'b0;                 
        end
        else
        begin
            op_sel <= op_sel;
            train_done <= 1'b0;
            chan_sel <= chan_sel; 
           cnt_rst <= 1'b0;                 
        end
      end
      else if (op_sel[3])
      begin
        op_sel <= op_sel;
        train_done <= 1'b1;
        cnt_rst <= 1'b1;
         if (~|chan_sel)
            chan_sel <= 1;                          
        else if (monitor_done)
            chan_sel <= chan_sel << 1;                      
        else
        begin
            chan_sel <= chan_sel;                       
        end
     end
      else
      begin
         op_sel <= 4'b0000;
        train_done <= 1'b0;
         chan_sel <= 0;
        cnt_rst <= 1'b1;
     end
   end
   else // !train_en
   begin 
      if (op_sel[3])
      begin
        op_sel <= op_sel;
        train_done <= 1'b1;
        cnt_rst <= 1'b1;
         if (~|chan_sel)
            chan_sel <= 1;                          
        else if (monitor_done)
            chan_sel <= chan_sel << 1;                      
        else
        begin
            chan_sel <= chan_sel;                       
        end
      end
      else
      begin
         op_sel <= 4'b0000;
        train_done <= 1'b0;
         chan_sel <= 0;
        cnt_rst <= 1'b1;
      end
   end
end     

// Dataout Channel Select Mux
reg [3:0] muxout;

always @(posedge clkdiv) begin: muxout_assign
    integer i;

        for (i = 0; i < num_chan; i = i + 1) begin
            if ((1<<i) == chan_sel)
                muxout <= dataout_R1[i];
        end
end

assign datain = muxout;

// Instantiate muxes that route the bitslip, dlyce and dlyinc control signals to 
// the data ISERDES and monitor ISERDES.
generate
genvar k;
   for (k=0; k<=num_chan-1; k=k+1)
   begin :  bitslip_generate
      assign bitslip[k] = chan_sel[k] ? bitslip_training : 1'b0;    
      assign dlyce[k] = chan_sel[k] ? dlyce1 : 1'b0;
      assign dlyinc[k] = chan_sel[k] ? dlyinc1 : 1'b0;
        assign dlyce_to_data_iserdes[k] = dlyce[k] | ice_ext;
        assign dlyinc_to_data_iserdes[k] = dlyinc[k] | inc_ext;     
   end 
endgenerate

always @(posedge domain_reset or posedge clkdiv)
begin
   if (domain_reset)
    begin
       dlyce_training_R1 <= 1'b0;
        dlyinc_training_R1 <= 1'b0;
      dlyce1 <= 1'b0;
      dlyinc1 <= 1'b0;
   end
    else
    begin
    dlyce_training_R1 <= dlyce_training;
    dlyinc_training_R1 <= dlyinc_training;
      dlyce1 <= dlyce_training_R1;
      dlyinc1 <= dlyinc_training_R1;
    end
end
                           
endmodule
