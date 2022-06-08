`ifndef __CORE_SV
`define __CORE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/csr_pkg.sv"
`include "pipeline/regfile/regfile.sv"
`include "pipeline/csr/csr.sv"
`include "pipeline/hazard/hazard.sv"
`include "pipeline/01_fetch/fetch.sv"
`include "pipeline/01_fetch/regfd.sv"
`include "pipeline/02_decode/decode.sv"
`include "pipeline/02_decode/regde.sv"
`include "pipeline/03_execute/execute.sv"
`include "pipeline/03_execute/regem.sv"
`include "pipeline/04_memrw/memrw.sv"
`include "pipeline/04_memrw/regmw.sv"
`include "pipeline/05_writeback/writeback.sv"
`else
`endif

module core 
	import common::*;
	import pipes::*;
	import csr_pkg::*;
(
	// 时钟信号与复位信号
	input  logic clk, reset,

	// 指令内存接口
	output ibus_req_t  ireq,
	input  ibus_resp_t iresp,

	// 数据内存接口
	output dbus_req_t  dreq,
	input  dbus_resp_t dresp,
	input logic trint, swint, exint
);

/* 五级流水线 */
/* TODO: Add your pipeline here. */
	
	/* 信号声明 */
	// 各阶段的数据
	fetch_data_t   dataF, dataF_nxt;
	decode_data_t  dataD, dataD_nxt;
	execute_data_t dataE, dataE_nxt;
	memory_data_t  dataM, dataM_nxt;
	// 寄存器读写端口、数据
	word_t		   rd1, rd2;
	word_t		   wd;
	// 冒险
	flush_t 	   bubble;     // 冲刷
	stall_t		   stop; 	   // 阻塞
	word_t		   alua, alub; // 转发
	// 提交
	u1			   commit_valid, commit_skip;
	// 总线
	u1 ibus_not_busy, dbus_not_busy;
	// 乘除法
	u1 			   done;
	// 中断与异常
	u1			   has_ex, invalidate_mem, has_int;
	addr_t		   ex_pc;
	// csr寄存器
	word_t         csr_imm;

	/* hazard */
	hazard hazard(
		.dataD,
		.dataE,
		.dataM,
		.done,
		.rd1,
		.rd2,
		.ibus_not_busy,
		.dbus_not_busy,
		.has_ex,
		.has_int,
		.bubble,
		.stop,
		.alua, .alub
	);

	/* regfile寄存器 */
	regfile regfile(
		.clk,
		.reset,
		.ra1(dataD.raw_instr[19:15]),
		.ra2(dataD.raw_instr[24:20]),
		.rd1,
		.rd2,
		.wvalid(dataM.ctl.regwrite),
		.wa(dataM.dst),
		.wd
	);

	/* csr寄存器 */
	csr csr_inst(
		.clk,
		.reset,
		.ra(dataF.raw_instr[31:20]),
		.dataM,
		.stop,
		.trint,
		.swint,
		.exint,
		.has_ex,
		.has_int,
		.ex_pc,
		.csr_imm
	);

	/* F阶段 */
	// 由指令寄存器与pc得到dataF_nxt
	fetch fetch(
		.clk,
		.reset,
		.bubble,
		.stop,
		.iresp,
		.dataE, // 跳转
		.ireq,
		.ex_pc,
		.dataF_nxt,
		.ibus_not_busy
	);
	// 寄存器IF/ID
	regfd regfd(
		.clk, 
		.reset,
		.bubble,
		.stop,
		.dataF_nxt,
		.dataF
	);

	/* D阶段 */
	// 由dataF得到dataD_nxt
	decode decode(
		.csr_imm,
		.dataF,
		.dataD_nxt
	);
	// 寄存器DF/EX
	regde regde(
    	.clk,
		.reset,
		.bubble,
		.stop,
   		.dataD_nxt,
    	.dataD
	);

	/* E阶段 */
	// 由dataD得到dataE_nxt
	execute execute(
		.clk,
		.reset,
		.dataD,
		.alua,
		.alub,
		.dataE,
		.bubble,
		.dataE_nxt,
		.done
	);
	// 寄存器EX/MEM
	regem regem(
    	.clk,
		.reset,
		.bubble,
		.stop,
   		.dataE_nxt,
		.ibus_not_busy,
		.dbus_not_busy,
    	.dataE
	);

	/* M阶段 */
	// 由dataE得到dataM_nxt
	memrw memrw(
		.dresp,
		.dataE,
		.dreq,
		.invalidate_mem,
		.dataM_nxt,
		.dbus_not_busy
	);
	// 寄存器MEM/WB
	regmw regmw(
    	.clk,
		.reset,
		.bubble,
		.stop,
		.dataM_nxt,
		.ibus_not_busy,
		.dbus_not_busy,
    	.dataM
	);

	/* W阶段 */
	// 由dataM得到dataW_nxt
	writeback writeback(
		.dataM,
		.trint,
		.swint,
		.exint,
		.regs_mstatus_mie(csr_inst.regs.mstatus.mie),
		.regs_mie(csr_inst.regs.mie),
		.wd,
		.invalidate_mem,
		.has_ex,
		.has_int,
		.ex_pc
	);

	// 提交
	assign commit_valid = (
		dataM.ctl.regwrite   || dataM.ctl.op == SD   || dataM.ctl.op == SB   || 
		dataM.ctl.op == SH   || dataM.ctl.op == SW   || dataM.ctl.op == BEQ  ||
		dataM.ctl.op == BNE  || dataM.ctl.op == BLT  || dataM.ctl.op == BGE  ||
		dataM.ctl.op == BLTU || dataM.ctl.op == BGEU || dataM.ctl.op == MRET ||
		dataM.raw_instr == 32'h5006b
	) && (stop != STALLW);
	
	assign commit_skip = (
		(dataM.ctl.op == LD  || dataM.ctl.op == SD  || dataM.ctl.op == SB  || 
		dataM.ctl.op == SH   || dataM.ctl.op == SW  || dataM.ctl.op == LB  || 
		dataM.ctl.op == LH   || dataM.ctl.op == LW  || dataM.ctl.op == LBU ||
		dataM.ctl.op == LHU  || dataM.ctl.op == LWU) && dataM.rst[31] == 0
	);

