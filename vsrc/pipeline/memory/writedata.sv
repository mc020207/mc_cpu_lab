`ifndef __WRITEDATA_SV
`define __WRITEDATA_SV


`ifdef VERILATOR
`include "include/common.sv"
`else

`endif

module writedata
	import common::*;
	(
	input u3 addr,
	input u64 _wd,
	input msize_t msize,
	output u64 wd,
	output strobe_t strobe,
	output u1 error
);
	always_comb begin
		strobe = '0;
		wd = '0;
		error=1'b0;
		unique case(msize)
			MSIZE1: begin
				unique case(addr)
					3'b000: begin
						wd[7-:8] = _wd[7:0];
						strobe = 8'h01;
					end
					3'b001: begin
						wd[15-:8] = _wd[7:0];
						strobe = 8'h02;
					end
					3'b010: begin
						wd[23-:8] = _wd[7:0];
						strobe = 8'h04;
					end
					3'b011: begin
						wd[31-:8] = _wd[7:0];
						strobe = 8'h08;
					end
					3'b100: begin
						wd[39-:8] = _wd[7:0];
						strobe = 8'h10;
					end
					3'b101: begin
						wd[47-:8] = _wd[7:0];
						strobe = 8'h20;
					end
					3'b110: begin
						wd[55-:8] = _wd[7:0];
						strobe = 8'h40;
					end
					3'b111: begin
						wd[63-:8] = _wd[7:0];
						strobe = 8'h80;
					end
					default: begin
						
					end
				endcase
			end
			MSIZE2: begin
				unique case(addr[2:0])
					3'b000: begin
						wd[15-:16] = _wd[15:0];
						strobe = 8'h03;
					end
					3'b010: begin
						wd[31-:16] = _wd[15:0];
						strobe = 8'h0c;
					end
					3'b100: begin
						wd[47-:16] = _wd[15:0];
						strobe = 8'h30;
					end
					3'b110: begin
						wd[63-:16] = _wd[15:0];
						strobe = 8'hc0;
					end
					default: begin
						error=1;
					end
				endcase
			end
			MSIZE4: begin
				unique case(addr[2:0])
					3'b000: begin
						wd[31-:32] = _wd[31:0];
						strobe = 8'h0f;
					end
					3'b100: begin
						wd[63-:32] = _wd[31:0];
						strobe = 8'hf0;
					end
					default: begin
						error=1;
					end
				endcase
				
			end
			MSIZE8: begin
				if (addr[2:0]==3'b0) begin
					wd = _wd;
					strobe = '1;
				end
				else error=1;
			end
			default: begin
				
			end
		endcase
	end
	
endmodule



`endif