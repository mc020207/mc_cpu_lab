`ifndef __MUX_IMM_SRCB_SV
`define __MUX_IMM_SRCB_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module mux_imm_srcb
	import common::*; 
	import pipes::*;
(
    input word_t imm, srcb,
    input control_t ctl,
    output word_t rst
);

    always_comb begin
        if(
            ctl.op == ADDI  || ctl.op == XORI  || ctl.op == ORI   || 
            ctl.op == ANDI  || ctl.op == LUI   || ctl.op == AUIPC ||
            ctl.op == LD    || ctl.op == SD    || ctl.op == SLTI  ||
            ctl.op == SLTIU || ctl.op == SLLI  || ctl.op == SRLI  ||
            ctl.op == SRAI  || ctl.op == ADDIW || ctl.op == SLLIW ||
            ctl.op == SRLIW || ctl.op == SRAIW || ctl.op == LB    ||
            ctl.op == LH    || ctl.op == LW    || ctl.op == LBU   ||
            ctl.op == LHU   || ctl.op == LWU   || ctl.op == SB    ||
            ctl.op == SH    || ctl.op == SW    || ctl.op == CSRRW ||
            ctl.op == CSRRS || ctl.op == CSRRC || ctl.op == CSRRWI||
            ctl.op == CSRRSI|| ctl.op == CSRRCI
        ) begin
            rst = imm;
        end else if(
            ctl.op == ADD  || ctl.op == SUB  || ctl.op == XOR  || 
            ctl.op == OR   || ctl.op == AND  || ctl.op == BEQ  || 
            ctl.op == BNE  || ctl.op == BLT  || ctl.op == BGE  ||
            ctl.op == BLTU || ctl.op == BGEU || ctl.op == SLL  ||
            ctl.op == SLT  || ctl.op == SLTU || ctl.op == SRL  ||
            ctl.op == SRA  || ctl.op == ADDW || ctl.op == SUBW ||
            ctl.op == SLLW || ctl.op == SRLW || ctl.op == SRAW ||
            ctl.op == MUL  || ctl.op == MULW || ctl.op == DIV  ||
            ctl.op == DIVW || ctl.op == DIVU || ctl.op == DIVUW||
            ctl.op == REM  || ctl.op == REMW || ctl.op == REMU ||
            ctl.op == REMUW
        ) begin
            rst = srcb;
        end else if(ctl.op == JAL || ctl.op == JALR) begin 
            rst = 64'd4;
        end else begin
            rst = '0;
        end
    end
	
endmodule

`endif