`ifndef __PCJUMP_SV
`define __PCJUMP_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module pcjump
	import common::*; 
	import pipes::*;
(
	input  decode_data_t dataD,
	input  word_t        alua,
    output addr_t        pc_nxt
);

	always_comb begin
		if(
			dataD.ctl.op == BEQ  || dataD.ctl.op == JAL || dataD.ctl.op == BNE  ||
			dataD.ctl.op == BLT  || dataD.ctl.op == BGE || dataD.ctl.op == BLTU || 
			dataD.ctl.op == BGEU
		) begin
			pc_nxt = dataD.pc + dataD.imm;
		end else if(dataD.ctl.op == JALR) begin
			pc_nxt = alua + dataD.imm;
		end else begin
			pc_nxt = '0;
		end
	end	
	
endmodule

`endif
