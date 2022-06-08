`ifndef __REGEM_SV
`define __REGEM_SV

`ifdef  VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else
`endif

module regem
    import common::*;
    import pipes::*;
(
    input  u1             clk, reset, 
    input  flush_t        bubble,
    input  stall_t        stop,
    input  execute_data_t dataE_nxt,
    input  u1             ibus_not_busy, dbus_not_busy,
    output execute_data_t dataE
);

    always_ff@(posedge clk) begin 
        if(reset || (bubble == FLUSHW && dbus_not_busy) || (bubble == FLUSHM && ibus_not_busy) || stop == STALLE) begin
            dataE <= '0;
        end else if(stop == STALLM || stop == STALLW) begin
            dataE <= dataE;
        end else begin
            dataE <= dataE_nxt;
        end
    end

endmodule


`endif
