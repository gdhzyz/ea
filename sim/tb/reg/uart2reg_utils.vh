`ifndef __UART2REG_UTILS_VH__
`define __UART2REG_UTILS_VH__

task emit_uart_tx;
    input [7:0] data;
    begin
        extern_uart_tx_valid <= 1;
        extern_uart_tx_data <= data;
        @(posedge clk);
        extern_uart_tx_valid <= 0;
        extern_uart_tx_data <= 0;
        @(posedge clk);
        while (extern_uart_tx_done == 1'b0) begin
            @(posedge clk);
        end
        @(posedge clk);
    end
endtask

task check_uart_rx;
    input [7:0] expected_data;
    begin
        while (extern_uart_rx_valid == 1'b0) begin
            @(posedge clk);
        end
        if (expected_data != extern_uart_rx_data) begin
            $error("check uart rx, expected data 0x%h, got 0x%h", expected_data, extern_uart_rx_data);
            $finish;
        end
        @(posedge clk);
    end
endtask
`endif // __UART2REG_UTILS_VH__