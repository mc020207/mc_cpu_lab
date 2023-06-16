`ifndef _FETCH_SV
`define _FETCH_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif
module fetch
    import common::*;
    import pipes::*;(
    input logic clk,reset,branch,stopd,stope,stopm,
    output fetch_data_t dataF,
    output ibus_req_t ireq,
    input ibus_resp_t iresp,
    input u64 jump,csrpc,
    output u1 stopf,
    input u1 flushde,flushall
);
	u1 move,bubble,stop,pc_stop;
    u64 pc,pc_next;
    fetch_data_t dataF_next;
    assign pc_stop=(pc[1:0]==2'b0)&&((~iresp.data_ok)|stopd|stope|stopm);
    assign ireq.addr=pc;
    assign ireq.valid=(~move)&&(pc[1:0]==2'b0);
    assign bubble=(pc[1:0]==2'b0)&&(~iresp.data_ok);
    assign stop=stopd|stope|stopm;
    assign dataF_next.pc=pc;
    assign dataF_next.valid=~branch;
    assign dataF_next.raw_instr=iresp.data;
    assign dataF_next.error=(pc[1:0]==2'b0)?NOERROR:FETCHERROR;
    assign stopf=pc_stop;
    always_comb begin
        pc_next=0;
        if (reset) pc_next=64'h80000000;
        else if (flushall) pc_next=csrpc;
        else if (branch) pc_next=jump;
        else if (pc_stop) pc_next=pc;
        else pc_next=pc+4;
    end
    always_ff@(posedge clk) begin
        move<=(pc!=pc_next);
        if (reset) begin
            pc<=64'h80000000;
            dataF.valid<=0;
        end
        else begin
            pc<=pc_next;
            if (flushall) dataF.valid<=0;
            else if (stop) dataF<=dataF;
            else if (bubble) dataF.valid<=0;
            else dataF<=dataF_next;
        end
    end
endmodule
`endif