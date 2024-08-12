
// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

`include "../head.vh"

/*
 * Register interface.
 */
module reg_intf 
(
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    input  wire         clk,
    input  wire         rst,
    output wire         srst, // soft reset

    /*
     * UART
     */
    input  wire         uart_intf_rx,
    output wire         uart_intf_tx,

    /*
     * MDIO
     */
    output wire         mdio_valid,
    output wire         mdio_write,
    input  wire         mdio_ready,
    output wire [4:0]   mdio_addr,
    output wire [15:0]  mdio_wdata,
    input  wire [15:0]  mdio_rdata,

    /*
     * configurations
     */
    output wire [3:0]   fpga_index,
    output reg  [4:0]   mac_dly_incs,
    input  wire [24:0]  mac_dly_values,
    output wire         mac_enable_jumbo_test,
    input  wire [4:0]   mac_jumbo_errors,
    output reg  [4:0]   mac_jumbo_error_clears
);
localparam UART_BITS = `UART_BITS;

wire                    uart_rx_valid;
wire [UART_BITS-1:0]    uart_rx_data;

uart_rx #(
    .CLKS_PER_BIT(125 * 1000 * 1000 / 115200), // 125MHz, 115200bps.
    .WORD(UART_BITS)
) uart_rx(
    .i_Clock(clk),
    .i_Rx_Serial(uart_intf_rx),
    .o_Rx_DV(uart_rx_valid),
    .o_Rx_Byte(uart_rx_data)
);

wire                    uart_tx_valid;
wire [UART_BITS-1:0]    uart_tx_data;
wire                    uart_tx_active;
wire                    uart_tx_done;

uart_tx #(
    .CLKS_PER_BIT(125 * 1000 * 1000 / 115200), // 125MHz, 115200bps.
    .WORD(UART_BITS)
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
wire         pslverr;

wire         is_local_reg = paddr[15:12] < 4'h8;
wire         is_local_mdio = paddr[15:12] == 4'h8;
wire         reg_pready;
wire [31:0]  reg_prdata;
wire         pready = is_local_mdio ? mdio_ready : reg_pready;
wire [31:0]  prdata = is_local_mdio ? {16'd0, mdio_rdata} : reg_prdata;
assign       mdio_valid = psel && penable && is_local_mdio;
assign       mdio_addr = paddr[4:0];
assign       mdio_wdata = pwdata[15:0];
assign       mdio_write = pwrite;

wire         uart2reg_busy;
wire         uart2reg_error;    
wire [31:0]  reg_wreq_count;
wire [31:0]  reg_rreq_count;
wire [31:0]  reg_rack_count;

uart2apb uart2apb (
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
    .m_axis_tready(!uart_tx_active),

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

wire mac_dly_inc;
reg  [4:0] mac_dly_value;
reg  mac_jumbo_error;
wire mac_jumbo_error_clear;
wire [2:0] mac_dly_sel;

always @(*) begin: mac_dly_sel_block
    integer i;

    for (i = 0; i < 5; i = i + 1) begin
        if (mac_dly_sel == i) begin
            mac_dly_value = mac_dly_values[i*5 +: 5];
            mac_jumbo_error = mac_jumbo_errors[i];

        end
        mac_jumbo_error_clears[i] = mac_jumbo_error_clear && mac_dly_sel == i;
        mac_dly_incs[i] = mac_dly_inc && mac_dly_sel == i;
    end
end

block_ea #(
    .ADDRESS_WIDTH(16),
    .VERSION_INITIAL_VALUE(`VERSION)
) reg_block (
    .i_clk(clk),
    .i_rst_n(!rst),
    .i_psel(psel && is_local_reg),
    .i_penable(penable && is_local_reg),
    .i_paddr(paddr),
    .i_pprot(pprot),
    .i_pwrite(pwrite),
    .i_pstrb(pstrb),
    .i_pwdata(pwdata),
    .o_pready(reg_pready),
    .o_prdata(reg_prdata),
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
    .i_mac_reg_read_ack_count(),
    .o_mac_dly_sel(mac_dly_sel),
    .o_mac_dly_inc_trigger(mac_dly_inc),
    .i_mac_dly_value(mac_dly_value),
    .o_mac_enable_jumbo_test(mac_enable_jumbo_test),
    .i_mac_jumbo_error(mac_jumbo_error),
    .o_mac_jumbo_error_trigger(mac_jumbo_error_clear)

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
