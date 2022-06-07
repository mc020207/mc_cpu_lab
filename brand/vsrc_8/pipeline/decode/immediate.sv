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
    output u1 bubble,
    input logic bubble1,bubble2
);
    always_comb begin      
        bubble=0;
        rd1=scra;
        rd2=scrb;
        unique case(ctl.op)
            ALU, ALUW: begin
                if (ctl.op==ALUW) begin
                    if (ctl.alufunc==ALU_DIV||ctl.alufunc==ALU_REM)begin
                        rd1={{32{scra[31]}},scra[31:0]};
                        rd2={{32{scrb[31]}},scrb[31:0]};
                    end
                    else if (ctl.alufunc==ALU_DIVU||ctl.alufunc==ALU_REMU) begin
                        rd1={{32{1'b0}},scra[31:0]};
                        rd2={{32{1'b0}},scrb[31:0]};
                    end
                    bubble=bubble1|bubble2;
                end
                else begin
                    rd1=scra;
                    rd2=scrb;
                    bubble=bubble1|bubble2;
                end
            end
            ALUI, ALUIW: begin
                rd2={{52{raw_instr[31]}},raw_instr[31:20]};
                bubble=bubble1;
            end
            LUI : begin
                rd2={{32{raw_instr[31]}},raw_instr[31:12],{12{1'b0}}};
                bubble=bubble1;
            end
            LD: begin
                rd2={{52{raw_instr[31]}},raw_instr[31:20]};
                bubble=bubble1;
            end
            SD: begin
                rd2={{52{raw_instr[31]}},raw_instr[31:25],raw_instr[11:7]};
                bubble=bubble1|bubble2;
            end
            AUIPC: begin
                rd1=pc;
                rd2={{32{raw_instr[31]}},raw_instr[31:12],{12{1'b0}}};
            end
            JAL: begin
                rd1=pc;
                rd2=4;
            end
            JALR: begin
                rd1=pc;
                rd2=4;
            end
            default: begin
                rd1=scra;
                rd2=scrb;
                bubble=bubble1|bubble2;
            end
        endcase 
    end
endmodule

`endif
