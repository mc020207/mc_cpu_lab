`ifndef __MUX_PC_SRCA_SV
`define __MUX_PC_SRCA_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module mux_pc_srca
	import common::*; 
	import pipes::*;
(
    input addr_t pc,
    input word_t srca,
    input control_t ctl,
    output word_t rst
);

    always_comb begin
        if(ctl.op == LUI) begin
            rst = '0;
        end else if(ctl.op == AUIPC || ctl.op == JAL || ctl.op == JALR) begin
            rst = pc;
        end else begin
            rst = srca;
        end
    end
	
endmodule

`endif
