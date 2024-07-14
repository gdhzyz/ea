
    localparam CASE1_TIME_OUT_CYCLES = 1000;
    reg [DATA_WIDTH-1:0] CASE1_TEST_DATA = {DATA_WIDTH{8'hA5}};
    // Takes in input byte and serializes it 
    task send_one_trans;
        begin
            @(posedge clk);
            // start
            data <= 1'b0;
            valid <= 0;
            @(negedge reset);
            @(posedge clk);
            valid <= 1;
            data <= CASE1_TEST_DATA;
            keep <= {KEEP_WIDTH{1'b1}};
            last <= 1'b1;
            user <= 1'b1;
            @(posedge clk);
            valid <= 1'b0;
            @(posedge clk);
         end
    endtask

    task check_one_trans;
        integer i;
        begin
            i = 0;
            oready <= 1'b0;
            forever begin
                @(posedge clk);
                if (ovalid) begin
                    oready <= 1'b1;
                end
                if (ovalid && oready) begin
                    if (odata == CASE1_TEST_DATA && 
                            okeep == {KEEP_WIDTH{1'b1}} && 
                            olast == 1'b1 && 
                            ouser == 1'b1) begin
                        $display("decouple_tb_case1 pass!");
                    end else begin
                        $error("decouple_tb_case1 failed!");
                        $error("ovalid %b odata 0x%h okeep 0x%h olast %b ouser %d", 
                                ovalid, odata, okeep, olast, ouser);
                    end
                    $finish;
                end

                i = i + 1;
                if (i == CASE1_TIME_OUT_CYCLES) begin
                    $error("decouple_tb_case1 timeout!");
                    $finish;
                end
            end
        end
    endtask

    initial begin
        send_one_trans;
    end

    initial begin
        check_one_trans;
    end
