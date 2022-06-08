`ifndef __ALU_SV
`define __ALU_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/execute/multi.sv"
`include "pipeline/execute/div.sv"
`include "pipeline/execute/divu.sv"
`else

`endif

module alu
	import common::*;
	import pipes::*;(
	input u1 clk,
	input u64 srca, srcb,
	input alufunc_t alufunc,
	output u64 result,
	input logic choose,
	input contral_t ctl,
	input logic valid,
	output u1 bubble
);
	logic[63:0] a,b,c;
	assign a=srca;
	assign b=srcb;
	logic more;
	//assign more=(ctl.op==ALUI||ctl.op==ALUIW||ctl.op==ALU)? b[5]:1'b0;
	u1 multibubble,divbubble,divububble;
	u64 multiresult,divresult,remresult,divuresult,remuresult;
	logic debug;
	always_comb begin
		c = '0;
		bubble=0;
		debug=0;
		if (ctl.op==CSR||ctl.op==CSRI) begin
			c=a;
		end
		else begin
			unique case(alufunc)
				ALU_ADD: c = a + b;
				ALU_XOR: c = a ^ b;
				ALU_OR : c = a | b; 
				ALU_AND: c = a & b;
				ALU_SUB: c = a - b;
				ALU_LUI: c = b;
				ALU_COMPARE: c ={63'b0, (a==b)};
				ALU_SMALL: c= $signed(a) < $signed(b) ? 64'b1 : 64'b0;
				ALU_SMALLU: c={63'b0,({1'b0,a}<{1'b0,b})};
				ALU_SLT: c= $signed(a) < $signed(b) ? 64'b1 : 64'b0;
				ALU_SLTU: c={63'b0,({1'b0,a}<{1'b0,b})};
				ALU_SLL: c=a<<b[5:0];
				ALU_SRL: c=a>>b[5:0];
				ALU_SRA: c = $signed(a) >>> b[5:0];
				ALU_MULT: begin
					c=multiresult+(srcb[0]?srca:0);
					bubble=~multibubble;
				end
				ALU_DIV: begin
					if (srcb==0) begin
						c='1;
						bubble=0;
					end
					else begin
						if (srca[63]==srcb[63]&&$signed(divresult)>=0||srca[63]!=srcb[63]&&$signed(divresult)<=0) c=divresult;
						else c=0-divresult;
						bubble=~divbubble;
					end
				end
				ALU_REM: begin
					if (srcb==0) begin
						c=srca;
						bubble=0;
					end
					else begin
						c=remresult;
						bubble=~divbubble;
					end
				end
				ALU_DIVU: begin
					if (srcb==0) begin
						c='1;
						bubble=0;
					end
					else begin
						c=divuresult;
						bubble=~divububble;
					end
				end
				ALU_REMU: begin
					if (srcb==0) begin
						c=srca;
						bubble=0;
					end
					else begin
						c=remuresult;
						bubble=~divububble;					
					end
				end
				default: begin
					bubble=0;
				end
			endcase
		end
		if (choose) begin
			unique case (ctl.alufunc)
				ALU_SLL: c = a << b[4:0];
				ALU_SRL: c[31:0] = a[31:0] >> b[4:0];
				ALU_SRA: c[31:0] = $signed(a[31:0]) >>> b[4:0];
				default: begin
				end
			endcase
			result={{32{c[31]}},c[31:0]};
		end
		else begin
			result=c[63:0];
		end
	end
	multi multi(
		.clk,.srca,.srcb,.result(multiresult),
		.data_ok(multibubble),.valid((alufunc==ALU_MULT)&valid)
	);
	div div(
		.clk,.srca,.srcb,.result(divresult),.rem(remresult),
		.data_ok(divbubble),.valid(((alufunc==ALU_DIV||alufunc==ALU_REM)&&srcb!=0)&valid)
	);
	divu divu(
		.clk,.srca,.srcb,.result(divuresult),.rem(remuresult),
		.data_ok(divububble),.valid(((alufunc==ALU_DIVU||alufunc==ALU_REMU)&&srcb!=0)&valid)
	);
endmodule

`endif
