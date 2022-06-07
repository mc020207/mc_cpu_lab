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
    input creg_addr_t ra,dstE,dstM,dstW,
    input word_t scr,rdE,rdM,rdW,
    input logic ismemE,bubbleE,bubbleM,bubbleW,writeM,writeW,
    output word_t rd,
    output logic bubble
);
    always_comb begin
        rd=scr;
        bubble=0;
        if (ra==0) begin
            rd=scr;
            bubble=0;
        end else if (ra==dstE&&bubbleE==0) begin
            if (ismemE) begin
                bubble=1;
            end else begin
                rd=rdE;
            end
        end else if (ra==dstM&&bubbleM==0&&writeM) begin
            rd=rdM;
        end else if (ra==dstW&&bubbleW==0&&writeW) begin
            rd=rdW;
        end
    end
endmodule
`endif 