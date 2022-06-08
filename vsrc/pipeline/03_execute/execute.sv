`ifndef __EXECUTE_SV
`define __EXECUTE_SV

`ifdef  VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/csr_pkg.sv"
`include "pipeline/03_execute/mux_pc_srca.sv"
`include "pipeline/03_execute/mux_imm_srcb.sv"
`include "pipeline/03_execute/alu.sv"
`include "pipeline/03_execute/multiplier.sv"
`include "pipeline/03_execute/divider.sv"
`include "pipeline/03_execute/rstselecter.sv"
`include "pipeline/03_execute/pcjump.sv"
`else
`endif

module execute
    import common::*;
    import pipes::*;
	import csr_pkg::*;
(
	input  u1 			  clk, reset,
    input  decode_data_t  dataD,
	input  word_t		  alua, alub,
	input  execute_data_t dataE,
	input  flush_t		  bubble,

    output execute_data_t dataE_nxt,
	output u1			  done
);

	// 多路选择+ALU
	u1 done_mul, done_div;
	word_t a, b, c_alu, c_mul, c_div, c;
	mux_pc_srca mux_pc_srca(
		.pc(dataD.pc),
		.srca(alua),
		.ctl(dataD.ctl),
		.rst(a)
	);
	mux_imm_srcb mux_imm_srcb(
		.imm(dataD.imm),
		.srcb(alub),
		.ctl(dataD.ctl),
		.rst(b)
	);
	alu alu(
		.a,
		.b,
		.ctl(dataD.ctl),
		.c(c_alu)
	);
	multiplier multiplier(
		.clk,
		.reset,
		.a,
		.b,
		.ctl(dataD.ctl),
		.dataE,
		.dataD,
		.bubble,
		.done_mul,
		.c_mul
	);
	divider divider(
		.clk,
		.reset,
		.a,
		.b,
		.ctl(dataD.ctl),
		.dataE,
		.dataD,
		.bubble,
		.done_div,
		.c_div
	);
	rstselecter rstselecter(
		.ctl(dataD.ctl),
		.c_alu,
		.c_div,
		.c_mul,
		.c
	);
	assign done = ((done_mul == 1'b1) && (done_div == 1'b1));

	// 跳转和分支指令计算
	addr_t pc_nxt;
	pcjump pcjump(
		.dataD,
		.alua,
		.pc_nxt
	);

    assign dataE_nxt.pc     = dataD.pc;
	assign dataE_nxt.raw_instr = dataD.raw_instr;
    assign dataE_nxt.ctl    = dataD.ctl;
	assign dataE_nxt.rst    = c;
	assign dataE_nxt.srca   = alua;
    assign dataE_nxt.srcb   = alub;
	assign dataE_nxt.imm    = dataD.imm;
	assign dataE_nxt.pc_nxt = pc_nxt;
    assign dataE_nxt.dst    = dataD.dst;
	assign dataE_nxt.ex		= dataD.ex;

endmodule


`endif
