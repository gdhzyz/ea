
    `include "uart2reg_utils.vh"
    localparam CASE2_TIME_OUT_CYCLES = 1000;

    task check_uart_tx;
        input [8:0] expected_data;
        input expected_user;
        input expected_last;
        begin
            if (!m_axis_tvalid || 
                    expected_data != m_axis_tdata || 
                    expected_user != m_axis_tuser ||
                    expected_last != m_axis_tlast) begin
                $error("wrong uart tx!");
                $error("expected: valid %d data 0x%h user %d last %d",
                        1, expected_data, expected_user, expected_last);
                $error("actual %d data 0x%h user %d last %d",
                        1, m_axis_tdata, m_axis_tuser, m_axis_tlast);
                $finish;
            end
            @(posedge clk);
        end
    endtask

    // Takes in input byte and serializes it 
    task local_read_reg;
        reg [15:0] addr;
        reg [31:0] data;
        begin
            addr = 16'h1234;
            data = 32'h5678_9ABC;
            s_axis_tvalid = 0;
            local_fpga_index = 1;
            pready = 0;
            prdata = 0;
            pslverr = 0;
            m_axis_tready = 0;
            @(posedge clk);
            @(negedge reset);
            @(posedge clk);
            // write req header
            s_axis_tvalid <= 1;
            s_axis_tdata <= {1'b0, local_fpga_index, 3'd2, 1'b0};
            s_axis_tuser <= 0;
            s_axis_tlast <= 1;
            wait_fire;
            // addr0
            s_axis_tvalid <= 1;
            s_axis_tdata <= {addr[7:0], 1'b1};
            s_axis_tuser <= 0;
            s_axis_tlast <= 1;
            wait_fire;
            // addr1
            s_axis_tvalid <= 1;
            s_axis_tdata <= {addr[15:8], 1'b1};
            s_axis_tuser <= 0;
            s_axis_tlast <= 1;
            wait_fire;

            // check apb
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
            if (!(psel && penable && paddr == addr && !pwrite && pstrb == 4'hf)) begin
                $error("local_write_reg failed!");
                $error("actual: psel %d penable %d paddr 0x%h pwrite %d pstrb 0x%h",
                    psel, penable, paddr, pwrite, pstrb);
                $error("expected: psel %d penable %d paddr 0x%h pwrite %d pstrb 0x%h",
                    1, 1, addr, 0, 4'hf);
                $finish;
            end

            // feed apb
            pready <= 1;
            prdata <= data;
            @(posedge clk);
            @(posedge clk);
            if (psel || penable) begin
                $error("local_write_reg failed!");
                $error("actual: psel %d penable %d", psel, penable);
                $error("expected: psel %d penable %d", 0, 0);
                $finish;
            end

            // check uart tx
            while (!m_axis_tvalid) begin
                @(posedge clk);
            end
            @(posedge clk);
            if (!m_axis_tvalid) begin
                $error("m_axis_tvalid is wrong!");
                $finish;
            end

            m_axis_tready <= 1;
            @(posedge clk);
            // header
            check_uart_tx({1'b0, local_fpga_index, 3'd3, 1'b0}, 1'b0, 1'b0);
            // value0
            check_uart_tx({data[7:0], 1'b1}, 1'b0, 1'b0);
            // value1
            check_uart_tx({data[15:8], 1'b1}, 1'b0, 1'b0);
            // value2
            check_uart_tx({data[23:16], 1'b1}, 1'b0, 1'b0);
            // value3
            check_uart_tx({data[31:24], 1'b1}, 1'b0, 1'b1);
            m_axis_tready <= 0;
            if (m_axis_tvalid) begin
                $error("too many m_axis_tvalid!");
                $finish;
            end

            $display("uart2reg_tb_case2 passed!");
            $finish;
         end
    endtask


    initial begin
        local_read_reg;
    end

    integer case2_i;
    initial begin
        for (case2_i = 0; case2_i < CASE2_TIME_OUT_CYCLES; case2_i = case2_i + 1) begin
            @(posedge clk);
        end
        $error("uart2reg_tb_case2 timeout!");
        $finish;
    end