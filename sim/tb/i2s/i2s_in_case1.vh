




localparam CASE1_TIME_OUT_CYCLES = 10000;

assign bclki = bclkt ? bclko : 1'bz;
assign lrcki = lrckt ? lrcko : 1'bz;

task run_one_channel;
    input [3:0] i;
    input [31:0] idata;

    input [2:0] i_tdm_num;
    input i_word_width;
    input [1:0] i_valid_word_width;
    input i_lrck_is_pulse;
    input i_lrck_polarity;
    input i_lrck_alignment;
    input [2:0] i_bclk_factor;

    reg lrcki_d1;
    reg [31:0] loop_counter;
    reg [5:0] actual_valid_word_width;
    reg [4:0] actual_tdm_num;

    begin
        enable[i] <= 1'b0;
        @(posedge clk);
        @(posedge clk);

        // configure
        tdm_num[3*(i+1)-1 : 3*i] <= i_tdm_num;
        is_master[i] <= 1'b1;
        dst_fpga_index[4*(i+1)-1 : 4*i] <= 4'd3;
        word_width[i] <= i_word_width;
        valid_word_width[2*(i+1) : 2*i] <= i_valid_word_width;
        lrck_is_pulse[i] <= i_lrck_is_pulse;
        lrck_polarity[i] <= i_lrck_polarity;
        lrck_alignment[i] <= i_lrck_alignment;
        bclk_factor[3*(i+1) : 3*i] <= i_bclk_factor;

        if (i_valid_word_width == 1) begin
            actual_valid_word_width <= 6'd16;
        end else if (i_valid_word_width == 2) begin
            actual_valid_word_width <= 6'd24;
        end else if (i_valid_word_width == 3) begin
            actual_valid_word_width <= 6'd32;
        end

        actual_tdm_num = 1 << i_tdm_num;

        @(posedge clk);

        // start
        enable[i] <= 1;
        @(posedge clk);

        fork
            begin: thread1
                // check
                loop_counter = 0;
                while (loop_counter < 10) begin
                    @(posedge bclki[i]);
                    if (m_axis_tvalid[i]) begin
                        check_one_channel(i, actual_valid_word_width, idata, loop_counter == actual_tdm_num-1);
                        loop_counter = loop_counter + 1;
                    end
                end
            end

            begin: thread2
                driver_one_channel(i, idata, actual_valid_word_width);
            end
        join

        $finish;
     end
endtask

task check_one_channel;
    input [3:0] i;
    input [5:0] valid_width;
    input [31:0] expected_data;
    input expected_last;

    reg [31:0] valid_actual_data;
    reg [31:0] valid_expected_data;

    begin
        valid_expected_data = expected_data[valid_width-1:0];
        valid_actual_data = m_axis_tdata[32*(i+1)-1:32*8][valid_width-1:0];
        if ((valid_expected_data != valid_actual_data) || 
                (expected_last ^ m_axis_tlast[i])) begin
            $error("index %d valid_width %d expected_data 0x%h got data 0x%h, expected_last %d got last %d",
                   i, valid_width, valid_expected_data, valid_actual_data, expected_last, m_axis_tlast[i]);
            $finish;
        end

    end
endtask

task driver_one_channel;
    input [3:0] i;
    input [31:0] idata;
    input [5:0] valid_width;

    reg lrck_d1;
    reg [31:0] counter;
    reg start;

    begin
        counter <= 0;
        start <= 0;
        lrck_d1 <= 0;
        forever begin
            @(negedge bclki[i]);
            lrck_d1 <= lrcki[i];
            datai[i] <= idata[counter];
            if (lrck_d1 ^ lrcki[i]) begin
                start <= 1;
                counter <= 1;
            end else if (start) begin
                counter <= counter + 1;
            end

        end
    end
endtask

initial begin
    // wait mmcm to be ready
    @(negedge dut.rst_int);
    // 192KHz tdm2 width32 valid24 50% posedge left_aligned 12.288MHz
    run_one_channel(0,  32'h1234_5678, 1, 1, 2, 0, 0, 0, 2);
    // 48KHz tdm4  width16 valid16 50% posedge left_aligned 12.288MHz
    run_one_channel(15, 32'hA5A5_A5A5, 2, 0, 1, 0, 0, 0, 2);
    // 48KHz tdm8  width32 valid32 50% posedge delayed_aligned 12.288MHz
    run_one_channel(15, 32'hA5A5_A5A5, 3, 1, 3, 0, 0, 1, 2);
end
