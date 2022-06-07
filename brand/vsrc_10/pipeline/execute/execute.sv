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
    input logic clk,reset,
	input decode_data_t dataD,
    output excute_data_t dataE,
    output u1 branch,
    output u64 jump,
    input logic stopm,
    output logic stope,
    output tran_t trane
);
    u1 bubble;
    contral_t ctl;
    word_t rd2,rd1;
    u32 raw_instr;
    excute_data_t dataE_next;
    word_t alu_result;
    alu alu(
        .clk,
        .srca(dataD.srca),
        .srcb(dataD.srcb),
        .alufunc(ctl.alufunc),
        .result(alu_result),
        .choose(ctl.op==ALUW||ctl.op==ALUIW),
        .ctl,.bubble,.valid(dataD.valid)
    );
	offset offset_module(
        .valid(dataD.valid),
        .raw_instr,
        .ctl,
        .choose(alu_result),
        .jump,
        .branch,
        .pc(dataD.pc),
        .jumppc(dataD.rd1+{{52{raw_instr[31]}},raw_instr[31:20]})
    );
    assign raw_instr=dataD.raw_instr;
    assign ctl=dataD.ctl;
    assign dataE_next.pc=dataD.pc;
    assign dataE_next.valid=dataD.valid;
    assign dataE_next.raw_instr=dataD.raw_instr;
    assign dataE_next.ctl=dataD.ctl;
    assign dataE_next.dst=dataD.dst;
    assign dataE_next.rd2=dataD.rd2;
    assign dataE_next.result=alu_result;
    assign stope=bubble&dataD.valid;
    assign trane.data=alu_result;
    assign trane.dst=(ctl.regwrite&dataD.valid)?dataD.dst:0;
    assign trane.ismem=(ctl.op==LD);
    always_ff @( posedge clk ) begin
        if (reset) begin
           dataE.valid<=0;
        end
        else begin
            if (stopm) dataE<=dataE;
            else if (bubble&dataD.valid) dataE.valid<=0;
            else dataE<=dataE_next;
        end
    end
endmodule

`endif
