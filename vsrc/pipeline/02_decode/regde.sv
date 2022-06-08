`ifndef __REGDE_SV
`define __REGDE_SV

`ifdef  VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else
`endif

module regde
    import common::*;
    import pipes::*;
(
    input  u1            clk, reset, 
    input  flush_t       bubble,
    input  stall_t       stop,
    input  decode_data_t dataD_nxt,
    output decode_data_t dataD
);

    always_ff@(posedge clk) begin 
        if(reset || bubble != NOFLUSH) begin
            dataD <= '0;
        end else if(stop == STALLM || stop == STALLE || stop == STALLW) begin
            dataD <= dataD;
        end else begin
            dataD <= dataD_nxt;
        end
    end

endmodule


`endif