




localparam CASE1_TIME_OUT_CYCLES = 10000;

assign bclki = bclkt ? bclko : 1'bz;
assign lrcki = lrckt ? lrcko : 1'bz;

function [511:0] get_partial;
    input [511:0] data;
    input [8:0] up;
    input [8:0] down;

    integer i;
    reg[31:0] mask;

    begin
        data = data >> down;
        mask = ((1 << (up-down+1)) - 1);
        get_partial = data & mask;
        //$display("data 0x%h mask 0x%h got 0x%h",
        //          data, mask, get_partial);
    end
endfunction

function [511:0] partial_update;
    input [511:0] data;
    input [8:0] up;
    input [8:0] down;
    input [511:0] new;

    reg [511:0] data1;
    reg [511:0] data2;
    reg [511:0] data3;

    begin
        data1 = get_partial(data, 511, up+1) << (up+1);
        data2 = get_partial(new, up, down) << down;
        data3 = 0;
        if (down > 0) begin
            data3 = get_partial(data, down-1, 0);
        end
        partial_update = data1 | data2 | data3;
        $display("data 0x%h up 0x%h down 0x%h new 0x%h got 0x%h",
                  data, up, down, new, partial_update);
    end
endfunction

function [511:0] indexed_update;
    input [511:0] data;
    input [8:0] width;
    input [8:0] i;
    input [31:0] new;

    reg [8:0] up;
    reg [8:0] down;
    reg [511:0] data1;

    begin
        up = width * (i+1) - 1;
        down = width * i; 
        data1 = new << down;
        indexed_update = partial_update(data, up, down, data1);
        //$display("data 0x%h up 0x%h down 0x%h new 0x%h got 0x%h",
        //          data, up, down, new, indexed_update);
    end
endfunction

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
        tdm_num = indexed_update(0, 3, i, i_tdm_num);
        is_master[i] <= 1'b1;
        dst_fpga_index <= indexed_update(0, 4, i, 4'd3);
        word_width[i] <= i_word_width;
        valid_word_width <= indexed_update(0, 2, i, i_valid_word_width);
        lrck_is_pulse[i] <= i_lrck_is_pulse;
        lrck_polarity[i] <= i_lrck_polarity;
        lrck_alignment[i] <= i_lrck_alignment;
        bclk_factor <= indexed_update(0, 3, i, i_bclk_factor);

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
                        check_one_channel(
                            i,
                            actual_valid_word_width, 
                            idata, 
                            loop_counter%actual_tdm_num == actual_tdm_num-1);
                        loop_counter = loop_counter + 1;
                    end
                end
                $display("loop %d times, all passes.", loop_counter);
                $finish;
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

    reg [7:0] actual_byte;
    reg [31:0] valid_expected_data;
    reg [5:0] got_bits;
    reg [7:0] valid_expected_byte;
    reg last_byte;

    begin
        valid_expected_data = partial_update(0, 31, 32-valid_width, expected_data);
        got_bits = 0;
        last_byte = valid_width == 8 && expected_last;

        while ((valid_width > got_bits)) begin
            if (m_axis_tvalid[i]) begin
                actual_byte = get_partial(m_axis_tdata, 8*(i+1)-1, 8*i);
                valid_expected_byte = valid_expected_data >> (valid_width - got_bits - 8);
                last_byte = valid_width == got_bits+8 && expected_last;

                if ((valid_expected_byte !== actual_byte) || 
                        (last_byte ^ m_axis_tlast[i])) begin
                    $error("index %d valid_width %d got_bits %d expected_byte 0x%h actual_byte 0x%h expected_last %d got last %d",
                           i, valid_width, got_bits, valid_expected_byte, actual_byte, last_byte, m_axis_tlast[i]);
                    $finish;
                end else begin
                    $display("index %d check one byte pass, valid_width %d got bits %d expected data 0x%h",
                             i, valid_width, got_bits, valid_expected_data);
                end
                got_bits = got_bits + 8;
            end
            @(posedge bclki[i]);
        end
        $display("index %d check one channel pass, valid_width %d expected data 0x%h",
                 i, valid_width, valid_expected_data);

    end
endtask

task driver_one_channel;
    input [3:0] i;
    input [31:0] idata;
    input [5:0] valid_width;

    reg lrck_d1;
    reg lrck_d2;
    reg [31:0] counter;
    reg start;
    reg lrck_neg;
    reg new_channel;
    reg lrck;

    begin
        $display("driving channel %d idata 0x%h valid_width %d", i, idata, valid_width);
        counter <= 31;
        @(negedge lrcki[i]);
        if (lrck_alignment[i] == 1'b1) begin // delay one more cycle
            @(negedge bclki[i]);
        end
        lrck_d1 = lrcki[i];
        lrck_d2 = lrcki[i];
        forever begin
            if (lrck_alignment[i] == 1'b0 && (lrcki[i] ^ lrck_d1)) begin
                counter = 31;
            end else if (lrck_alignment[i] == 1'b1 && (lrck_d1 ^ lrck_d2)) begin
                counter = 31;
            end
            datai[i] = idata[counter];
            
            counter = counter - 1;
            lrck_d1 <= lrcki[i];
            lrck_d2 <= lrck_d1;
            @(negedge bclki[i]);

        end
    end
endtask

initial begin
    // wait mmcm to be ready
    @(negedge dut.rst_int);
    //// 192KHz tdm2 width32 valid24 50% posedge left_aligned 12.288MHz
    //run_one_channel(0,  32'h1234_5678, 1, 1, 2, 0, 0, 0, 2);
    //// 48KHz tdm4  width16 valid16 50% posedge left_aligned 12.288MHz
    //run_one_channel(15, 32'hA5A5_A5A5, 2, 0, 1, 0, 0, 0, 2);
    // 48KHz tdm8  width32 valid32 50% posedge delayed_aligned 12.288MHz
    run_one_channel(15, 32'hA5A5_A5A5, 3, 1, 3, 0, 0, 1, 2);
end
