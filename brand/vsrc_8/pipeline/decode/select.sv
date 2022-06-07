`ifndef __SELECT_SV
`define __SELECT_SV
`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else
`endif
module select
    import common::*;
    import pipes::*;(
    input creg_addr_t ra,dstE,dstM,dstD,
    input word_t scr,rdE,rdM,
    input logic ismemE,validE,validM,validD,
    output word_t rd,
    output logic bubble
);
    always_comb begin
        rd=scr;
        bubble=0;
        if (ra==0) begin
            rd=scr;
            bubble=0;
        end 
        else if (ra==dstD&&validD) begin
            bubble=1;
            rd=scr;
        end
        else if (ra==dstE&&validE) begin
            if (ismemE) begin
                bubble=1;
            end else begin
                rd=rdE;
            end
        end 
        else if (ra==dstM&&validM) begin
            rd=rdM;
        end
    end
endmodule
`endif 