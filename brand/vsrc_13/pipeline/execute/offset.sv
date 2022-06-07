`ifndef __OFFSET_SV
`define __OFFSET_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/execute/alu.sv"
`else

`endif

module offset
	import common::*;
	import pipes::*;(
    input u1 valid,
    input u32 raw_instr,
    input contral_t ctl,
    input word_t choose,
    output u64 jump,
    output u1 branch,
    input  u64 pc,
    input u64 jumppc
);
    always_comb begin 
        jump=pc;
        branch=0;
        unique case(ctl.op)
            JAL : begin
                jump=pc+{{43{raw_instr[31]}},{raw_instr[31]},{raw_instr[19:12]},{raw_instr[20]},{raw_instr[30:21]},{1'b0}};
                branch=valid;
            end
            BEQ , BLT,BLTU:begin
                if (choose==1) begin
                    jump=pc+{{51{raw_instr[31]}},{raw_instr[31]},{raw_instr[7]},{raw_instr[30:25]},{raw_instr[11:8]},{1'b0}};
                    branch=valid;
                end
                else begin
                    jump=pc+4;
                    branch=valid;
                end
            end
            BNE ,BGE , BGEU: begin
                if (choose==0) begin
                    jump=pc+{{51{raw_instr[31]}},{raw_instr[31]},{raw_instr[7]},{raw_instr[30:25]},{raw_instr[11:8]},{1'b0}};
                    branch=valid;
                end
                else begin
                    jump=pc+4;
                    branch=valid;
                end
            end
            JALR:begin
                jump=jumppc;
                branch=valid;
            end
            default: begin
                
            end
        endcase 
    end
endmodule

`endif
