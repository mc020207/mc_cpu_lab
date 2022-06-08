`ifndef __CSR_SV
`define __CSR_SV


`ifdef VERILATOR
`include "include/interface.svh"
`else
`include "interface.svh"
`endif

module csr
	import common::*;
	import decode_pkg::*;
	import csr_pkg::*;(
	input logic clk, reset,
	csr_intf.csr self,
	pcselect_intf.csr pcselect

);
	csr_regs_t regs, regs_nxt;

	always_ff @(posedge clk) begin
		if (reset) begin
			regs <= '0;
			regs.mcause[1] <= 1'b1;
			regs.mepc[31] <= 1'b1;
		end else begin
			regs <= regs_nxt;
		end
	end

	// read
	always_comb begin
		self.rd = '0;
		unique case(self.ra)
			CSR_MIE: self.rd = regs.mie;
			CSR_MIP: self.rd = regs.mip;
			CSR_MTVEC: self.rd = regs.mtvec;
			CSR_MSTATUS: self.rd = regs.mstatus;
			CSR_MSCRATCH: self.rd = regs.mscratch;
			CSR_MEPC: self.rd = regs.mepc;
			CSR_MCAUSE: self.rd = regs.mcause;
			CSR_MCYCLE: self.rd = regs.mcycle;
			CSR_MTVAL: self.rd = regs.mtval;
			default: begin
				self.rd = '0;
			end
		endcase
	end

	// write
	always_comb begin
		regs_nxt = regs;
		regs_nxt.mcycle = regs.mcycle + 1;
		// Writeback: W stage
		unique if (self.valid) begin
			unique case(self.wa)
				CSR_MIE: regs_nxt.mie = self.wd;
				CSR_MIP:  regs_nxt.mip = self.wd;
				CSR_MTVEC: regs_nxt.mtvec = self.wd;
				CSR_MSTATUS: regs_nxt.mstatus = self.wd;
				CSR_MSCRATCH: regs_nxt.mscratch = self.wd;
				CSR_MEPC: regs_nxt.mepc = self.wd;
				CSR_MCAUSE: regs_nxt.mcause = self.wd;
				CSR_MCYCLE: regs_nxt.mcycle = self.wd;
				CSR_MTVAL: regs_nxt.mtval = self.wd;
				default: begin
					
				end
				
			endcase
			regs_nxt.mstatus.sd = regs_nxt.mstatus.fs != 0;
		end else if (self.is_mret) begin
			regs_nxt.mstatus.mie = regs_nxt.mstatus.mpie;
			regs_nxt.mstatus.mpie = 1'b1;
			regs_nxt.mstatus.mpp = 2'b0;
			regs_nxt.mstatus.xs = 0;
		end
		else begin end
	end
	assign pcselect.mepc = regs.mepc;
	
	
endmodule

`endif