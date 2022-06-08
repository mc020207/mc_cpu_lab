`ifndef __WRITEBACK_SV
`define __WRITEBACK_SV

`ifdef  VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/csr_pkg.sv"
`else
`endif

module writeback
    import common::*;
    import pipes::*;
    import csr_pkg::*;
(
    input  memory_data_t dataM,
    input  logic         trint, swint, exint,
    input  u1            regs_mstatus_mie, // regs.mstatus.mie
    input  u64           regs_mie, // regs.mie

    output word_t        wd,
    output u1            invalidate_mem, has_ex, has_int,
    output addr_t        ex_pc
);

    assign wd = dataM.rst;

    assign has_ex = (dataM.ex != NOEX) || dataM.ctl.op == ECALL;

    assign invalidate_mem = has_ex || dataM.ctl.op == CSRRW || dataM.ctl.op == CSRRS || 
                    dataM.ctl.op == CSRRC || dataM.ctl.op == CSRRWI || dataM.ctl.op == CSRRSI || 
                    dataM.ctl.op == CSRRCI || dataM.ctl.op == MRET;

    assign has_int = dataM != '0 && !has_ex && regs_mstatus_mie &&
            ((trint && regs_mie[7]) || (swint && regs_mie[3]) || (exint && regs_mie[11])); 

endmodule


`endif
