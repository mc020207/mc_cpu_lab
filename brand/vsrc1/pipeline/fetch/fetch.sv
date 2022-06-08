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
    input u64 jump
);
	u1 move,bubble,stop,pc_stop;
    u64 pc,pc_next;
    fetch_data_t dataF_next;
    assign pc_stop=(~iresp.data_ok)|stopd|stope|stopm;
    assign ireq.addr=pc;
    assign ireq.valid=~move;
    assign bubble=~iresp.data_ok;
    assign stop=stopd|stope|stopm;
    assign dataF_next.pc=pc;
    assign dataF_next.valid=~branch;
    assign dataF_next.raw_instr=iresp.data;
    always_comb begin
        pc_next=0;
        if (reset) pc_next=64'h80000000;
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
            if (stop) dataF<=dataF;
            else if (bubble) dataF.valid<=0;
            else dataF<=dataF_next;
        end
    end
endmodule
`endif