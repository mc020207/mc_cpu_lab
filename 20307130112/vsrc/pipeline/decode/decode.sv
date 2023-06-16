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
    input tran_t trane,tranm,tranw,
    output u12 csrra,
    input word_t csrrd,
    input u1 flushde
);
    contral_t ctl;
    word_t temp1,temp2;
    logic bubble,bubblet,bubble1,bubble2;//bubblecsr,bubblealu;
    decode_data_t dataD_next;
    u1 error;
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
    word_t srcb;
    immediate immediate(
        .scra(temp1),.scrb(temp2),
        .pc(dataF.pc),
        .ctl(ctl),
        .csr(csrrd),
        .raw_instr(dataF.raw_instr),
        .rd1(dataD_next.srca),
        .rd2(srcb),
		.bubble(bubblet),.bubble1,.bubble2
    );
    assign error=(ctl.op==UNKNOWN);
    assign bubble=bubblet&(dataF.valid&(dataF.error==NOERROR));
    assign csrra=dataF.raw_instr[31:20];
    assign ra2 = dataF.raw_instr[24:20];
    assign ra1 = dataF.raw_instr[19:15];
    assign dataD_next.valid=dataF.valid;
    assign dataD_next.pc=dataF.pc;
    assign dataD_next.raw_instr=dataF.raw_instr;
    assign dataD_next.ctl=ctl;
    assign dataD_next.dst=dataF.raw_instr[11:7];
    assign dataD_next.rd1=temp1;
    assign dataD_next.rd2=temp2;
    assign dataD_next.csrdst=csrra;
    assign dataD_next.srcb=srcb;
    assign dataD_next.csr=srcb;
    assign dataD_next.error=(dataF.error==NOERROR&&error)?DECODEERRRE:dataF.error;
    assign stopd=bubble;
    always_ff @( posedge clk ) begin
        if (reset) begin
            dataD.valid<=0;
        end
        else begin
            if (flushde) dataD.valid<=0;
            else if (stope|stopm) dataD<=dataD;
            else if (branch|bubble) dataD.valid<=0;
            else dataD<=dataD_next;
        end
    end
endmodule
`endif 