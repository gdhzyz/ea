
    
    `include "uart2apb_utils.vh"
    localparam CASE1_TIME_OUT_CYCLES = 1000;

    // Takes in input byte and serializes it 
    task local_write_reg;
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
            @(posedge clk);
            @(negedge reset);
            @(posedge clk);
            // write req header
            s_axis_tvalid <= 1;
            s_axis_tdata <= {1'b0, local_fpga_index, 3'd1, 1'b0};
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
            // value0
            s_axis_tvalid <= 1;
            s_axis_tdata <= {data[7:0], 1'b1};
            s_axis_tuser <= 0;
            s_axis_tlast <= 1;
            wait_fire;
            // value1
            s_axis_tvalid <= 1;
            s_axis_tdata <= {data[15:8], 1'b1};
            s_axis_tuser <= 0;
            s_axis_tlast <= 1;
            wait_fire;
            // value2
            s_axis_tvalid <= 1;
            s_axis_tdata <= {data[23:16], 1'b1};
            s_axis_tuser <= 0;
            s_axis_tlast <= 1;
            wait_fire;
            // value3
            s_axis_tvalid <= 1;
            s_axis_tdata <= {data[31:24], 1'b1};
            s_axis_tuser <= 0;
            s_axis_tlast <= 1;
            wait_fire;

            // check apb
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
            if (!(psel && penable && paddr == addr && pwrite && pstrb == 4'hf && pwdata == data)) begin
                $error("local_write_reg failed!");
                $error("actual: psel %d penable %d paddr 0x%h pwrite %d pstrb 0x%h pwdata 0x%h",
                    psel, penable, paddr, pwrite, pstrb, pwdata);
                $error("expected: psel %d penable %d paddr 0x%h pwrite %d pstrb 0x%h pwdata 0x%h",
                    1, 1, addr, 1, 4'hf, data);
                $finish;
            end

            // feed apb
            pready <= 1;
            @(posedge clk);
            @(posedge clk);
            if (psel || penable) begin
                $error("local_write_reg failed!");
                $error("actual: psel %d penable %d", psel, penable);
                $error("expected: psel %d penable %d", 0, 0);
                $finish;
            end else begin
                $display("uart2reg_tb_case1 passed!");
            end
            
            $finish;
         end
    endtask


    initial begin
        local_write_reg;
    end

    integer case1_i;
    initial begin
        for (case1_i = 0; case1_i < CASE1_TIME_OUT_CYCLES; case1_i = case1_i + 1) begin
            @(posedge clk);
        end
        $error("uart2reg_tb_case1 timeout!");
        $finish;
    end