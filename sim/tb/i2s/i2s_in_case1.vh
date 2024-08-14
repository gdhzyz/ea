



localparam CASE1_TIME_OUT_CYCLES = 10000;

task run;
    reg [31:0] counter;
    begin
        @(negedge reset);
        @(posedge clk);
        @(posedge clk);

        // configure
        bclk_factor <= 1;
        word_width <= 32;
        @(posedge clk);

        // start
        enable <= 1;
        @(posedge clk);

        counter = 0;
        while (counter < CASE1_TIME_OUT_CYCLES) begin
            counter = counter + 1;
            @(posedge clk);
        end
        $finish;
     end
endtask
initial begin
    run;
end