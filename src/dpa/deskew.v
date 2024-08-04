//******************************************************************************
//
//  Xilinx, Inc. 2002                 www.xilinx.com
//
//
//*******************************************************************************
//
//  File name :       deskew.v
//
//  Description :     This module implements the training control
// module. The training module implements the algorithm
// for word alignment and bit alignment 
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
//  Copyright � 2002 Xilinx, Inc.
//  All rights reserved 
// 
//*****************************************************************************

`timescale 1ps/1ps

module deskew (
      datain,
	 edgei,
	 rst,
	 deskew_en, 
	 clkdiv,
	 dlyce,
	 dlyinc,
	 done
      );


(* mark_debug = "true" *)input [3:0] datain;
output [2:0] edgei;
input rst; 
(* mark_debug = "true" *)input deskew_en;
input clkdiv;
(* mark_debug = "true" *)output dlyce;
(* mark_debug = "true" *)output dlyinc;
(* mark_debug = "true" *)output done;

(* mark_debug = "true" *)reg [4:0] Current_State;
reg [4:0] Next_State;
(* mark_debug = "true" *)reg [7:0] counter;
//synthesis attribute keep of counter is true;
(* mark_debug = "true" *)reg [7:0] center_store;
wire [2:0] edgei;
(* mark_debug = "true" *)reg [2:0] edgei_init;
//synthesis attribute keep of edgei_init is true;
reg cnt_rst;
reg cnt_inc;
reg loadedgei;
reg load_center;
reg dlyce;
reg dlyinc;
reg done;
wire [7:0] center;

// Training Control State Machine
//Declare state machine parameters
parameter START        = 5'b00000; //0
parameter START_WAIT1  = 5'b00001; //1
parameter START_WAIT2  = 5'b00010; //2
parameter SEEK_EDGE    = 5'b00011; //3
parameter INC1          = 5'b00100; //4
parameter INC1_WAIT1    = 5'b00101; //5
parameter INC1_WAIT2    = 5'b00110; //6
parameter INC1_WAIT3    = 5'b00111; //7
parameter EDGE1        = 5'b01000; //8
parameter INC2          = 5'b01001; //9
parameter INC2_WAIT1    = 5'b01010; //10
parameter INC2_WAIT2    = 5'b01011; //11
parameter INC2_WAIT3    = 5'b01100; //12
parameter EDGE2        = 5'b01101; //13
parameter EDGE2_WAIT1  = 5'b01110; //14
parameter CENTER_DEC   = 5'b01111; //15
parameter CHECK_CENTER = 5'b10000; //16
parameter DONE         = 5'b10001; //17
parameter DONE_WAIT1   = 5'b10010; //18
parameter DONE_WAIT2   = 5'b10011; //19
parameter NO_INC1      = 5'b10100; //20
parameter NO_INC2      = 5'b10101; //21
parameter INC1_WAIT4      = 5'b10110; //22
parameter INC1_WAIT5      = 5'b10111; //23
parameter INC1_WAIT6      = 5'b11000; //24
parameter INC1_WAIT7      = 5'b11001; //25
parameter INC1_WAIT8      = 5'b11010; //26
parameter INC2_WAIT4      = 5'b11011; //27
parameter INC2_WAIT5      = 5'b11100; //28
parameter INC2_WAIT6      = 5'b11101; //29
parameter INC2_WAIT7      = 5'b11110; //30
parameter INC2_WAIT8      = 5'b11111; //31
//

// Divide tap_counter by 2 to get mid point 
assign center = (center_store >> 1); 

// Create edge information
assign edgei[2] = datain[3] ^ datain[2];
assign edgei[1] = datain[2] ^ datain[1];
assign edgei[0] = datain[1] ^ datain[0]; 

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

always @ (posedge clkdiv or posedge rst) 
begin
   if (rst)    
   begin
      center_store <= 8'h00;
   end   
   else if (load_center)  
   begin  
      center_store <= counter;
   end	 
   else
   begin
      center_store <= center_store;
   end	 
end

always @ (posedge clkdiv or posedge rst) 
begin
   if (rst)    
   begin
      edgei_init <= 1'b0;
   end   
   else if (loadedgei)  
   begin  
      edgei_init <= edgei;
   end	 
   else
   begin
      edgei_init <= edgei_init;
   end	 
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
	    cnt_rst = 1'b1;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	 end

      START_WAIT1: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	 end

      START_WAIT2: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	 end

     SEEK_EDGE: begin   
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b1;
         load_center = 1'b0;            
	    done = 1'b0;	      
	end

     INC1: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b1;
	    dlyinc = 1'b1;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	end

     INC1_WAIT1: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	end

     INC1_WAIT2: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	  end

     INC1_WAIT3: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	  end

     INC1_WAIT4: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	  end

     INC1_WAIT5: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	  end

     INC1_WAIT6: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	  end

     INC1_WAIT7: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	  end

     INC1_WAIT8: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	  end

	  // Check to see if the Q1 output of the ISERDES has changed 
	  // indicating the first edge has been found.
     EDGE1: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	  end

	  // If the first edge has been found, continue incrememnting 
	  // the tap delay line while incrementing the tap counter
	  // until the second edge is found. 
     INC2: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b1;
         dlyce = 1'b1;
	    dlyinc = 1'b1;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	  end

     INC2_WAIT1: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	  end

     INC2_WAIT2: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	  end

     INC2_WAIT3: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	  end

     INC2_WAIT4: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	  end

     INC2_WAIT5: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	  end

     INC2_WAIT6: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	  end

     INC2_WAIT7: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	  end

     INC2_WAIT8: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	  end

	  // Check to see if the Q2 output of the ISERDES has changed 
	  // indicating the second edge has been found.
     EDGE2: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	  end

     EDGE2_WAIT1: begin
	    cnt_rst = 1'b1;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b1;            
	    done = 1'b0;			     	         
     end   

	  // Once second edge is found, decrement the tap delay line to half
	  // the value of the tap counter 
     CENTER_DEC: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b1;
         dlyce = 1'b1;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;		     	         
     end   

	  // Check to see if the center point of the data eye has been reached.
     CHECK_CENTER: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;	         
     end   

      DONE: begin           
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b1;
      end

      DONE_WAIT1: begin           
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
      end

      DONE_WAIT2: begin           
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
      end		 

     NO_INC1: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	  end

     NO_INC2: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
	  end

      default: begin
	    cnt_rst = 1'b0;
	    cnt_inc = 1'b0;
         dlyce = 1'b0;
	    dlyinc = 1'b0;
         loadedgei = 1'b0;
         load_center = 1'b0;            
	    done = 1'b0;
      end				 
   endcase
end


always @ (Current_State or rst or deskew_en or counter or edgei or edgei_init or center)
begin
   case (Current_State)
      START: begin
		   if (rst)
	         Next_State = START; 
		   else if (!deskew_en)
	         Next_State = START; 
			else
	         Next_State = START_WAIT1; 
		end

     START_WAIT1: begin
        Next_State = START_WAIT2;
	end

     START_WAIT2: begin
        Next_State = SEEK_EDGE;
	end

     SEEK_EDGE: begin   
	   if (edgei[0] || edgei[1])
		//if (edgei[0] & edgei[1] & edgei[2])	            
	      Next_State = INC1;
	   else
	      Next_State = SEEK_EDGE;	      
	end

     INC1: begin
        Next_State = INC1_WAIT1;
	end

     INC1_WAIT1: begin           // new tag is valid
        Next_State = INC1_WAIT2;
	end

     INC1_WAIT2: begin
        Next_State = INC1_WAIT3;
	  end

     INC1_WAIT3: begin
        Next_State = INC1_WAIT4;
	  end

     INC1_WAIT4: begin
        Next_State = INC1_WAIT5;
	  end

     INC1_WAIT5: begin
        Next_State = INC1_WAIT6;
	  end

     INC1_WAIT6: begin
        Next_State = INC1_WAIT7;
	  end

     INC1_WAIT7: begin
        Next_State = INC1_WAIT8;
	  end

     INC1_WAIT8: begin
        Next_State = EDGE1;
	  end

	  // Check to see if the Q1 output of the ISERDES has changed 
	  // indicating the first edge has been found.
     EDGE1: begin
        if (edgei == (edgei_init << 1)) // First edge found
           Next_State = INC2; 
        else /*if (edgei == edgei_init)*/
	      Next_State = INC1;
		  //else
	     // Next_State = NO_INC1;		   
	  end

	  // If the first edge has been found, continue incrememnting 
	  // the tap delay line while incrementing the tap counter
	  // until the second edge is found. 
     INC2: begin
	     Next_State = INC2_WAIT1;
	  end

     INC2_WAIT1: begin
        Next_State = INC2_WAIT2;
	  end

     INC2_WAIT2: begin
        Next_State = INC2_WAIT3;
	  end

     INC2_WAIT3: begin
        Next_State = INC2_WAIT4;
	  end

     INC2_WAIT4: begin
        Next_State = INC2_WAIT5;
	  end

     INC2_WAIT5: begin
        Next_State = INC2_WAIT6;
	  end

     INC2_WAIT6: begin
        Next_State = INC2_WAIT7;
	  end

     INC2_WAIT7: begin
        Next_State = INC2_WAIT8;
	  end

     INC2_WAIT8: begin
        Next_State = EDGE2;
	  end
	  // Check to see if the Q2 output of the ISERDES has changed 
	  // indicating the second edge has been found.
     EDGE2: begin
        if (edgei == (edgei_init << 2))		 			 		 
           Next_State = EDGE2_WAIT1; 
        else /*if (edgei == (edgei_init << 1))*/ 
           Next_State = INC2; 
		  //else
        //   Next_State = NO_INC2; 
	  end

     EDGE2_WAIT1: begin
	     Next_State = CENTER_DEC;			     	         
     end   

	  // Once second edge is found, decrement the tap delay line to half
	  // the value of the tap counter 
     CENTER_DEC: begin
	     Next_State = CHECK_CENTER;			     	         
     end   

	  // Check to see if the center point of the data eye has been reached.
     CHECK_CENTER: begin
	     if (counter == center)
		    Next_State = DONE;
		else
		   Next_State = CENTER_DEC;	         
     end   

   DONE: begin           
      Next_State = DONE_WAIT1 ;
   end

   DONE_WAIT1: begin           
      Next_State = DONE_WAIT2 ;
   end

   DONE_WAIT2: begin           
      Next_State = START ;
   end		 

   NO_INC1: begin
        Next_State = INC1_WAIT1;
	end

   NO_INC2: begin
        Next_State = INC2_WAIT1;
	end

   default: Next_State = START ;
   endcase
end

endmodule

