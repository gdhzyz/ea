`timescale 1ns/1ps

module top_4ch_training_monitor (
     train_done,
     idelayctrl_ready,
     iobclk,
     clk_200m,
     data_in,
     rst,
     train_en,
     inc_ext,
     ice_ext
    );

// Parameter that determines the number of channels instantiated.
parameter num_chan = 5;

output train_done;
(* mark_debug = "true" *)output idelayctrl_ready;
input  iobclk;
input  clk_200m;
input  [num_chan-1:0] data_in;
(* mark_debug = "true" *)input  rst;
(* mark_debug = "true" *)input  train_en;
input  inc_ext;
input  ice_ext;

(* mark_debug = "true" *)reg [num_chan-1:0] chan_sel;
(* mark_debug = "true" *)wire deskew_done;
(* mark_debug = "true" *)wire bitslip_done;
wire monitor_done;
wire bitslip_error;
(* mark_debug = "true" *)reg  train_done;
wire [num_chan-1:0] dlyce;
wire [num_chan-1:0] dlyinc;
wire [num_chan-1:0] dlyce_to_data_idelay;
wire [num_chan-1:0] dlyinc_to_data_idelay;
wire dlyce_training;
wire dlyinc_training;
reg dlyce_training_R1;
reg dlyinc_training_R1;
reg dlyce1;
reg dlyinc1;
wire [num_chan-1:0] bitslip;
(* mark_debug = "true" *)wire bitslip_training;
wire iobclk;
wire clkdiv;
wire [num_chan-1:0] q1;
wire [num_chan-1:0] q2;
wire [num_chan-1:0] q3;
wire [num_chan-1:0] q4;
wire [3:0] datain;
reg [3:0] dataout_R1[num_chan-1:0];
wire [3:0] dataout_int[num_chan-1:0];
(* mark_debug = "true" *)wire [2:0] edgei_training;
(* mark_debug = "true" *)reg [7:0] counter;
reg cnt_rst;
(* mark_debug = "true" *)reg [3:0] op_sel;

wire bufio_clk;
BUFIO RX_CLK_BUFIO(.O(bufio_clk), .I(iobclk));
wire bufr_clk;
BUFR RX_CLK_BUFR(.O(bufr_clk), .CE(1'b1), .CLR(1'b0), .I(iobclk));
//synopsys translate_off
defparam RX_CLK_BUFR.BUFR_DIVIDE = "bypass";
//synopsys translate_on
BUFR RX_CLK_BUFR2(.O(clkdiv), .CE(1'b1), .CLR(1'b0), .I(bufr_clk));
//synopsys translate_off
defparam RX_CLK_BUFR2.BUFR_DIVIDE = "2";
//synopsys translate_on

wire idelayctrl_ready;
(* mark_debug = "true" *)wire domain_reset;
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
(* mark_debug = "true" *)wire [4:0] delayed_count_value[num_chan-1:0];
(* mark_debug = "true" *)wire [1:0] iddr_out[num_chan-1:0];
(* mark_debug = "true" *)reg [1:0] iddr_out_temp[num_chan-1:0];

generate
genvar i;
for (i=0; i<=num_chan-1; i=i+1)
begin :  for_generator
    IDELAYE2 data_idelay (
        .C(clkdiv),
        .REGRST(domain_reset),
        .LD(1'b0), // update when in product.
        .CE(dlyce_to_data_idelay[i]),
        .INC(dlyinc_to_data_idelay[i]),
        .CINVCTRL(1'b0),
        .CNTVALUEIN(5'd0),
        .IDATAIN(data_in[i]),
        .LDPIPEEN(1'b0),
        .DATAIN(),
        .DATAOUT(delayed_data_in[i]),
        .CNTVALUEOUT(delayed_count_value[i])
    );

    iddr #(
    .TARGET("XILINX"),
    .IODDR_STYLE("IODDR"),
    .WIDTH(1)
    )
    data_iddr_inst (
        .clk(bufio_clk),
        .d(delayed_data_in[i]),
        .q1(iddr_out[i][0]),
        .q2(iddr_out[i][1])
    );

    always @(posedge bufr_clk) begin
        iddr_out_temp[i] <= iddr_out[i];
    end
    
// synthesis translate_off
    defparam data_idelay.IDELAY_TYPE = "VARIABLE";
    defparam data_idelay.DELAY_SRC = "IDATAIN";
    defparam data_idelay.IDELAY_VALUE = 0;
    defparam data_idelay.HIGH_PERFORMANCE_MODE = "TRUE";
    defparam data_idelay.SIGNAL_PATTERN = "DATA";
    defparam data_idelay.REFCLK_FREQUENCY = 200; // IDELAYCTRL clock input frequency in MHz
    defparam data_idelay.CINVCTRL_SEL = "FALSE";
    defparam data_idelay.PIPE_SEL = "FALSE";
// synthesis translate_on

    always @(posedge domain_reset or posedge clkdiv) begin
        if (domain_reset) begin
            dataout_R1[i] <= 0;
        end else begin
            dataout_R1[i] <= {iddr_out[i], iddr_out_temp[i]};
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
        assign dlyce_to_data_idelay[k] = dlyce[k] | ice_ext;
        assign dlyinc_to_data_idelay[k] = dlyinc[k] | inc_ext;     
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
