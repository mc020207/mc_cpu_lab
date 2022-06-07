`ifndef __EXCUTE_SV
`define __EXCUTE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/execute/alu.sv"
`include "pipeline/execute/offset.sv"
`else

`endif

module execute
	import common::*;
	import pipes::*;(
    input logic clk,
    input logic reset,
	input decode_data_t dataD,
    output excute_data_t dataE,
    output u1 branch,
    output u64 jump,
    input u64 pc,
    input logic stop_formem,
    output logic stop_forexe
);
    u1 bubble;
    contral_t ctl;
    word_t rd2,rd1;
    u32 raw_instr;
    assign raw_instr=dataD.raw_instr;
    word_t alu_result;
    assign ctl=dataD.ctl;
	alu alu(
        .clk,
        .srca(dataD.scra),
        .srcb(dataD.scrb),
        .alufunc(ctl.alufunc),
        .result(alu_result),
        .choose(ctl.op==ALUW||ctl.op==ALUIW),
        .ctl,.bubble,.valid(~dataD.bubble)
    );
	offset offset_module(
        .bubble(dataD.bubble),
        .raw_instr(raw_instr),
        .ctl(ctl),
        .choose(alu_result),
        .jump,
        .branch(branch),
        .pc,
        .jumppc(dataD.rd1+{{52{raw_instr[31]}},raw_instr[31:20]})
    );
    excute_data_t dataE_next;
    assign dataE_next.bubble=dataD.bubble|bubble;
    assign dataE_next.ismem=dataD.ismem;
    assign dataE_next.result=alu_result;
    assign dataE_next.ctl=ctl;
    assign dataE_next.pc=dataD.pc;
    assign dataE_next.dst=dataD.dst;
    assign dataE_next.scra=dataD.scra;
    assign dataE_next.scrb=dataD.scrb;
    assign dataE_next.valid=dataD.valid;
    assign dataE_next.iresp_data=dataD.iresp_data;
    assign dataE_next.rd1=dataD.rd1;
    assign dataE_next.rd2=dataD.rd2;
    assign stop_forexe=(bubble&~dataD.bubble);
    always_ff @( posedge clk ) begin
        if (reset) begin
           dataE<='0;
        end
        else if (~stop_formem) begin
            dataE<=dataE_next;
        end
    end
endmodule

`endif
