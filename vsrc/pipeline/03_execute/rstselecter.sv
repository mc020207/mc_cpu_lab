`ifndef __RSTSELECTER_SV
`define __RSTSELECTER_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module rstselecter
	import common::*; 
	import pipes::*;
(
    input  control_t ctl,
    input  word_t    c_alu, c_div, c_mul,

    output word_t    c
);

    always_comb begin 
        if(ctl.op == MUL || ctl.op == MULW) begin 
            c = c_mul;
        end else if(ctl.op == DIV || ctl.op == DIVU || ctl.op == DIVW || ctl.op == DIVUW || 
                    ctl.op == REM || ctl.op == REMU || ctl.op == REMW || ctl.op == REMUW) begin 
            c = c_div;
        end else begin 
            c = c_alu;
        end
    end

endmodule

`endif