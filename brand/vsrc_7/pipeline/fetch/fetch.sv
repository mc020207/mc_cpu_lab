`ifndef _FETCH_SV
`define _FETCH_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/fetch/pcselect.sv"
`else

`endif
module fetch
    import common::*;
    import pipes::*;(
    input logic clk,
    input logic reset,
    output fetch_data_t dataF,
    output u64 pc,
    input u64 pc_nxt,
    output ibus_req_t  ireq,
	input  ibus_resp_t iresp,
    input u1 stop_forbranch,
    input branch,
    output logic stop_forfetch,
    input logic stop_formem,
    input logic move
);
    u64 pc_before;
	assign ireq.addr=pc_nxt;
	assign ireq.valid=(pc_before[27:0]==pc_nxt[27:0]);
	u32 raw_instr;
	assign raw_instr=iresp.data;
    fetch_data_t dataF_next;
    assign dataF_next.raw_instr=raw_instr;
    assign dataF_next.pc=reset?64'h8000_0000:pc_nxt;
    assign dataF_next.iresp_data=iresp.data;
    assign dataF_next.bubble=~iresp.data_ok;
    always_ff @( posedge clk ) begin
        dataF<=dataF_next;
        dataF.valid<=1;
        pc<=pc_nxt;
        pc_before<=pc_nxt;
        stop_forfetch<=~iresp.data_ok;
    end
endmodule
`endif