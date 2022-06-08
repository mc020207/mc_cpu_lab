`ifndef __CSR_SV
`define __CSR_SV


`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/csr_pkg.sv"
`else
`endif

module csr
	import common::*;
	import pipes::*;
	import csr_pkg::*;
(
	input  logic         clk, reset,
	input  u12			 ra, // dataF.raw_instr[31:20]
	input  memory_data_t dataM,
	input  stall_t 		 stop,
	input  logic         trint, swint, exint,
	input  logic 	     has_ex, has_int,

	output addr_t        ex_pc,
	output word_t        csr_imm
);
	u2 mode, mode_nxt;
	csr_regs_t regs, regs_nxt;
	
	// update mode
    always_ff @(posedge clk) begin
		if (reset) begin
			mode <= 2'd3;
		end else begin
			mode <= mode_nxt;
		end
	end
    // update mode_nxt
    always_comb begin 
        mode_nxt = mode;
        if(stop != STALLW && dataM.ctl.op == MRET) begin 
            mode_nxt = regs_nxt.mstatus.mpp;
        end else if(stop != STALLW && (dataM.ex != NOEX || has_int)) begin 
            mode_nxt = 2'd3;
        end
    end

    // update regs
    always_ff @(posedge clk) begin
		if (reset) begin
			regs <= '0;
			regs.mcause[1] <= 1'b1;
			regs.mepc[31] <= 1'b1;
		end else begin
			regs <= regs_nxt;
		end
	end
    // assign regs_nxt & ex_pc
	word_t tmp;
    always_comb begin 
        ex_pc = '0;
        regs_nxt = regs;
        regs_nxt.mcycle = regs.mcycle + 1;
        tmp = '0;
        if(stop != STALLW && (dataM.ex != NOEX || has_int)) begin 
            ex_pc = regs_nxt.mtvec;
            regs_nxt.mepc = dataM.pc;
            regs_nxt.mcause[62:0] = 63'd0;
            if(has_int) begin 
                regs_nxt.mcause[63] = 1'b1;
                if(trint) begin 
                    regs_nxt.mcause[62:0] = 63'd7;
                end else if(swint) begin 
                    regs_nxt.mcause[62:0] = 63'd3;
                end else if(exint) begin 
                    regs_nxt.mcause[62:0] = 63'd11;
                end else begin end
            end else begin
                regs_nxt.mcause[63] = 1'b0;
                unique case(dataM.ex)
                    INSTR_ADDR: begin 
                        regs_nxt.mcause[62:0] = 63'd0;
                    end
                    INSTR_TYPE: begin 
                        regs_nxt.mcause[62:0] = 63'd2;
                    end
                    LOAD_ADDR: begin 
                        regs_nxt.mcause[62:0] = 63'd4;
                    end
                    STORE_ADDR: begin 
                        regs_nxt.mcause[62:0] = 63'd6;
                    end
                    ENV_CALL: begin 
                        unique case(mode)
                            2'd0: begin 
                                regs_nxt.mcause[62:0] = 63'd8;
                            end
                            2'd3: begin 
                                regs_nxt.mcause[62:0] = 63'd11;
                            end
                            default: begin end
                        endcase
                    end
                    default: begin end
                endcase
            end
            regs_nxt.mstatus.mpie = regs_nxt.mstatus.mie;
            regs_nxt.mstatus.mie = '0;
            regs_nxt.mstatus.mpp = mode;
        end else if(stop != STALLW && (dataM.ctl.op == CSRRW || dataM.ctl.op == CSRRS || dataM.ctl.op == CSRRC ||
                    dataM.ctl.op == CSRRWI|| dataM.ctl.op == CSRRSI|| dataM.ctl.op == CSRRCI)) begin 
            ex_pc = dataM.pc + 64'd4;
            unique case(dataM.ctl.op)
                CSRRW: begin 
                    tmp = dataM.srca;
                end
                CSRRS: begin 
                    tmp = dataM.srca | dataM.imm;
                end
                CSRRC: begin 
                    tmp = (~dataM.srca) & dataM.imm;
                end
                CSRRWI: begin 
                    tmp = {59'b0, dataM.raw_instr[19:15]};
                end
                CSRRSI: begin 
                    tmp = {59'b0, dataM.raw_instr[19:15]} | dataM.imm;
                end
                CSRRCI: begin 
                    tmp = (~{59'b0, dataM.raw_instr[19:15]}) & dataM.imm;
                end
                default: begin 
                    tmp = '0;
                end
            endcase
			unique case(dataM.raw_instr[31:20])
				CSR_MIE: regs_nxt.mie = tmp;
				CSR_MIP:  regs_nxt.mip = tmp;
				CSR_MTVEC: regs_nxt.mtvec = tmp;
				CSR_MSTATUS: regs_nxt.mstatus = tmp;
				CSR_MSCRATCH: regs_nxt.mscratch = tmp;
				CSR_MEPC: regs_nxt.mepc = tmp;
				CSR_MCAUSE: regs_nxt.mcause = tmp;
				CSR_MCYCLE: regs_nxt.mcycle = tmp;
				CSR_MTVAL: regs_nxt.mtval = tmp;
				default: begin end
			endcase
        end	else if(stop != STALLW && (dataM.ctl.op == MRET))begin
            ex_pc = regs_nxt.mepc;
			regs_nxt.mstatus.mie = regs_nxt.mstatus.mpie;
			regs_nxt.mstatus.mpie = 1'b1;
			regs_nxt.mstatus.mpp = 2'b0;
		end
    end

	// read
	always_comb begin 
		unique case(ra)
			CSR_MIE: csr_imm = regs.mie;
			CSR_MIP: csr_imm = regs.mip;
			CSR_MTVEC: csr_imm = regs.mtvec;
			CSR_MSTATUS: csr_imm = regs.mstatus;
			CSR_MSCRATCH: csr_imm = regs.mscratch;
			CSR_MEPC: csr_imm = regs.mepc;
			CSR_MCAUSE: csr_imm = regs.mcause;
			CSR_MCYCLE: csr_imm = regs.mcycle;
			CSR_MTVAL: csr_imm = regs.mtval;
			default: begin
				csr_imm = '0;
			end
		endcase
	end

	
endmodule

`endif