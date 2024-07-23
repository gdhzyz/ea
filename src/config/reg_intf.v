
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
    output wire       srst, // soft reset

    /*
     * UART
     */
    input  wire       uart_intf_rx,
    output wire       uart_intf_tx,

    /*
     * configurations
     */
    output wire [3:0] fpga_index,
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

wire         uart2reg_busy;
wire         uart2reg_error;    
wire [31:0]  reg_wreq_count;
wire [31:0]  reg_rreq_count;
wire [31:0]  reg_rack_count;

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
    .pslverr(pslverr),

    /*
     * Configuration
     */
    .local_fpga_index(fpga_index),
    .busy(uart2reg_busy),
    .error(uart2reg_error),
    .wreq_count(reg_wreq_count),
    .rreq_count(reg_rreq_count),
    .rack_count(reg_rack_count)
);

wire reset_trigger;

block_ea #(
    .ADDRESS_WIDTH(16),
    .VERSION_INITIAL_VALUE(32'h24072300)
) reg_block (
    .i_clk(clk),
    .i_rst_n(!rst),
    .i_psel(psel),
    .i_penable(penable),
    .i_paddr(paddr),
    .i_pprot(pprot),
    .i_pwrite(pwrite),
    .i_pstrb(pstrb),
    .i_pwdata(pwdata),
    .o_pready(pready),
    .o_prdata(prdata),
    .o_pslverr(pslverr),
    .i_version(`VERSION),
    .i_reset(srst),
    .o_reset_trigger(reset_trigger),
    .o_index(fpga_index),
    .i_uart_bit_rate(115200),
    .i_uart_reg_write_req_count(reg_wreq_count),
    .i_uart_reg_read_req_count(reg_rreq_count),
    .i_uart_reg_read_ack_count(reg_rack_count),
    .i_uart_write_data_count(),
    .i_uart_recv_data_count(),
    .o_uart_data_dst_fpga_index(),
    .o_uart_reg_dst_fpga_index(),
    .i_mac_send_count(),
    .i_mac_recv_count(),
    .i_mac_reg_write_req_count(),
    .i_mac_reg_read_req_count(),
    .i_mac_reg_read_ack_count()
);

reg srst_reg = 0;
assign srst = srst_reg;
always @(posedge clk) begin
    if (reset_trigger) begin
        srst_reg <= 1;
    end else begin
        srst_reg <= 0;
    end
end


endmodule

`resetall
