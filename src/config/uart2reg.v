
// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * Uart to register module for both local and remote.
 */
module uart2reg
(
    /*
     * Clock: 125MHz
     * Synchronous reset
     */
    input  wire         clk,
    input  wire         rst,

    /*
     * UART rx
     */
    input  wire         s_axis_tvalid,
    input  wire [8:0]   s_axis_tdata,
    input  wire         s_axis_tuser,
    input  wire         s_axis_tlast,
    output wire         s_axis_tready,

    /*
     * UART tx
     */
    output wire         m_axis_tvalid,
    output wire [8:0]   m_axis_tdata,
    output wire         m_axis_tuser,
    output wire         m_axis_tlast,
    input  wire         m_axis_tready,

    /*
     * APB
     */
    output wire         psel,
    output wire         penable,
    output wire [15:0]  paddr,
    output wire [2:0]   pprot,
    output wire         pwrite,
    output wire [3:0]   pstrb,
    output wire [31:0]  pwdata,
    input  wire         pready,
    input  wire [31:0]  prdata,
    input  wire [31:0]  pslverr,

    /*
     * Configuration
     */
    input  wire [3:0]   local_fpga_index,
    output wire         busy,
    output wire         error
);

localparam S_IDLE = 0;
localparam S_ADDR0 = 1;
localparam S_ADDR1 = 2;
localparam S_WDATA0 = 3;
localparam S_WDATA1 = 4;
localparam S_WDATA2 = 5;
localparam S_WDATA3 = 6;
localparam S_WAIT_WRITE = 7;
localparam S_WAIT_READ = 8;
localparam S_RD_HEADER = 9;
localparam S_RDATA0 = 10;
localparam S_RDATA1 = 11;
localparam S_RDATA2 = 12;
localparam S_RDATA3 = 13;

wire sfire = s_axis_tvalid && s_axis_tready;
wire mfire = m_axis_tvalid && m_axis_tready;
wire pfire = psel && penable && pready;

reg [3:0] state_reg=S_IDLE, state_next;
wire is_command = s_axis_tdata[0] == 1'b0;
wire is_wr_w = s_axis_tdata[3:1] == 3'd1;
wire is_rd_w = s_axis_tdata[3:1] == 3'd2;
wire [3:0] dst_fpga_w = s_axis_tdata[7:4];
wire is_local_w = dst_fpga_w == 4'd0 || dst_fpga_w == local_fpga_index;
wire start = is_command && sfire && is_local_w;

reg is_wr=0, is_rd=0;
reg [3:0] dst_fpga;

wire [7:0] sdata = s_axis_tdata[8:1];

reg penable_reg=0, penable_next;
reg [15:0] paddr_reg=0, paddr_next;
reg pwrite_reg=0, pwrite_next;
reg [31:0] pwdata_reg=0, pwdata_next;
reg [31:0] prdata_reg=0, prdata_next;

reg m_axis_tvalid_reg=0, m_axis_tvalid_next;
reg m_axis_tlast_reg=0, m_axis_tlast_next;
reg [8:0] m_axis_tdata_reg, m_axis_tdata_next;

