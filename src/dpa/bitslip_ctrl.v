//******************************************************************************
//
//  Xilinx, Inc. 2002                 www.xilinx.com
//
//
//*******************************************************************************
//
//  File name :       bitslip_ctrl.v
//
//  Description :     This module implements the bitslip control
//                    module. The bitslip module implements the algorithm
//                    for word alignment. 
//                    
//  Date - revision : 11/30/2004
//
//  Author :          Tze Yi Yeoh
//
//  Contact : e-mail  hotline@xilinx.com
//            phone   + 1 800 255 7778 
//
//  Disclaimer: LIMITED WARRANTY AND DISCLAMER. These designs are 
//              provided to you "as is". Xilinx and its licensors make and you 
//              receive no warranties or conditions, express, implied, 
//              statutory or otherwise, and Xilinx specifically disclaims any 
//              implied warranties of merchantability, non-infringement, or 
//              fitness for a particular purpose. Xilinx does not warrant that 
//              the functions contained in these designs will meet your 
//              requirements, or that the operation of these designs will be 
//              uninterrupted or error free, or that defects in the Designs 
//              will be corrected. Furthermore, Xilinx does not warrant or 
//              make any representations regarding use or the results of the 
//              use of the designs in terms of correctness, accuracy, 
//              reliability, or otherwise. 
//
//              LIMITATION OF LIABILITY. In no event will Xilinx or its 
//              licensors be liable for any loss of data, lost profits, cost 
//              or procurement of substitute goods or services, or for any 
//              special, incidental, consequential, or indirect damages 
//              arising from the use or operation of the designs or 
//              accompanying documentation, however caused and on any theory 
//              of liability. This limitation will apply even if Xilinx 
//              has been advised of the possibility of such damage. This 
//              limitation shall apply not-withstanding the failure of the 
//              essential purpose of any limited remedies herein. 
//
//  Copyright © 2002 Xilinx, Inc.
//  All rights reserved 
// 
//*****************************************************************************

