`ifndef __UART2REG_UTILS_VH__
`define __UART2REG_UTILS_VH__
    task wait_fire;
        begin
            @(posedge clk);
            while (!(s_axis_tready && s_axis_tvalid)) begin
                //$display("ivalid %d iready %d !(iready && ivalid) %d", ivalid, iready, !(iready && ivalid));
                @(posedge clk);
            end
        end
    endtask
`endif // __UART2REG_UTILS_VH__