`ifndef __FORWARD_SV
`define __FORWARD_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module forward
	import common::*; 
	import pipes::*;
(
    input  execute_data_t dataE,
    input  memory_data_t  dataM,
    input  decode_data_t  dataD,
    input  word_t         rd1, rd2,
    
    output word_t         alua, alub
);

    always_comb begin
        alua = rd1;
        alub = rd2;

        // dataM转发给dataD
        if(dataM.ctl.regwrite == 1'b1 && dataM.dst != 5'b0) begin
            if(dataD.ctl.regusage == R1 && dataD.raw_instr[19:15] == dataM.dst) begin
                alua = dataM.rst;
            end else if(dataD.ctl.regusage == R2) begin
                if(dataD.raw_instr[19:15] == dataM.dst) begin
                    alua = dataM.rst;
                end else begin end
                if(dataD.raw_instr[24:20] == dataM.dst) begin
                    alub = dataM.rst;
                end else begin end
            end else begin end
        end else begin end

        // dataE转发给dataD
        if(dataE.ctl.regwrite == 1'b1 && dataE.dst != 5'b0) begin
            if(dataD.ctl.regusage == R1 && dataD.raw_instr[19:15] == dataE.dst) begin
                alua = dataE.rst;
            end else if(dataD.ctl.regusage == R2) begin
                if(dataD.raw_instr[19:15] == dataE.dst) begin
                    alua = dataE.rst;
                end else begin end
                if(dataD.raw_instr[24:20] == dataE.dst) begin
                    alub = dataE.rst;
                end else begin end
            end else begin end
        end else begin end

    end
	
endmodule

`endif
