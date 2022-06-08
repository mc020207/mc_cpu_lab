`ifndef __PCSELECT_SV
`define __PCSELECT_SV

`ifdef  VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else
`endif

module pcselect
    import common::*;
    import pipes::*;
(
    input  execute_data_t dataE,
    input  flush_t        bubble,
    input  u64            pcplus4,
    input  u64            ex_pc,

    output u64            pc_nxt
);
    
    always_comb begin
        if(bubble == FLUSHW) begin
            pc_nxt = ex_pc;
        end else if(dataE.ctl.op != JALR && bubble == FLUSHM) begin
            pc_nxt = dataE.pc_nxt;
        end else if(dataE.ctl.op == JALR) begin
            // pc_nxt = {dataE.pc_nxt[63:1], 1'b0}; // lab1~lab3
            pc_nxt = dataE.pc_nxt;
        end else begin
            pc_nxt = pcplus4;
        end
    end

endmodule


`endif


