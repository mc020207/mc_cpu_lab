`ifndef __STALL_SV
`define __STALL_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module stall
	import common::*; 
	import pipes::*;
(
    input  execute_data_t dataE,
    input  decode_data_t  dataD,
	input  flush_t		  bubble,
    input  u1             ibus_not_busy, dbus_not_busy,
    input  u1             done,

    output stall_t        stop
);

    always_comb begin
		stop = NOSTALL;
		if((bubble == FLUSHM && ibus_not_busy) || (bubble == FLUSHW && ibus_not_busy && dbus_not_busy)) begin
			stop = NOSTALL; // jump & ex & int
        end else if(bubble == FLUSHW && !(ibus_not_busy && dbus_not_busy)) begin
            stop = STALLW; // delay ex & delay int
        end else if((bubble == FLUSHM && !ibus_not_busy) || !dbus_not_busy) begin
            stop = STALLM; // delay jump & rw data-mem
        end else if(
            ((
                dataE.ctl.op == LD  || dataE.ctl.op == LB  || dataE.ctl.op == LH  || dataE.ctl.op == LW ||
                dataE.ctl.op == LBU || dataE.ctl.op == LHU || dataE.ctl.op == LWU
            ) && (
                (dataD.ctl.regusage == R1 && dataD.raw_instr[19:15] == dataE.dst) || 
                (dataD.ctl.regusage == R2 && (dataD.raw_instr[19:15] == dataE.dst || dataD.raw_instr[24:20] == dataE.dst))
            )) || (!done)
        ) begin 
            stop = STALLE; // mem load-use && div/mul/rem instr
        end else if(!ibus_not_busy) begin 
            stop = STALLF; // rw instr-mem
        end else begin end
	end
	
endmodule

`endif