`timescale 1ps/1ps

module bitslip_ctrl (
      datain,
	 rst,
	 bitslip_en, 
	 clkdiv,
	 bitslip,
	 done,
	 error 
      );


input [3:0] datain;
input rst; 
input bitslip_en;
input clkdiv;
output bitslip;
output done;
output error;

reg [3:0] Current_State;
reg [3:0] Next_State;
reg [7:0] counter;
reg cnt_rst;
reg cnt_inc;
wire pattern_detect;
reg bitslip;
reg done;
reg error;

parameter [7:0] BITSLIP_LIMIT = 8'b00010100;

// Bitslip Control State Machine
//Declare state machine parameters
parameter START               = 4'b0000; //0
parameter START_WAIT1         = 4'b0001; //1
parameter START_WAIT2         = 4'b0010; //2
parameter SEEK_PATTERN1       = 4'b0011; //3
parameter SEEK_PATTERN2       = 4'b0100; //4
parameter SEEK_PATTERN3       = 4'b0101; //5
parameter SEEK_PATTERN4       = 4'b0110; //6
parameter SEEK_PATTERN5       = 4'b0111; //7
parameter BITSLIP             = 4'b1000; //8
parameter WAIT_BITSLIP1       = 4'b1001; //9
parameter WAIT_BITSLIP2       = 4'b1010; //10
parameter DONE                = 4'b1011; //11
parameter WAIT1_DONE          = 4'b1100; //12
parameter ERROR               = 4'b1101; //13
//

// Pattern Detect Logic
// Detect a "0011" pattern from ISERDES output
assign pattern_detect = (datain[3] & datain[2] & ~datain[1] & ~datain[0]);

// All-purpose counter
always @ (posedge clkdiv or posedge rst) 
begin
   if (rst)    
      counter <= 8'h00;
   else if (cnt_rst)    
      counter <= 8'h00;
   else if (cnt_inc)
      counter <= counter + 1'b1; 
	else
	   counter <= counter;
end

// Current State Logic
always @ (posedge clkdiv or posedge rst) 
begin
   if (rst) 
   begin     
      Current_State <= START ;
   end
	else
   begin
      Current_State <= Next_State;
   end 
end

// Output forming logic
always @ (Current_State)
	begin
      case (Current_State)
         START: begin
	       cnt_rst <= 1'b1;
		  cnt_inc <= 1'b0;
	       bitslip <= 1'b0;           
	       done <= 1'b0;
	       error <= 1'b0;
	    end
	    // Insert wait states after START to account for pipeline stages
	    // in channel select MUX.
         START_WAIT1: begin
	       cnt_rst <= 1'b0;
		  cnt_inc <= 1'b0;
	       bitslip <= 1'b0;           
	       done <= 1'b0;
	       error <= 1'b0;
	    end

         START_WAIT2: begin
	       cnt_rst <= 1'b0;
		  cnt_inc <= 1'b0;
	       bitslip <= 1'b0;           
	       done <= 1'b0;
	       error <= 1'b0;
	    end

         SEEK_PATTERN1: begin
	       cnt_rst <= 1'b0;
		  cnt_inc <= 1'b0;
	       bitslip <= 1'b0;           
	       done <= 1'b0;
	       error <= 1'b0;
         end

         SEEK_PATTERN2: begin
	       cnt_rst <= 1'b0;
		  cnt_inc <= 1'b0;
	       bitslip <= 1'b0;           
	       done <= 1'b0;
	       error <= 1'b0;
         end

         SEEK_PATTERN3: begin
	       cnt_rst <= 1'b0;
		  cnt_inc <= 1'b0;
	       bitslip <= 1'b0;           
	       done <= 1'b0;
	       error <= 1'b0;
         end

         SEEK_PATTERN4: begin
	       cnt_rst <= 1'b0;
		  cnt_inc <= 1'b0;
	       bitslip <= 1'b0;           
	       done <= 1'b0;
	       error <= 1'b0;
         end

         SEEK_PATTERN5: begin
	       cnt_rst <= 1'b0;
		  cnt_inc <= 1'b0;
	       bitslip <= 1'b0;           
	       done <= 1'b0;
	       error <= 1'b0;
         end

         BITSLIP: begin
	       cnt_rst <= 1'b0;
		  cnt_inc <= 1'b1;
	       bitslip <= 1'b1;           
	       done <= 1'b0;
	       error <= 1'b0;
         end

         WAIT_BITSLIP1: begin
	       cnt_rst <= 1'b0;
		  cnt_inc <= 1'b0;
	       bitslip <= 1'b0;           
	       done <= 1'b0;
	       error <= 1'b0;
         end

         WAIT_BITSLIP2: begin
	       cnt_rst <= 1'b0;
		  cnt_inc <= 1'b0;
	       bitslip <= 1'b0;           
	       done <= 1'b0;
	       error <= 1'b0;
         end

  	      // Bitslip operation is complete. The training pattern has been detected. The data
	      // channel has been word aligned.  
         DONE: begin
	       cnt_rst <= 1'b1;
		  cnt_inc <= 1'b0;
	       bitslip <= 1'b0;           
	       done <= 1'b1;
	       error <= 1'b0;
	      end

         WAIT1_DONE: begin
	       cnt_rst <= 1'b1;
		  cnt_inc <= 1'b0;
	       bitslip <= 1'b0;           
	       done <= 1'b0; 
	       error <= 1'b0;
	      end

         ERROR: begin
	       cnt_rst <= 1'b0;
		  cnt_inc <= 1'b0;
	       bitslip <= 1'b0;           
	       done <= 1'b0;
	       error <= 1'b1;
	      end

         default: begin
	       cnt_rst <= 1'b0;
		  cnt_inc <= 1'b0;
	       bitslip <= 1'b0;           
	       done <= 1'b0;
	       error <= 1'b0;
	    end				 
      endcase
	end


always @ (Current_State or rst or bitslip_en or counter or pattern_detect)
begin
   case (Current_State)
      START: begin
		   if (rst)
			begin
	         Next_State <= START; 
			end
		   else if (!bitslip_en)
			begin
	         Next_State <= START; 
			end
			else
			begin
	         Next_State <= START_WAIT1; 
			end
		end

	    // Insert wait states after START to account for pipeline stages
	    // in channel select MUX.
      START_WAIT1: begin
         Next_State <= START_WAIT2;
      end

      START_WAIT2: begin
         Next_State <= SEEK_PATTERN1;
      end

      SEEK_PATTERN1: begin
	    if (pattern_detect) // If Paterrn = 0011
            Next_State <= DONE;	      
	    else					     																			    
            Next_State <= SEEK_PATTERN2;
      end

      SEEK_PATTERN2: begin
	    if (pattern_detect) // If Paterrn = 0011
            Next_State <= DONE;	      
	    else					     																			    
            Next_State <= SEEK_PATTERN3;
      end

      SEEK_PATTERN3: begin
	    if (pattern_detect) // If Paterrn = 0011
            Next_State <= DONE;	      
	    else					     																			    
            Next_State <= SEEK_PATTERN4;
      end

      SEEK_PATTERN4: begin
	    if (pattern_detect) // If Paterrn = 0011
            Next_State <= DONE;	      
	    else					     																			    
            Next_State <= SEEK_PATTERN5;
      end

      SEEK_PATTERN5: begin
	    if (pattern_detect) // If Paterrn = 0011
            Next_State <= DONE;	      
	    else					     																			    
            Next_State <= BITSLIP;
      end

	  // Activate one bitslip operation
      BITSLIP: begin
         Next_State <= WAIT_BITSLIP1;
      end

      WAIT_BITSLIP1: begin
         Next_State <= WAIT_BITSLIP2;
      end     

      WAIT_BITSLIP2: begin
         Next_State <= SEEK_PATTERN1;
      end
	
  	  // Bitslip operation is complete. The training pattern has been detected. The data
	  // channel has been word aligned.  
     DONE: begin    
        Next_State <= WAIT1_DONE;
     end

     WAIT1_DONE: begin    
        Next_State <= START;
     end

     ERROR: begin    
        Next_State <= ERROR;
     end

   default: Next_State <= START ;
   endcase
end

endmodule