always @(*) begin
    state_next = state_reg;
    penable_next = penable_reg;
    paddr_next = paddr_reg;
    pwrite_next = pwrite_reg;
    pwdata_next = pwdata_reg;
    prdata_next = prdata_reg;
    m_axis_tvalid_next = m_axis_tvalid_reg;
    m_axis_tlast_next = m_axis_tlast_reg;
    m_axis_tdata_next = m_axis_tdata_reg;

    if (start) begin
        state_next = S_ADDR0;
    end else begin
        case(state_reg)
            S_IDLE: begin
                if (start) begin
                    state_next = S_ADDR0;
                end
            end
            S_ADDR0: begin
                if (sfire) begin
                    state_next = S_ADDR1;
                    paddr_next = {sdata, paddr_reg[15:8]};
                end
            end
            S_ADDR1: begin
                if (sfire) begin
                    if (is_wr) begin
                        state_next = S_WDATA0;
                        penable_next = 1'b0;
                    end else begin
                        state_next = S_WAIT_READ;
                        penable_next =1'b1;
                    end
                    paddr_next = {sdata, paddr_reg[15:8]};
                end
            end
            S_WDATA0: begin
                if (sfire) begin
                    state_next = S_WDATA1;
                    pwdata_next = {sdata, pwdata_reg[31:8]};
                end
            end
            S_WDATA1: begin
                if (sfire) begin
                    state_next = S_WDATA2;
                    pwdata_next = {sdata, pwdata_reg[31:8]};
                end
            end
            S_WDATA2: begin
                if (sfire) begin
                    state_next = S_WDATA3;
                    pwdata_next = {sdata, pwdata_reg[31:8]};
                end
            end
            S_WDATA3: begin
                if (sfire) begin
                    state_next = S_WAIT_WRITE;
                    pwdata_next = {sdata, pwdata_reg[31:8]};
                    penable_next =1'b1;
                    pwrite_next = 1'b1;
                end
            end
            S_WAIT_WRITE: begin
                if (pfire) begin
                    state_next = S_IDLE;
                    penable_next = 1'b0;
                    pwrite_next = 1'b0;
                end
            end
            S_WAIT_READ: begin
                if (pfire) begin
                    state_next = S_RD_HEADER;
                    penable_next = 1'b0;
                    prdata_next = prdata;
                    m_axis_tvalid_next = 1'b1;
                    m_axis_tlast_next = 1'b0;
                    m_axis_tdata_next = {1'b0, dst_fpga, 3'd3, 1'b0};
                end
            end
            S_RD_HEADER: begin
                if (mfire) begin
                    state_next = S_RDATA0;
                    m_axis_tvalid_next = 1'b1;
                    m_axis_tlast_next = 1'b0;
                    m_axis_tdata_next = {prdata_reg[7:0], 1'b1};
                end
            end
            S_RDATA0: begin
                if (mfire) begin
                    state_next = S_RDATA1;
                    m_axis_tvalid_next = 1'b1;
                    m_axis_tlast_next = 1'b0;
                    m_axis_tdata_next = {prdata_reg[15:8], 1'b1};
                end
            end
            S_RDATA1: begin
                if (mfire) begin
                    state_next = S_RDATA2;
                    m_axis_tvalid_next = 1'b1;
                    m_axis_tlast_next = 1'b0;
                    m_axis_tdata_next = {prdata_reg[23:16], 1'b1};
                end
            end
            S_RDATA2: begin
                if (mfire) begin
                    state_next = S_RDATA3;
                    m_axis_tvalid_next = 1'b1;
                    m_axis_tlast_next = 1'b1;
                    m_axis_tdata_next = {prdata_reg[31:24], 1'b1};
                end
            end
            S_RDATA3: begin
                if (mfire) begin
                    state_next = S_IDLE;
                    m_axis_tvalid_next = 1'b0;
                    m_axis_tlast_next = 1'b0;
                end
            end
        endcase
    end
end

always @(posedge clk) begin
    if (rst) begin
        state_reg <= S_IDLE;
    end else begin
        state_reg <= state_next;
    end
end

reg busy_reg=0;
assign busy = busy_reg;
always @(posedge clk) begin
    if (rst) begin
        busy_reg <= 1'b0;
    end else begin
        busy_reg <= state_reg != S_IDLE;
    end
end

reg error_reg=0;
assign error = error_reg;
always @(posedge clk) begin
    if (rst) begin
        error_reg <= 1'b0;
    end else if (pfire) begin
        error_reg <= pslverr;
    end
end

always @(posedge clk) begin
    if (start) begin
        is_wr <= is_wr_w;
        is_rd <= is_rd_w;
        dst_fpga <= dst_fpga_w;
    end
end

always @(posedge clk) begin
    paddr_reg <= paddr_next;
    pwrite_reg <= pwrite_next;
    pwdata_reg <= pwdata_next;
    prdata_reg <= prdata_next;

    m_axis_tlast_reg <= m_axis_tlast_next;
    m_axis_tdata_reg <= m_axis_tdata_next;

    if (rst) begin
        penable_reg <= 1'b0;
        m_axis_tvalid_reg <= 1'b0;
    end else begin
        penable_reg <= penable_next;
        m_axis_tvalid_reg <= m_axis_tvalid_next;
    end
end

/*
 * APB
 */
assign psel = penable_reg;
assign penable = penable_reg;
assign paddr = paddr_reg;
assign pprot = 3'd0;
assign pwrite = pwrite_reg;
assign pstrb = 4'hf;
assign pwdata = pwdata_reg;

assign s_axis_tready = 1'b1;

assign m_axis_tvalid = m_axis_tvalid_reg;
assign m_axis_tdata = m_axis_tdata_reg;
assign m_axis_tuser = 1'b0;
assign m_axis_tlast = m_axis_tlast_reg;


endmodule

`resetall
