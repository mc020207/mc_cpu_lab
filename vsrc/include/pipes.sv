`ifndef __PIPES_SV
`define __PIPES_SV

`ifdef  VERILATOR
`include "include/common.sv"
`else
`endif

package pipes;
	import common::*;

	// exception
	typedef enum logic [3:0] {
		NOEX, INSTR_ADDR, INSTR_TYPE, LOAD_ADDR, STORE_ADDR, ENV_CALL
	} exception_t;

	// F
	typedef struct packed {
		addr_t 		pc;
		instr_t 	raw_instr; // 指令
		exception_t ex;
	} fetch_data_t;

	// D
	typedef enum logic [7:0] {  // logic 多分配可以，不能少分配，不然编译报错
		UNKNOWN, // 0
		ADDI , XORI , ORI  , ANDI  , SLTI  , SLTIU , SLLI, SRLI, SRAI,
		ADD  , SUB  , XOR  , OR    , AND   , SLL   , SLT , SLTU, SRL , SRA,
		ADDIW, SLLIW, SRLIW, SRAIW , 
		ADDW , SUBW , SLLW , SRLW  , SRAW  , 
		LUI  , AUIPC,
		BEQ  , BNE  , BLT  , BGE   , BLTU  , BGEU  ,
		JAL  , JALR ,
		LD   , LB   , LH   , LW    , LBU   , LHU   , LWU ,
		SD   , SB   , SH   , SW    ,
		MUL  , MULW , DIV  , DIVW  , DIVU  , DIVUW , REM , REMW , REMU, REMUW,
		CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI, MRET, ECALL
	} decode_op_t;

	typedef enum logic [7:0] {
		ALU_UNKNOWN,
		ALU_ADD, ALU_XOR, ALU_OR, ALU_AND, ALU_SUB,
		ALU_ADDW, ALU_SUBW,
		ALU_EQ, ALU_NEQ, ALU_LT, ALU_LTU, ALU_GE, ALU_GEU,
		ALU_SLL, ALU_SRL, ALU_SRA,
		ALU_SLLW, ALU_SRLW, ALU_SRAW,
		ALU_MUL, ALU_MULW, ALU_DIV, ALU_DIVW, ALU_REM, ALU_REMW,
		ALU_CSR
	} alufunc_t;

	typedef enum logic [2:0] {
		R0, R1, R2
	} reg_usage_t;

	typedef struct packed {
		decode_op_t op;	      // 操作
		alufunc_t  	alufunc;  // ALU操作
		logic       regwrite; // 寄存器写信号
		reg_usage_t regusage; // 寄存器使用
	} control_t;

	typedef struct packed {
		addr_t		pc;
		instr_t 	raw_instr; // 指令
		control_t   ctl;
		word_t		imm;
		creg_addr_t dst;
		exception_t ex;
	} decode_data_t;

	// E
	typedef enum u1 { INIT, DOING } state_t;
	typedef struct packed {
		addr_t		pc, pc_nxt;
		instr_t 	raw_instr; // 指令
		control_t   ctl;
		word_t		imm, rst, srca, srcb;
		creg_addr_t dst;
		exception_t ex;
	} execute_data_t;

	// M
	typedef struct packed {
		addr_t		pc;
		instr_t 	raw_instr; // 指令
		control_t   ctl;
		word_t		imm, rst, srca, srcb;
		creg_addr_t dst;
		exception_t ex;
	} memory_data_t;

	// stall	
	typedef enum logic [3:0] {
		NOSTALL, STALLF, STALLE, STALLM, STALLW
	} stall_t;

	// flush
	typedef enum logic [3:0] {
		NOFLUSH, FLUSHM, FLUSHW
	} flush_t;

endpackage

`endif
