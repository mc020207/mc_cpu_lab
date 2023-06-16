`ifndef __CSR_SV
`define __CSR_SV


`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/regfile/csr_pkg.sv"
`else
`endif

module csr
	import common::*;
	import csr_pkg::*;
	import pipes::*;(
	input logic clk, reset,
	input u12 ra,
	output u64 rd,
	output u64 csrpc,
	input memory_data_t dataM,
	input logic trint, swint,exint,
	input logic stopm,stopf,
	output logic flushde,flushall
);
	csr_regs_t regs, regs_nxt;
	u2 mode, mode_nxt;
	logic interupt,error;
	word_t csrresult;
	u1 debug;
	assign debug=(dataM.pc==64'h80008048);
	assign error=dataM.valid&&(dataM.error!=0||dataM.ctl.op==ECALL);
	assign interupt=dataM.valid&&regs.mstatus.mie &&((trint&&regs.mie[7])||(swint&&regs.mie[3])||(exint&&regs.mie[11]));
	always_ff @(posedge clk) begin
		if (reset) begin
			regs <= '0;
			regs.mcause[1] <= 1'b1;
			regs.mepc[31] <= 1'b1;
			mode<=2'd3;
		end else begin
			regs <= regs_nxt;
			mode<=mode_nxt;
		end
	end

	// read
	always_comb begin
		rd = '0;
		unique case(ra)
			CSR_MIE: rd = regs.mie;
			CSR_MIP: rd = regs.mip;
			CSR_MTVEC: rd = regs.mtvec;
			CSR_MSTATUS: rd = regs.mstatus;
			CSR_MSCRATCH: rd = regs.mscratch;
			CSR_MEPC: rd = regs.mepc;
			CSR_MCAUSE: rd = regs.mcause;
			CSR_MCYCLE: rd = regs.mcycle;
			CSR_MTVAL: rd = regs.mtval;
			default: begin
				rd = '0;
			end
		endcase
	end

	always_comb begin
		mode_nxt=mode;
		regs_nxt=regs;
		csrresult=0;
		flushde=0;
		flushall=0;
		csrpc='0;
		regs_nxt.mcycle =regs.mcycle+1;
		if (~stopm&&error&&dataM.valid) begin
			flushde=1;
			if (~stopf) begin
				flushall=1;
				mode_nxt=2'd3;
				csrpc=regs_nxt.mtvec;
				regs_nxt.mepc=dataM.pc;
				regs_nxt.mcause[63:0]=64'b0;
				unique case(dataM.error)
					FETCHERROR: regs_nxt.mcause[62:0]=63'd0;
                    DECODEERRRE: regs_nxt.mcause[62:0]=63'd2;
                    LOADERROR: regs_nxt.mcause[62:0]=63'd4;
                    STOREERROR: regs_nxt.mcause[62:0]=63'd6;
					default : begin
						if (mode==2'b0) regs_nxt.mcause[62:0]=63'd8;
						else if (mode==2'd3) regs_nxt.mcause[62:0]=63'd11;
					end
				endcase
				regs_nxt.mstatus.mpie=regs_nxt.mstatus.mie;
            	regs_nxt.mstatus.mie='0;
            	regs_nxt.mstatus.mpp=mode;
			end
		end
		else if (~stopm&&interupt) begin
			flushde=1;
			if (~stopf) begin
				flushall=1;
				mode_nxt=2'd3;
				csrpc=regs_nxt.mtvec;
				regs_nxt.mepc=dataM.pc;
				regs_nxt.mcause[62:0]=63'b0;
				regs_nxt.mcause[63]=1'b1;
                if(trint) regs_nxt.mcause[62:0]=63'd7;
                else if(swint) regs_nxt.mcause[62:0]=63'd3;
                else if(exint) regs_nxt.mcause[62:0]=63'd11;
				regs_nxt.mstatus.mpie=regs_nxt.mstatus.mie;
				regs_nxt.mstatus.mie='0;
				regs_nxt.mstatus.mpp=mode;
			end
		end
		else if (~stopm&&(dataM.ctl.op==CSR||dataM.ctl.op==CSRI)&&dataM.valid) begin
			flushde=1;
			if (~stopf) begin
				flushall=1;
				csrpc=dataM.pc+4;
				unique case(dataM.ctl.alufunc) 
					ALU_CSRW: csrresult=dataM.csr;
					ALU_CSRS: csrresult=dataM.result|dataM.csr;
					ALU_CSRC: csrresult=dataM.result&(~dataM.csr);
					default: begin end
				endcase
				unique case(dataM.csrdst)
					CSR_MIE: regs_nxt.mie = csrresult;
					CSR_MIP:  regs_nxt.mip = csrresult;
					CSR_MTVEC: regs_nxt.mtvec = csrresult;
					CSR_MSTATUS: regs_nxt.mstatus = csrresult;
					CSR_MSCRATCH: regs_nxt.mscratch = csrresult;
					CSR_MEPC: regs_nxt.mepc = csrresult;
					CSR_MCAUSE: regs_nxt.mcause = csrresult;
					CSR_MCYCLE: regs_nxt.mcycle = csrresult;
					CSR_MTVAL: regs_nxt.mtval = csrresult;
					default: begin end
				endcase
			end
		end
		else if (~stopm&&(dataM.ctl.op==MRET)&&dataM.valid) begin
			flushde=1;
			if (~stopf) begin
				flushall=1;
				csrpc=regs_nxt.mepc;
				regs_nxt.mstatus.mie=regs_nxt.mstatus.mpie;
				regs_nxt.mstatus.mpie=1'b1;
				regs_nxt.mstatus.mpp=2'b0;
				mode_nxt=regs_nxt.mstatus.mpp;
			end
		end
	end

	// write
	// always_comb begin
	// 	regs_nxt = regs;
	// 	regs_nxt.mcycle = regs.mcycle + 1;
	// 	// Writeback: W stage
	// 	unique if (wvalid) begin
	// 		unique case(wa)
	// 			CSR_MIE: regs_nxt.mie = wd;
	// 			CSR_MIP:  regs_nxt.mip = wd;
	// 			CSR_MTVEC: regs_nxt.mtvec = wd;
	// 			CSR_MSTATUS: regs_nxt.mstatus = wd;
	// 			CSR_MSCRATCH: regs_nxt.mscratch = wd;
	// 			CSR_MEPC: regs_nxt.mepc = wd;
	// 			CSR_MCAUSE: regs_nxt.mcause = wd;
	// 			CSR_MCYCLE: regs_nxt.mcycle = wd;
	// 			CSR_MTVAL: regs_nxt.mtval = wd;
	// 			default: begin
					
	// 			end
				
	// 		endcase
	// 		regs_nxt.mstatus.sd = regs_nxt.mstatus.fs != 0;
	// 	end else if (is_mret) begin
	// 		regs_nxt.mstatus.mie = regs_nxt.mstatus.mpie;
	// 		regs_nxt.mstatus.mpie = 1'b1;
	// 		regs_nxt.mstatus.mpp = 2'b0;
	// 		regs_nxt.mstatus.xs = 0;
	// 	end
	// 	else begin end
	// end
	// assign pcselect = regs.mepc;
	
	
endmodule

`endif