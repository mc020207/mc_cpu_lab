`ifndef __MEMDATA_SV
`define __MEMDATA_SV

`ifdef  VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/04_memrw/read_data.sv"
`include "pipeline/04_memrw/write_data.sv"
`else
`endif

module memdata
    import common::*;
    import pipes::*;
(
    input  dbus_resp_t    dresp,
    input  execute_data_t dataE,
	input  u1 			  invalidate_mem,

    output dbus_req_t     dreq,
    output word_t         mdata,
	output exception_t    ex,
	output u1			  dbus_not_busy
);

	u1 mem_unsigned, is_write, is_valid;
	msize_t msize;
	
	always_comb begin
		dreq.addr = dataE.rst; // all the same
		
		// default
		dreq.valid = 1'b0;
		mem_unsigned = 1'b0;
		is_write = 1'b0;
		ex = dataE.ex;
		unique case(dataE.ctl.op)
			LD: begin
				dreq.size = MSIZE8;
				if(dataE.rst[2:0] == '0) begin 
					dreq.valid = 1'b1;
				end else begin 
					dreq.valid = 1'b0;
					if(dataE.ex == NOEX) begin ex = LOAD_ADDR; end
				end
				mem_unsigned = 1'b0;
			end
			LB: begin
				dreq.size = MSIZE1;
				dreq.valid = 1'b1;
				mem_unsigned = 1'b0;
			end
			LH: begin
				dreq.size = MSIZE2;
				if(dataE.rst[0] == '0) begin 
					dreq.valid = 1'b1;
				end else begin 
					dreq.valid = 1'b0;
					if(dataE.ex == NOEX) begin ex = LOAD_ADDR; end
				end
				mem_unsigned = 1'b0;
			end
			LW: begin
				dreq.size = MSIZE4;
				if(dataE.rst[1:0] == '0) begin 
					dreq.valid = 1'b1;
				end else begin 
					dreq.valid = 1'b0;
					if(dataE.ex == NOEX) begin ex = LOAD_ADDR; end
				end
				mem_unsigned = 1'b0;
			end
			LBU: begin
				dreq.size = MSIZE1;
				dreq.valid = 1'b1;
				mem_unsigned = 1'b1;
			end
			LHU: begin
				dreq.size = MSIZE2;
				if(dataE.rst[0] == '0) begin 
					dreq.valid = 1'b1;
				end else begin 
					dreq.valid = 1'b0;
					if(dataE.ex == NOEX) begin ex = LOAD_ADDR; end
				end
				mem_unsigned = 1'b1;
			end
			LWU: begin
				dreq.size = MSIZE4;
				if(dataE.rst[1:0] == '0) begin 
					dreq.valid = 1'b1;
				end else begin 
					dreq.valid = 1'b0;
					if(dataE.ex == NOEX) begin ex = LOAD_ADDR; end
				end
				mem_unsigned = 1'b1;
			end
			SD: begin 
				dreq.size = MSIZE8;
				if(dataE.rst[2:0] == '0) begin 
					dreq.valid = 1'b1;
				end else begin 
					dreq.valid = 1'b0;
					if(dataE.ex == NOEX) begin ex = STORE_ADDR; end
				end
				is_write = 1'b1;
			end
			SB: begin 
				dreq.size = MSIZE1;
				dreq.valid = 1'b1;
				is_write = 1'b1;
			end
			SH: begin 
				dreq.size = MSIZE2;
				if(dataE.rst[0] == '0) begin 
					dreq.valid = 1'b1;
				end else begin 
					dreq.valid = 1'b0;
					if(dataE.ex == NOEX) begin ex = STORE_ADDR; end
				end
				is_write = 1'b1;
			end
			SW: begin 
				dreq.size = MSIZE4;
				if(dataE.rst[1:0] == '0) begin 
					dreq.valid = 1'b1;
				end else begin 
					dreq.valid = 1'b0;
					if(dataE.ex == NOEX) begin ex = STORE_ADDR; end
				end
				is_write = 1'b1;
			end
			default: begin
			end
		endcase

		if(invalidate_mem) begin 
			dreq.valid = 1'b0;
		end

		if(dataE.raw_instr == 32'h5006b) begin 
			ex = NOEX;
		end

		is_valid = dreq.valid;
		msize = dreq.size;
	end

	assign dbus_not_busy = (dreq.valid == 1'b0) || 
						   (dreq.valid == 1'b1 && dresp.data_ok == 1'b1);

	read_data read_data(
		.is_valid,
		.is_write,
		._rd(dresp.data),
		.addr(dataE.rst[2:0]),
		.msize,
		.mem_unsigned,
		.rd(mdata)
	);

	write_data write_data(
		.is_valid,
		.is_write,
		._wd(dataE.srcb),
		.addr(dataE.rst[2:0]),
		.msize,
		.wd(dreq.data),
		.strobe(dreq.strobe)
	);

endmodule


`endif
