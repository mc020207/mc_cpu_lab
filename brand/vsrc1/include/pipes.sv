`ifndef __PIPES_SV
`define __PIPES_SV
`ifdef VERILATOR
`include "include/common.sv"
`endif
package pipes;
	import common::*;
/* Define instrucion decoding rules here */

// parameter F7_RI = 7'bxxxxxxx;
parameter F7_ALUI=   7'b0010011;
parameter F7_ALU=    7'b0110011;
parameter F7_ALUW=	 7'b0111011;
parameter F7_ALUIW=	 7'b0011011;
parameter F7_LUI=    7'b0110111;
parameter F7_JAL=    7'b1101111;
parameter F7_BRANCH= 7'b1100011;
parameter F7_LD=     7'b0000011;
parameter F7_SD=     7'b0100011;
parameter F7_AUIPC=  7'b0010111;
parameter F7_JALR=   7'b1100111;
parameter F7_CSR=	 7'b1110011;

parameter F3_ADD=3'b000;
parameter F3_XOR=3'b100;
parameter F3_OR=3'b110;
parameter F3_AND=3'b111;
parameter F3_BEQ=3'b000;
parameter F3_BNE=3'b001;
parameter F3_BLT=3'b100;
parameter F3_DIV=3'b100;
parameter F3_REM=3'b110;
parameter F3_DIVU=3'b101;
parameter F3_REMU=3'b111;
parameter F3_BGE=3'b101;
parameter F3_BLTU=3'b110;
parameter F3_BGEU=3'b111;
parameter F3_SLT=3'b010;
parameter F3_SLTU=3'b011;
parameter F3_SLL=3'b001;
parameter F3_SR=3'b101;
parameter F3_CSRRC=3'b011;
parameter F3_CSRRCI=3'b111;
parameter F3_CSRRS=3'b010;
parameter F3_CSRRSI=3'b110;
parameter F3_CSRRW=3'b001;
parameter F3_CSRRWI=3'b101;
parameter F3_ECALL=3'b000;


parameter F7_FIRST_ADD=7'b0000000;
parameter F7_FIRST_SUB=7'b0100000;
parameter F7_FIRST_MUL=7'b0000001;
parameter F7_FIRST_ECALL=7'b0000000;
parameter F7_FIRST_MRET=7'b0011000;

/* Define pipeline structures here */
typedef enum logic[5:0] {
	UNKNOWN,ALUI,ALU,ALUW,ALUIW,LUI,JAL,BEQ,LD,SD,AUIPC,JALR,BNE,BLT,BGE,BLTU,BGEU,CSR,CSRI,ECALL,MRET
} decode_op_t;
typedef enum logic [4:0] {
	NOTALU,ALU_ADD,ALU_XOR,ALU_OR,ALU_AND,ALU_SUB,ALU_LUI,ALU_COMPARE,ALU_SMALL,ALU_SMALLU,ALU_SLT,
	ALU_SLTU,ALU_SLL,ALU_SRL,ALU_SRA,ALU_MULT,ALU_DIV,ALU_REM,ALU_DIVU,ALU_REMU,ALU_CSRC,ALU_CSRS,ALU_CSRW,ALU_ECALL,ALU_MRET
} alufunc_t;
typedef struct packed {
	u1 ismem;
	creg_addr_t dst;// 不是写操作该数置为0
	word_t data;
} tran_t;
typedef struct packed {
	decode_op_t op;
	alufunc_t alufunc;
	u1 regwrite;
} contral_t;
typedef struct packed {
	u1 valid;
	u32 raw_instr;
	u64 pc;
	u1 error;
} fetch_data_t;
typedef struct packed {
	u1 valid;
	u64 pc;
	u32 raw_instr;
	contral_t ctl;
	creg_addr_t dst;
	u12 csrdst;
	word_t srca, srcb;	
	word_t rd2,rd1;
	word_t csra,csrb;
	u1 error;
} decode_data_t;
typedef struct packed {
	u64 pc;
	u1 valid;
	u32 raw_instr;
	contral_t ctl;
	creg_addr_t dst;
	word_t rd2;
	word_t result;
	u12 csrdst;
	word_t csrresult;
	u1 error;
} excute_data_t;
typedef struct packed {
	u64 pc;
	u1 valid;
	u32 raw_instr;
	contral_t ctl;
	creg_addr_t dst;
	word_t result;
	word_t addr;
	u12 csrdst;
	word_t csrresult;
	u1 error;
} memory_data_t;
endpackage

`endif
