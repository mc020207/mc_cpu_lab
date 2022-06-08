`ifndef __ALU_SV
`define __ALU_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module alu
	import common::*; 
	import pipes::*;
(
	input word_t a, b,
	input control_t ctl,
	output word_t c
);

	u64 tmp1;
	u32 tmp2;

	always_comb begin
		tmp1 = '0;
		tmp2 = '0;
		c = '0;
		unique case(ctl.alufunc)
			ALU_ADD: begin 
				c = a + b;
			end
			ALU_XOR: begin 
				c = a ^ b;
			end
			ALU_OR: begin 
				c = a | b;
			end
			ALU_AND: begin 
				c = a & b;
			end
			ALU_SUB: begin 
				c = a - b;
			end
			ALU_EQ:  begin
				c = {63'b0, (a == b)};
			end
			ALU_NEQ: begin 
				c = {63'b0, (a != b)};
			end
			ALU_LT:  begin
				c = {63'b0, ($signed(a) < $signed(b))};
			end
			ALU_GE:  begin
				c = {63'b0, ($signed(a) >= $signed(b))};
			end
			ALU_LTU: begin 
				c = {63'b0, (a < b)};
			end
			ALU_GEU: begin
				c = {63'b0, (a >= b)};
			end
			ALU_SLL: begin 
				c = a << b[5:0];
			end
			ALU_SRL: begin
				c = a >> b[5:0];
			end
			ALU_SRA: begin
				c = $signed(a) >>> b[5:0];
			end
			ALU_ADDW: begin 
				tmp1 = a + b;
				c   = {{32{tmp1[31]}} , tmp1[31:0]};
			end
			ALU_SUBW: begin 
				tmp1 = a - b;
				c   = {{32{tmp1[31]}} , tmp1[31:0]};
			end
			ALU_SLLW: begin 
				tmp2 = a[31:0] << b[4:0];
				c   = {{32{tmp2[31]}} , tmp2};
			end
			ALU_SRLW: begin
				tmp2 = a[31:0] >> b[4:0];
				c   = {{32{tmp2[31]}} , tmp2};
			end
			ALU_SRAW: begin
				tmp2 = $signed(a[31:0]) >>> b[4:0];
				c   = {{32{tmp2[31]}} , tmp2};
			end
			ALU_CSR: begin 
				c = b;
			end
			default: begin
			end
		endcase
	end
	
endmodule

`endif
