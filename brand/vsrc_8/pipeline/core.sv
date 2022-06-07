`ifndef __CORE_SV
`define __CORE_SV
`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/regfile/regfile.sv"
`include "pipeline/fetch/fetch.sv"
`include "pipeline/fetch/pcselect.sv"
`include "pipeline/decode/decode.sv"
`include "pipeline/execute/execute.sv"
`include "pipeline/memory/memory.sv"
`else

`endif

module core 
	import common::*;
	import pipes::*;(
	input logic clk, reset,
	output ibus_req_t  ireq,
	input  ibus_resp_t iresp,
	output dbus_req_t  dreq,
	input  dbus_resp_t dresp
);
	u64 pc,pc_nxt;
	fetch_data_t dataF;
	decode_data_t dataD,dataD_copy;
	excute_data_t dataE;
	memory_data_t dataM;
	word_t rdE,rdM;
	creg_addr_t dstE,dstM;
	logic ismemE,bubbleE,bubbleM,writeM;
	creg_addr_t ra1,ra2;
	word_t rd1,rd2;
	u1 stop;//stop the programe and waiting
	u64 pc_stop;
	u1 branch;
	u1 stop_forbranch,stop_forfetch,stop_formem,stop_forexe;
	u64 jump;
	u1 move;
	pcselect pcselect(
		.reset,
		.pcplus4(pc + 4),
		.pc_selected(pc_nxt),
		.jump,
		.branch,
		.stop,
		.pc_stop(pc),
		.stop_forbranch,.stop_forfetch,.stop_formem,.stop_forexe,
		.move
	);
	fetch fetch(
		.clk,.reset,
		.dataF(dataF),
		//.raw_instr(raw_instr),
		.pc(pc),
		.pc_nxt,
		.ireq,
		.iresp,
		.stop_forbranch,
		.branch,.stop_forfetch,.stop_formem,.move
	);

	decode decode (
		.clk,.reset,
		.dataF,
		.dataD,
		.ra1,.ra2,.rd1,.rd2,
		.stop,.pc_stop,
		.stop_forbranch,
		.branch,.rdE(dataE.result),.rdM(dataM.result),
		.dstE(dataE.dst),.dstM(dataM.dst),.dstD(dataD.dst),
		.validD((~dataD.bubble)&dataD.valid&dataD.ctl.regwrite),
		.validE((~dataE.bubble)&dataE.valid&dataE.ctl.regwrite),
		.validM((~dataM.bubble)&dataM.valid&dataM.ctl.regwrite),
		.ismemE(dataE.ctl.op==LD),
		.stop_formem,.stop_forexe
	);
	assign dataD_copy=dataD;
	regfile regfile(
		.clk, .reset,
		.ra1,
		.ra2,
		.rd1,
		.rd2,
		.wvalid(dataM.ctl.regwrite&&~dataM.bubble),
		.wa(dataM.dst),
		.wd(dataM.result)
	);
	execute execute(
		.clk,.reset,
		.dataD,
		.dataE,
		.branch,
		.jump,
		.pc,
		.stop_formem,.stop_forexe
	);
	memory memory(
		.clk,.reset,
		.dataE(dataE),
		.dataM(dataM),
		.dreq(dreq),
		.dresp(dresp),
		.stop_formem
	);
	logic skip;
	assign skip=(dataM.ctl.op == SD || dataM.ctl.op == LD) && dataM.addr[31] == 0;
	logic debug;
	assign debug=(dataM.pc==64'h800166c0);
`ifdef VERILATOR
	DifftestInstrCommit DifftestInstrCommit(
		.clock              (clk),
		.coreid             (0),
		.index              (0),
		.valid              (~reset&dataM.valid&~dataM.bubble),
		.pc                 (dataM.pc),
		.instr              (dataM.iresp_data),
		.skip               (skip),
		.isRVC              (0),
		.scFailed           (0),
		.wen                (dataM.ctl.regwrite),
		.wdest              ({3'b0,dataM.dst}),
		.wdata              (dataM.result)
	);
	      
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
	      
	DifftestTrapEvent DifftestTrapEvent(
		.clock              (clk),
		.coreid             (0),
		.valid              (0),
		.code               (0),
		.pc                 (0),
		.cycleCnt           (0),
		.instrCnt           (0)
	);
	      
	DifftestCSRState DifftestCSRState(
		.clock              (clk),
		.coreid             (0),
		.priviledgeMode     (3),
		.mstatus            (0),
		.sstatus            (0),
		.mepc               (0),
		.sepc               (0),
		.mtval              (0),
		.stval              (0),
		.mtvec              (0),
		.stvec              (0),
		.mcause             (0),
		.scause             (0),
		.satp               (0),
		.mip                (0),
		.mie                (0),
		.mscratch           (0),
		.sscratch           (0),
		.mideleg            (0),
		.medeleg            (0)
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