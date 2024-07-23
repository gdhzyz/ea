
// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * Register interface.
 */
module reg_intf 
(
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    input  wire       clk,
    input  wire       rst,

    /*
     * UART
     */
    input  wire       uart_intf_rx,
    output wire       uart_intf_tx,

    /*
     * configurations
     */
    output wire       debug_led
);

wire                uart_rx_valid;
wire [8:0]          uart_rx_data;

uart_rx #(
    .CLKS_PER_BIT(125 * 1000 * 1000 / 115200), // 125MHz, 115200bps.
    .WORK(9)
) uart_rx(
    .i_Clock(clk),
    .i_Rx_Serial(uart_intf_rx),
    .o_Rx_DV(uart_rx_valid),
    .o_Rx_Byte(uart_rx_data)
);

wire                uart_tx_valid;
wire [8:0]          uart_tx_data;
wire                uart_tx_active;
wire                uart_tx_done;

uart_tx #(
    .CLKS_PER_BIT(125 * 1000 * 1000 / 115200), // 125MHz, 115200bps.
    .WORK(9)
) uart_tx(
    .i_Clock(clk),
    .i_Tx_DV(uart_tx_valid),
    .i_Tx_Byte(uart_tx_data),
    .o_Tx_Active(uart_tx_active),
    .o_Tx_Serial(uart_intf_tx),
    .o_Tx_Done(uart_tx_done)
);

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
wire         pready;
wire [31:0]  prdata;
wire [31:0]  pslverr;

uart2reg uart2reg (
    .clk(clk),
    .rst(rst),

    /*
     * UART rx
     */
    .s_axis_tvalid(uart_rx_valid),
    .s_axis_tdata(uart_rx_data),
    .s_axis_tuser(1'b0),
    .s_axis_tlast(1'b1),
    .s_axis_tready(),

    /*
     * UART tx
     */
    .m_axis_tvalid(uart_tx_valid),
    .m_axis_tdata(uart_tx_data),
    .m_axis_tuser(),
    .m_axis_tlast(),
    .m_axis_tready(1'b1),

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
    .pslverr(pslverr)
);

//block_ea #(
//    .ADDRESS_WIDTH(16),
//)

endmodule

`resetall
