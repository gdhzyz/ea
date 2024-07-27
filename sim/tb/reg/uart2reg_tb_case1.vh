
`include "../../../src/config/regs/block_ea.vh"

localparam CASE1_TIME_OUT_CYCLES = 1000000;
localparam FPGA_INDEX_ADDR = `BLOCK_EA_INDEX_BYTE_OFFSET;
`include "uart2reg_utils.vh"

task write_fpga_index;
    reg [15:0] addr;
    reg [31:0] data;
    begin
        addr = FPGA_INDEX_ADDR;
        data = 32'h3;
        extern_uart_tx_valid = 0;
        extern_uart_tx_data = 0;
        
        @(posedge clk);
        @(negedge reset);
        @(posedge clk);
        // --------- write fpga_index -----------
        // write req header
        emit_uart_tx({1'b0, 4'd0, 3'b1});
        // addr0
        emit_uart_tx(addr[7:0]);
        // addr1
        emit_uart_tx(addr[15:8]);
        // data0
        emit_uart_tx(data[7:0]);
        // data1
        emit_uart_tx(data[15:8]);
        // data2
        emit_uart_tx(data[23:16]);
        // data3
        emit_uart_tx(data[31:24]);
        $display("write req done");

        // --------- read fpga_index -----------
        // read req header
        emit_uart_tx({1'b0, 4'd0, 3'd2});
        // addr0
        emit_uart_tx(addr[7:0]);
        // addr1
        emit_uart_tx(addr[15:8]);
        $display("read req done");

        // -------- check uart back ----
        // read ack header
        check_uart_rx({1'b0, data[3:0], 3'd3});
        $display("read ack header done");
        // data0
        check_uart_rx(data[7:0]);
        $display("read data0 done");
        // data1
        check_uart_rx(data[15:8]);
        // data2
        check_uart_rx(data[23:16]);
        // data3
        check_uart_rx(data[31:24]);

        $display("uart2reg_tb_case1 passed!!!");
        $finish;
     end
endtask
initial begin
    write_fpga_index;
end
integer case1_i;
initial begin
    for (case1_i = 0; case1_i < CASE1_TIME_OUT_CYCLES; case1_i = case1_i + 1) begin
        @(posedge clk);
    end
    $error("uart2reg_tb_case1 timeout!");
    $finish;
end