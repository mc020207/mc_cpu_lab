`ifndef __PCUPDATE_SV
`define __PCUPDATE_SV

`ifdef  VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else
`endif

module pcupdate
    import common::*;
    import pipes::*;
(
    input  u1      clk, reset, 
	input  stall_t stop,
    input  addr_t  pc_nxt,
    output addr_t  pc
);
    
    always_ff @( posedge clk ) begin
		if (reset) begin
			pc <= 64'h8000_0000; // 手册要求
		end else begin
			if(stop == STALLW || stop == STALLM || stop == STALLE || stop == STALLF) begin
				pc <= pc;
			end else begin
				pc <= pc_nxt; // pc_nxt;
			end
		end
	end

endmodule


`endif