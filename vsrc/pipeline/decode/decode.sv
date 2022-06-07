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
    input logic clk,reset,
    input logic stope,stopm,branch,
    output logic stopd,
    input fetch_data_t dataF,
    output decode_data_t dataD,
    input word_t rd1,rd2,
    output creg_addr_t ra1,ra2,
    input tran_t trane,tranm,tranw
);
    contral_t ctl;
    word_t temp1,temp2;
    logic bubble,bubble1,bubble2;
    decode_data_t dataD_next;
    decoder decoder(
        .raw_instr(dataF.raw_instr),
        .ctl
    );
    select select1(
        .ra(ra1),.rd(rd1),.result(temp1),
        .trane,.tranm,.tranw,
        .bubble(bubble1)
    );
    select select2(
        .ra(ra2),.rd(rd2),.result(temp2),
        .trane,.tranm,.tranw,
        .bubble(bubble2)
    );
    immediate immediate(
        .scra(temp1),.scrb(temp2),
        .pc(dataF.pc),
        .ctl(ctl),
        .raw_instr(dataF.raw_instr),
        .rd1(dataD_next.srca),
        .rd2(dataD_next.srcb),
		.bubble,.bubble1,.bubble2
    );
    assign ra2 = dataF.raw_instr[24:20];
    assign ra1 = dataF.raw_instr[19:15];
    assign dataD_next.valid=dataF.valid;
    assign dataD_next.pc=dataF.pc;
    assign dataD_next.raw_instr=dataF.raw_instr;
    assign dataD_next.ctl=ctl;
    assign dataD_next.dst=dataF.raw_instr[11:7];
    assign dataD_next.rd1=temp1;
    assign dataD_next.rd2=temp2;
    assign stopd=bubble;
    always_ff @( posedge clk ) begin
        if (reset) begin
            dataD.valid<=0;
        end
        else begin
            if (stope|stopm) dataD<=dataD;
            else if (branch|bubble) dataD.valid<=0;
            else dataD<=dataD_next;
        end
    end
endmodule
`endif 