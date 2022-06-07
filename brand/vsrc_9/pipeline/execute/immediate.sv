`ifndef __IMMEDIATE_SV
`define __IMMEDIATE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module immediate
	import common::*;
	import pipes::*;(
    input word_t scrb,scra,
    input u64 pc,
	input contral_t ctl,
    input u32 raw_instr,
    output word_t rd2,rd1,
    input u32 rdenable11, rdenable12, rdenable21, rdenable22,
	output u1 stop,
    output u1 bubble,
);
    always_comb begin
        bubble=((rdenable11!=rdenable12)||(rdenable21!=rdenable22));
        stop=bubble;
        rd1=scra;
        rd2=scrb;
        unique case(ctl.op)
            ALU: begin
                bubble=((rdenable11!=rdenable12)||(rdenable21!=rdenable22));
                stop=bubble;
                rd1=scra;
                rd2=scrb;
            end
            ALUI: begin
                bubble=((rdenable11!=rdenable12));
                stop=bubble;
                unique case (ctl.alufunc)
                    ALU_SLL,ALU_SRL,ALU_SRA: rd2={raw_instr[25:20]}
                    default: 
                endcase
                rd2={{52{raw_instr[31]}},raw_instr[31:20]};
            end
            LUI : begin
                bubble=((rdenable11!=rdenable12));
                stop=bubble;
                rd2={{32{raw_instr[31]}},raw_instr[31:12],{12{1'b0}}};
            end
            LD: begin
                bubble=((rdenable11!=rdenable12));
                stop=bubble;
                rd2={{52{1'b0}},raw_instr[31:20]};
            end
            AUIPC: begin
                rd1=pc;
                rd2={{32{raw_instr[31]}},raw_instr[31:12],{12{1'b0}}};
            end
            
            default: begin
                bubble=((rdenable11!=rdenable12)||(rdenable21!=rdenable22));
                stop=bubble;
                rd1=scra;
                rd2=scrb;
            end
        endcase 
    end
endmodule

`endif
