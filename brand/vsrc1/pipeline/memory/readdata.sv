`ifndef __READDATA_SV
`define __READDATA_SV


`ifdef VERILATOR
`include "include/common.sv"
`else

`endif

module readdata
	import common::*;
	(
	input u64 _rd,
	output u64 rd,
	input u3 addr,
	input msize_t msize,
	input u1 mem_unsigned
);
	u1 sign_bit;
	always_comb begin
		rd = 'x;
		sign_bit = 'x;
		unique case(msize)
			MSIZE1: begin // LB, LBU
				unique case(addr)
					3'b000: begin
						sign_bit = mem_unsigned ? 1'b0 : _rd[7];
						rd = {{56{sign_bit}}, _rd[7-:8]};
					end
					3'b001: begin
						sign_bit = mem_unsigned ? 1'b0 : _rd[15];
						rd = {{56{sign_bit}}, _rd[15-:8]};
					end
					3'b010: begin
						sign_bit = mem_unsigned ? 1'b0 : _rd[23];
						rd = {{56{sign_bit}}, _rd[23-:8]};
					end
					3'b011: begin
						sign_bit = mem_unsigned ? 1'b0 : _rd[31];
						rd = {{56{sign_bit}}, _rd[31-:8]};
					end
					3'b100: begin
						sign_bit = mem_unsigned ? 1'b0 : _rd[39];
						rd = {{56{sign_bit}}, _rd[39-:8]};
					end
					3'b101: begin
						sign_bit = mem_unsigned ? 1'b0 : _rd[47];
						rd = {{56{sign_bit}}, _rd[47-:8]};
					end
					3'b110: begin
						sign_bit = mem_unsigned ? 1'b0 : _rd[55];
						rd = {{56{sign_bit}}, _rd[55-:8]};
					end
					3'b111: begin
						sign_bit = mem_unsigned ? 1'b0 : _rd[63];
						rd = {{56{sign_bit}}, _rd[63-:8]};
					end
					default: begin
						
					end
				endcase
			end
			MSIZE2: begin
				unique case(addr[2:1])
					2'b00: begin
						sign_bit = mem_unsigned ? 1'b0 : _rd[15];
						rd = {{48{sign_bit}}, _rd[15-:16]};
					end
					2'b01: begin
						sign_bit = mem_unsigned ? 1'b0 : _rd[31];
						rd = {{48{sign_bit}}, _rd[31-:16]};
					end
					2'b10: begin
						sign_bit = mem_unsigned ? 1'b0 : _rd[47];
						rd = {{48{sign_bit}}, _rd[47-:16]};
					end
					2'b11: begin
						sign_bit = mem_unsigned ? 1'b0 : _rd[63];
						rd = {{48{sign_bit}}, _rd[63-:16]};
					end
					default: begin
						
					end
				endcase
			end
			MSIZE4: begin
				unique case(addr[2])
					1'b0: begin
						sign_bit = mem_unsigned ? 1'b0 : _rd[31];
						rd = {{32{sign_bit}}, _rd[31-:32]};
					end
					1'b1: begin
						sign_bit = mem_unsigned ? 1'b0 : _rd[63];
						rd = {{32{sign_bit}}, _rd[63-:32]};
					end
					default: begin
						
					end
				endcase
			end
			MSIZE8: begin
				rd = _rd;
			end
			default: begin
				
			end
		endcase
	end
	
endmodule



`endif