/* 接入Verilator仿真 */

	// 将CPU接入Verilator Difftest的仿真接口
	// 需要例化三个模块(所给框架中已例化好，需要接线)

	`ifdef VERILATOR

	// 首先是当前周期提交的指令
	// 提交的时候是W阶段，需要将dataW里的信息填入
	DifftestInstrCommit DifftestInstrCommit(
		.clock              (clk),
		.coreid             (0), // (不改)
		.index              (0), // (前4个lab不改)多发射时，例化多个该模块
		.valid              (commit_valid), // 无提交(或提交的指令是flush导致的bubble时，为0)
		.pc                 (dataM.pc), // 这条指令的pc，因此pc需要从dataF一路传到dataW
		.instr              (dataM.raw_instr), // (不改)这条指令的内容
		.skip               (commit_skip), // 提交的是一条内存读写指令，且这部分内存属于设备(addr[31]==0)时，skip为1
		.isRVC              (0), // (前4个lab不改)
		.scFailed           (0), // (前4个lab不改)
		.wen                (dataM.ctl.regwrite), // 这条指令是否写入通用寄存器，1 bit 
		.wdest              ({3'b0, dataM.dst}), // 写入哪个寄存器
		.wdata              (wd)  // 写入的值
	);
	
	// 这个周期的指令提交后，通用寄存器的内容(已连接好)
	DifftestArchIntRegState DifftestArchIntRegState (
		.clock              (clk),
		.coreid             (0),
		.gpr_0              (regfile.regs_nxt[0]),
		.gpr_1              (regfile.regs_nxt[1]),
		.gpr_2              (regfile.regs_nxt[2]),
		.gpr_3              (regfile.regs_nxt[3]),
		.gpr_4              (regfile.regs_nxt[4]),
		.gpr_5              (regfile.regs_nxt[5]),
		.gpr_6              (regfile.regs_nxt[6]),
		.gpr_7              (regfile.regs_nxt[7]),
		.gpr_8              (regfile.regs_nxt[8]),
		.gpr_9              (regfile.regs_nxt[9]),
		.gpr_10             (regfile.regs_nxt[10]),
		.gpr_11             (regfile.regs_nxt[11]),
		.gpr_12             (regfile.regs_nxt[12]),
		.gpr_13             (regfile.regs_nxt[13]),
		.gpr_14             (regfile.regs_nxt[14]),
		.gpr_15             (regfile.regs_nxt[15]),
		.gpr_16             (regfile.regs_nxt[16]),
		.gpr_17             (regfile.regs_nxt[17]),
		.gpr_18             (regfile.regs_nxt[18]),
		.gpr_19             (regfile.regs_nxt[19]),
		.gpr_20             (regfile.regs_nxt[20]),
		.gpr_21             (regfile.regs_nxt[21]),
		.gpr_22             (regfile.regs_nxt[22]),
		.gpr_23             (regfile.regs_nxt[23]),
		.gpr_24             (regfile.regs_nxt[24]),
		.gpr_25             (regfile.regs_nxt[25]),
		.gpr_26             (regfile.regs_nxt[26]),
		.gpr_27             (regfile.regs_nxt[27]),
		.gpr_28             (regfile.regs_nxt[28]),
		.gpr_29             (regfile.regs_nxt[29]),
		.gpr_30             (regfile.regs_nxt[30]),
		.gpr_31             (regfile.regs_nxt[31])
	);
	
	// (lab4的内容，前面的lab可以不管)这个周期的指令提交后，系统寄存器的内容
	DifftestCSRState DifftestCSRState(
			.clock              (clk),
			.coreid             (0),
			.priviledgeMode     (csr_inst.mode_nxt),
			.mstatus            (csr_inst.regs_nxt.mstatus),
			.sstatus            (csr_inst.regs_nxt.mstatus & 64'h800000030001e000),
			.mepc               (csr_inst.regs_nxt.mepc),
			.sepc               (0),
			.mtval              (csr_inst.regs_nxt.mtval),
			.stval              (0),
			.mtvec              (csr_inst.regs_nxt.mtvec),
			.stvec              (0),
			.mcause             (csr_inst.regs_nxt.mcause),
			.scause             (0),
			.satp               (0),
			.mip                (csr_inst.regs_nxt.mip),
			.mie                (csr_inst.regs_nxt.mie),
			.mscratch           (csr_inst.regs_nxt.mscratch),
			.sscratch           (0),
			.mideleg            (0),
			.medeleg            (0)
	);

	DifftestTrapEvent DifftestTrapEvent(
		.clock              (clk),
		.coreid             (0),
		.valid              (0),
		.code               (0),
		.pc                 (0),
		.cycleCnt           (0),
		.instrCnt           (0)
	);

	DifftestArchFpRegState DifftestArchFpRegState(
		.clock              (clk),
		.coreid             (0),
		.fpr_0              (0),
		.fpr_1              (0),
		.fpr_2              (0),
		.fpr_3              (0),
		.fpr_4              (0),
		.fpr_5              (0),
		.fpr_6              (0),
		.fpr_7              (0),
		.fpr_8              (0),
		.fpr_9              (0),
		.fpr_10             (0),
		.fpr_11             (0),
		.fpr_12             (0),
		.fpr_13             (0),
		.fpr_14             (0),
		.fpr_15             (0),
		.fpr_16             (0),
		.fpr_17             (0),
		.fpr_18             (0),
		.fpr_19             (0),
		.fpr_20             (0),
		.fpr_21             (0),
		.fpr_22             (0),
		.fpr_23             (0),
		.fpr_24             (0),
		.fpr_25             (0),
		.fpr_26             (0),
		.fpr_27             (0),
		.fpr_28             (0),
		.fpr_29             (0),
		.fpr_30             (0),
		.fpr_31             (0)
	);
	
	`endif

endmodule

`endif