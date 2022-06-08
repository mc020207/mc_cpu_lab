`ifndef __MUX_RST_MDATA_SV
`define __MUX_RST_MDATA_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module mux_rst_mdata
	import common::*; 
	import pipes::*;
(
    input word_t erst, mdata,
    input control_t ctl,
    output word_t rst
);

    always_comb begin
        if(ctl.op == LD || ctl.op == LB  || ctl.op == LH  ||
           ctl.op == LW || ctl.op == LBU || ctl.op == LHU ||
           ctl.op == LWU) begin 
            rst = mdata;
        end else begin 
            rst = erst;
        end
    end
	
endmodule

`endif