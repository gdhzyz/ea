

localparam CASE1_TIME_OUT_CYCLES = 1000000;

task write_once;
    input [4:0] addr;
    input [15:0] wdata;
    begin
        mdio_valid <= 1;
        mdio_write <= 1;
        mdio_addr <= addr;
        mdio_wdata <= wdata;
        @(posedge clk);
        while (~mdio_ready) begin
            @(posedge clk);
        end
        mdio_valid <= 0;
        @(posedge clk);
    end
endtask

task read_once;
    input [4:0] addr;
    output [15:0] rdata;
    begin
        mdio_valid <= 1;
        mdio_write <= 0;
        mdio_addr <= addr;
        @(posedge clk);
        while (~mdio_ready) begin
            @(posedge clk);
        end
        rdata <= mdio_rdata;
        mdio_valid <= 0;
        @(posedge clk);
    end
endtask

task automatic mdio_tb_case1;
    input [4:0] iaddr;
    input [15:0] iwdata;
    reg [15:0] rdata;
    begin
        // --------- write -----------
        write_once(iaddr, iwdata);
        read_once(iaddr, rdata);

        if (rdata != iwdata) begin
            $error("mdio_tb_case1 compare failed, expected 0x%h, got 0x%h", iwdata, rdata);
        end else begin
            $display("mdio_tb_case1 passed!!!");
        end
     end
endtask
initial begin
    mdio_valid = 0;
    mdio_write = 0;
    mdio_addr = 0;
    mdio_wdata = 0;
    
    @(posedge clk);
    @(negedge reset);
    @(posedge clk);
    
    mdio_tb_case1(5'd5, 16'hA5A5);
    mdio_tb_case1(5'd15, 16'hBBCC);
    $finish;
end
integer case1_i;
initial begin
    for (case1_i = 0; case1_i < CASE1_TIME_OUT_CYCLES; case1_i = case1_i + 1) begin
        @(posedge clk);
    end
    $error("test_case1 timeout!");
    $finish;
end