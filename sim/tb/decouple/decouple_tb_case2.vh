
    localparam CASE2_TIME_OUT_CYCLES = 2000;
    localparam CASE2_BEATS = 256;
    // Takes in input byte and serializes it 
    task send_trans;
        integer i;
        begin
            @(posedge clk);
            // start
            data <= 1'b0;
            valid <= 0;
            @(negedge reset);
            i = 0;
            while (i < CASE2_BEATS) begin
                @(posedge clk);
                if (valid && ready) begin
                    i = i + 1;
                end
                valid <= 1;
                data <= i[DATA_WIDTH-1:0];
                keep <= {KEEP_WIDTH{1'b1}};
                last <= i % 256 == 0;
                user <= i % 10 == 0;

            end
            @(posedge clk);
            valid <= 1'b0;
            @(posedge clk);
         end
    endtask

    task check_trans;
        integer i;
        integer acc;
        integer acc_after;
        begin
            i = 0;
            acc = 0;
            acc_after = 0;
            oready <= 1'b0;
            forever begin
                @(posedge clk);
                if (ovalid) begin
                    oready <= i % 3 == 0;
                end
                if (ovalid && oready) begin
                    if (odata != acc[DATA_WIDTH-1:0] || 
                            okeep != {KEEP_WIDTH{1'b1}} || 
                            olast != (acc % 256 == 0) && 
                            ouser != (acc % 10 == 0)) begin
                        $error("decouple_tb_case2 failed!");
                        $error("acc %d ovalid %b odata 0x%h okeep 0x%h olast %b ouser %d", 
                                acc, ovalid, odata, okeep, olast, ouser);
                        $finish;
                    end
                    acc = acc + 1;
                end

                if (acc >= CASE2_BEATS) begin
                    acc_after = acc_after + 1;
                    if (acc_after == 1000) begin
                        if (acc == CASE2_BEATS) begin
                            $display("decouple_tb_case2 pass!");
                            $finish;
                        end else begin
                            $error("decouple_tb_case2 failed, too many acc %d, expected acc %d",
                                    acc, CASE2_BEATS);
                            $finish;
                        end
                    end
                end

                i = i + 1;
                if (i == CASE2_TIME_OUT_CYCLES) begin
                    $error("decouple_tb_case2 timeout!");
                    $finish;
                end
            end
        end
    endtask

    initial begin
        send_trans;
    end

    initial begin
        check_trans;
    end
