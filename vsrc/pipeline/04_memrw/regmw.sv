`ifndef __REGMW_SV
`define __REGMW_SV

`ifdef  VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else
`endif

module regmw
    import common::*;
    import pipes::*;
(
    input  u1            clk, reset,
    input  flush_t       bubble,
    input  stall_t       stop,
    input  memory_data_t dataM_nxt,
    input  u1            dbus_not_busy, ibus_not_busy,
    output memory_data_t dataM
);

    always_ff@(posedge clk) begin 
        if(reset || (bubble == FLUSHW && ibus_not_busy && dbus_not_busy) || stop == STALLM) begin
            dataM <= '0;
        end else if(stop == STALLW) begin
            dataM <= dataM;
        end else begin
            dataM <= dataM_nxt;
        end
    end

endmodule


`endif
