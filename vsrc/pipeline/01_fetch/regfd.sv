`ifndef __REGFD_SV
`define __REGFD_SV

`ifdef  VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else
`endif

module regfd
    import common::*;
    import pipes::*;
(
    input  u1           clk, reset,
    input  flush_t      bubble,
    input  stall_t      stop,
    input  fetch_data_t dataF_nxt,
    output fetch_data_t dataF
);

    always_ff@(posedge clk) begin 
        if(reset || bubble != NOFLUSH || stop == STALLF) begin
            dataF <= '0;
        end else if(stop == STALLM || stop == STALLE || stop == STALLW) begin 
            dataF <= dataF;
        end else begin
            dataF <= dataF_nxt;
        end
    end

endmodule


`endif