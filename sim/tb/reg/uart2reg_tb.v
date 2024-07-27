
`timescale 1ns/100ps
  
module uart2reg_tb ();
 
   
wire clk;     
wire reset;
wire srst;

wire extern_uart_tx;
reg extern_uart_tx_valid;
reg [8:0] extern_uart_tx_data;
wire extern_uart_tx_active;
wire extern_uart_tx_done;

uart_tx #(
    .CLKS_PER_BIT(125 * 1000 * 1000 / 115200), // 125MHz, 115200bps.
    .WORD(8)
) tb_uart_tx(
    .i_Clock(clk),
    .i_Tx_DV(extern_uart_tx_valid),
    .i_Tx_Byte(extern_uart_tx_data),
    .o_Tx_Active(extern_uart_tx_active),
    .o_Tx_Serial(extern_uart_tx),
    .o_Tx_Done(extern_uart_tx_done)
);

wire extern_uart_rx;
wire extern_uart_rx_valid;
wire [8:0] extern_uart_rx_data;

uart_rx #(
    .CLKS_PER_BIT(125 * 1000 * 1000 / 115200), // 125MHz, 115200bps.
    .WORD(8)
) tb_uart_rx(
    .i_Clock(clk),
    .i_Rx_Serial(extern_uart_rx),
    .o_Rx_DV(extern_uart_rx_valid),
    .o_Rx_Byte(extern_uart_rx_data)
);

wire [3:0] fpga_index;

reg_intf dut (
/*
 * Clock: 125MHz
 * Synchronous reset
 */
.clk(clk),
.rst(reset),
.srst(srst),
/*
 * UART
 */
.uart_intf_rx(extern_uart_tx),
.uart_intf_tx(extern_uart_rx),
/*
 * configurations
 */
.fpga_index(fpga_index)
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

`include "uart2reg_tb_case1.vh"

   
endmodule