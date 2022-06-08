`ifndef __CSR_PKG_SV
`define __CSR_PKG_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif
package csr_pkg;
	import common::*;

	// csrs
	parameter u12 CSR_MHARTID = 12'hf14;
	parameter u12 CSR_MIE = 12'h304;
	parameter u12 CSR_MIP = 12'h344;
	parameter u12 CSR_MTVEC = 12'h305;
	parameter u12 CSR_MSTATUS = 12'h300;
	parameter u12 CSR_MSCRATCH = 12'h340;
	parameter u12 CSR_MEPC = 12'h341;
	parameter u12 CSR_SATP = 12'h180;
	parameter u12 CSR_MCAUSE = 12'h342;
	parameter u12 CSR_MCYCLE = 12'hb00;
	parameter u12 CSR_MTVAL = 12'h343;

	typedef struct packed {
		u1 sd;
		logic [MXLEN-2-36:0] wpri1;
		u2 sxl;
		u2 uxl;
		u9 wpri2;
		u1 tsr;
		u1 tw;
		u1 tvm;
		u1 mxr;
		u1 sum;
		u1 mprv;
		u2 xs;
		u2 fs;
		u2 mpp;
		u2 wpri3;
		u1 spp;
		u1 mpie;
		u1 wpri4;
		u1 spie;
		u1 upie;
		u1 mie;
		u1 wpri5;
		u1 sie;
		u1 uie;
	} mstatus_t;

	typedef struct packed {
		u4 mode;
		u16 asid;
		u44 ppn;
	} satp_t;
	
	typedef struct packed {
		u64
		mhartid, // Hardware thread Id, read-only as 0 in this work
		mie,	 // √ Machine Interrupt Enable 它指出处理器目前能处理和必须忽略的中断 Machine interrupt-enable register
		mip,	 // √ Machine interrupt pending 它列出目前正准备处理的中断
		mtvec;	 // √ Machine Trap Vector 它保存发生异常时处理器需要跳转到的地址 Machine trap-handler base address

		mstatus_t
		mstatus; // √ Machine Status 它保存全局中断使能，以及许多其他的状态 Machine status register

		u64
		mscratch, // √ Machine Scratch 它暂时存放一个字大小的数据 Scratch register for machine trap handlers
		mepc,	 // Machine exception program counter
		satp,	 // Supervisor address translation and protection, read-only as 0 in this work
		mcause,  // √ Machine Exception Cause 它指示发生异常的种类 Machine trap cause
		mcycle,  // Counter
		mtval;   // √ Machine Trap Value 它保存了trap的附加信息：地址例外中出错的地址、发生非法指令例外的指令本身，对于其他异常，它的值为 0。
	} csr_regs_t;
	
endpackage

`endif
