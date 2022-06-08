`ifndef __FLUSH_SV
`define __FLUSH_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module flush
	import common::*; 
	import pipes::*;
(
	input  decode_op_t    dataE_op, // dataE.ctl.op
	input  u1			  can_jump, // dataE.rst[0] == 1'b1
	input  decode_op_t    dataM_op, // dataM.ctl.op
	input  u1			  has_ex, has_int,
	
    output flush_t        bubble
);

    always_comb begin
		bubble = NOFLUSH;
		if(has_ex || has_int || dataM_op == CSRRW || dataM_op == CSRRS || 
        	dataM_op == CSRRC || dataM_op == CSRRWI || dataM_op == CSRRSI || 
            dataM_op == CSRRCI || dataM_op == MRET) begin 
			bubble = FLUSHW;
		end else if(((dataE_op == BEQ  || dataE_op == BNE || dataE_op == BLT  || 
			dataE_op == BGE || dataE_op == BLTU || dataE_op == BGEU) && can_jump) || 
			dataE_op == JAL || dataE_op == JALR) begin 
			bubble = FLUSHM;
		end
	end

endmodule

`endif
