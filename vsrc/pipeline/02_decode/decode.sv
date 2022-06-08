`ifndef __DECODE_SV
`define __DECODE_SV

`ifdef  VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/csr_pkg.sv"
`include "pipeline/02_decode/decoder.sv"
`include "pipeline/02_decode/extend.sv"
`else
`endif

module decode
    import common::*;
    import pipes::*;
	import csr_pkg::*;
(
    input  fetch_data_t  dataF,
	input  word_t		 csr_imm,
    output decode_data_t dataD_nxt
);

  	// 指令译码出控制信号
	control_t ctl;
	decoder decoder(
		.raw_instr(dataF.raw_instr),
		.ex(dataF.ex),
		.ctl(ctl),
		.ex_nxt(dataD_nxt.ex)
	);

	// 立即数扩展
	word_t imm;
	extend extend(
		.csr_imm,
		.raw_instr(dataF.raw_instr),
		.imm(imm)
	); 

    assign dataD_nxt.pc   = dataF.pc;
	assign dataD_nxt.raw_instr = dataF.raw_instr;
    assign dataD_nxt.ctl  = ctl;
	assign dataD_nxt.imm  = imm;
    assign dataD_nxt.dst  = dataF.raw_instr[11:7];


endmodule


`endif
