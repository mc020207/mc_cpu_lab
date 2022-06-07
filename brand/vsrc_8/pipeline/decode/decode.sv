`ifndef __DECODE_SV
`define __DECODE_SV
`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/decode/decoder.sv"
`include "pipeline/decode/immediate.sv"
`include "pipeline/decode/select.sv"
`else
`endif
module decode 
    import common::*;
    import pipes::*;(
    input logic clk,
    input logic reset,
    input fetch_data_t dataF,
    output decode_data_t dataD,
    output creg_addr_t ra1,ra2,
    input creg_addr_t dstD,dstE,dstM,
    input word_t rd1,rd2,rdE,rdM,
    output logic stop,
    input logic validD,validE,validM,ismemE,
    output u64 pc_stop,
    output u1 stop_forbranch,
    input u1 stop_formem,
    input u1 branch,
    input logic stop_forexe
);
    decode_data_t dataD_next;
    contral_t ctl;
    logic ismem;
    decoder decoder(
        .raw_instr(dataF.raw_instr),
        .ctl(ctl),
        .branch(dataD_next.branch),
        .ismem
    );
    u1 bubble;
    logic bubble1,bubble2;
    word_t temp1,temp2;
    select select1(
        .ra(ra1),.dstE,.dstM,.dstD,
        .scr(rd1),.rdE,.rdM,
        .ismemE,
        .rd(temp1),.validE,.validM,.validD,
        .bubble(bubble1)
    );
    select select2(
        .ra(ra2),.dstE,.dstM,.dstD,
        .scr(rd2),.rdE,.rdM,
        .ismemE,
        .rd(temp2),.validE,.validM,.validD,
        .bubble(bubble2)
    );
    immediate immediate(
        .scra(temp1),.scrb(temp2),
        .pc(dataF.pc),
        .ctl(ctl),
        .raw_instr(dataF.raw_instr),
        .rd1(dataD_next.scra),
        .rd2(dataD_next.scrb),
		.bubble,.bubble1,.bubble2
    );
    assign dataD_next.bubble=dataF.bubble|bubble;
    assign dataD_next.ismem=ismem;
    assign dataD_next.rd2=temp2;
    assign dataD_next.rd1=temp1;
    assign dataD_next.dst=dataF.raw_instr[11:7];
    assign ra1=dataF.raw_instr[19:15];
    assign ra2=dataF.raw_instr[24:20];
    assign dataD_next.ctl=ctl;
    assign dataD_next.pc=(stop&&bubble?pc_stop:dataF.pc);
    assign dataD_next.raw_instr=dataF.raw_instr;
    assign dataD_next.valid=dataF.valid;
    assign dataD_next.iresp_data=dataF.iresp_data;
    assign stop=bubble;
    assign stop_forbranch=dataD_next.branch;
    always_ff @( posedge clk ) begin
        if (reset) begin
            dataD<='0;
        end
        else if ((~stop_formem)&&(~stop_forexe))begin
            dataD<=dataD_next;
            pc_stop<=dataD_next.pc;
            dataD.bubble<=dataD_next.bubble|(stop_forbranch&&branch);
            //bubble_forbrance=dataD_next.branch|branch;
        end
    end
endmodule
`endif 