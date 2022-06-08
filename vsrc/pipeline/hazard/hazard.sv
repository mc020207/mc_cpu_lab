`ifndef __HAZARD_SV
`define __HAZARD_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/hazard/flush.sv"
`include "pipeline/hazard/stall.sv"
`include "pipeline/hazard/forward.sv"
`else

`endif

module hazard
	import common::*; 
	import pipes::*;
(
	input  decode_data_t  dataD,
    input  execute_data_t dataE,
	input  memory_data_t  dataM,
	input  u1			  done,
	input  word_t		  rd1, rd2,
	input  u1  			  has_ex, has_int,
	input  u1             ibus_not_busy, dbus_not_busy,

    output flush_t        bubble,
	output stall_t		  stop,
    output word_t         alua, alub
);

	flush flush(
		.dataE_op(dataE.ctl.op),
		.can_jump(dataE.rst[0]),
		.dataM_op(dataM.ctl.op),
		.has_ex,
		.has_int,
		.bubble
	);

	stall stall(
		.dataE,
		.dataD,
		.ibus_not_busy, 
		.dbus_not_busy,
		.bubble,
		.done,
		.stop
	);

	forward forward(
		.dataE,
		.dataM,
		.dataD,
		.rd1,
		.rd2,
		.alua,
		.alub
	);
	
endmodule

`endif
