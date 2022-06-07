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
    input logic clk,
    input logic reset,
    input excute_data_t dataE,
    output memory_data_t dataM,
    output dbus_req_t  dreq,
	input  dbus_resp_t dresp,
    output word_t rdM,
    output creg_addr_t dstM,
    output logic writeM,
    output logic bubbleM,stop_formem
);
    memory_data_t dataM_next;
    u3 f3;
    assign f3=dataE.iresp_data[14:12];
    u1 mem_unsigned;
    msize_t msize;
    u1 bubble;
    word_t memwresult,memrresult;
    strobe_t strobe;
    logic dubug;
    assign dubug=(dataE.pc==64'h800152f8);
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
        bubble=0;
        dreq.addr={64{1'b0}};
        dreq.data=0;
        dreq.strobe={8{1'b0}};
        dreq.valid=0;
        dreq.size=msize;
        stop_formem=0;
           unique case(dataE.ctl.op)
                LD: begin
                    dreq.size=msize;
                    dreq.valid=~dataE.bubble;
                    dreq.addr=dataE.result;//64'h40600008;
                    dataM_next.result=memrresult;
                    stop_formem=(~dresp.data_ok)&&(~dataE.bubble);
                    bubble=~dresp.data_ok;
                    dreq.strobe='0;
                end
                SD: begin
                    dreq.size=msize;
                    dreq.data=memwresult;
                    dreq.addr=dataE.result;
                    dreq.valid=~dataE.bubble;
                    stop_formem=(~dresp.data_ok)&&(~dataE.bubble);
                    bubble=~dresp.data_ok;
                    dreq.strobe=strobe;
                end
                default: begin
                    
                end
            endcase 
        //end
    end
    readdata readdata(
        ._rd(dresp.data),.rd(memrresult),.addr(dataE.result[2:0]),
        .msize,.mem_unsigned
    );
    writedata writedata(
        .addr(dataE.result[2:0]),._wd(dataE.rd2),.msize,
        .wd(memwresult),.strobe(strobe)
    );
    assign dataM_next.bubble=dataE.bubble|bubble;
    assign dataM_next.ismem=dataE.ismem;
    assign dataM_next.ctl=dataE.ctl;
    assign dataM_next.pc=dataE.pc;
    assign dataM_next.dst=dataE.dst;
    assign dataM_next.valid=dataE.valid;
    assign dataM_next.iresp_data=dataE.iresp_data;
    assign writeM=dataM_next.ctl.regwrite;
    assign rdM=dataM_next.result;
    assign dstM=dataM_next.dst;
    assign bubbleM=dataM_next.bubble;
    always_ff @( posedge clk ) begin
        if (reset) begin
            dataM<='0;
        end
        else begin
            dataM<=dataM_next;
        end
    end
endmodule
`endif