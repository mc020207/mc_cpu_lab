`ifndef _MEMORY_SV
`define _MEMORY_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/memory/readdata.sv"
`include "pipeline/memory/writedata.sv"
`else

`endif
module memory
    import common::*;
    import pipes::*;(
    input logic clk,reset,
    input excute_data_t dataE,
    output memory_data_t dataM,
    output dbus_req_t  dreq,
	input  dbus_resp_t dresp,
    output logic stopm,
    output tran_t tranm,
    input u1 flushde,flushall
);
    memory_data_t dataM_next;
    u3 f3;
    u1 mem_unsigned;
    msize_t msize;
    u1 bubble;
    word_t memwresult,memrresult;
    strobe_t strobe;
    u1 loaderror,storeerror;
    always_comb begin
        unique case (f3)
            3'b000: begin
                msize=MSIZE1;
                mem_unsigned=0;
            end
            3'b100: begin
                msize=MSIZE1;
                mem_unsigned=1;
            end
            3'b001: begin
                msize=MSIZE2;
                mem_unsigned=0;
            end
            3'b101: begin
                msize=MSIZE2;
                mem_unsigned=1;
            end
            3'b010: begin
                msize=MSIZE4;
                mem_unsigned=0;
            end
            3'b110: begin
                msize=MSIZE4;
                mem_unsigned=1;
            end
            default: begin
                msize=MSIZE8;
                mem_unsigned=0;
            end 
        endcase
    end
    always_comb begin
        dataM_next.result=dataE.result;
        dataM_next.addr=dataE.result;
        dataM_next.error=dataE.error;
        bubble=0;
        dreq='0;
        unique case(dataE.ctl.op)
            LD: begin
                dreq.size=msize;
                dreq.valid=dataE.valid&&(dataE.error==0);
                dreq.addr=dataE.result;//64'h40600008;
                dataM_next.result=memrresult;
                dataM_next.error=dataE.valid&&(dataE.error==0)&&loaderror?LOADERROR:dataE.error;
                bubble=~dresp.data_ok;
                dreq.strobe='0;
            end
            SD: begin
                dreq.size=msize;
                dreq.data=memwresult;
                dreq.addr=dataE.result;
                dreq.valid=dataE.valid&&(dataE.error==0);
                dataM_next.error=dataE.valid&&(dataE.error==0)&&storeerror?STOREERROR:dataE.error;
                bubble=~dresp.data_ok;
                dreq.strobe=strobe;
            end
            default: begin
                
            end
        endcase
        if (dataM_next.raw_instr==32'h5006b) begin
            dataM_next.error=NOERROR;
            dataM_next.dst=0;
        end
    end
    readdata readdata(
        ._rd(dresp.data),.rd(memrresult),.addr(dataE.result[2:0]),
        .msize,.mem_unsigned,.error(loaderror)
    );
    writedata writedata(
        .addr(dataE.result[2:0]),._wd(dataE.rd2),.msize,
        .wd(memwresult),.strobe(strobe),.error(storeerror)
    );
    assign f3=dataE.raw_instr[14:12];
    assign dataM_next.pc=dataE.pc;
    assign dataM_next.valid=dataE.valid;
    assign dataM_next.raw_instr=dataE.raw_instr;
    assign dataM_next.ctl=dataE.ctl;
    assign dataM_next.dst=dataE.dst;
    assign dataM_next.csrdst=dataE.csrdst;
    assign dataM_next.csr=dataE.csr;
    assign stopm=bubble&(dataE.valid&&(dataE.error==0));
    assign tranm.dst=(dataE.ctl.regwrite&(dataE.valid&&(dataE.error==0)))?dataE.dst:0;
    assign tranm.data=dataM_next.result;
    assign tranm.ismem=1;
    always_ff @( posedge clk ) begin
        if (reset) begin
            dataM.valid<='0;
        end
        else begin
            if (flushall) dataM.valid<=0;
            else if (flushde) dataM<=dataM;
            else if (bubble&(dataE.valid|(dataE.error==0))) dataM.valid<=0;
            else dataM<=dataM_next;
        end
    end
endmodule
`endif