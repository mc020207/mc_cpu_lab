`ifndef __MEMRW_SV
`define __MEMRW_SV

`ifdef  VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/04_memrw/memdata.sv"
`include "pipeline/04_memrw/mux_rst_mdata.sv"
`else
`endif

module memrw
    import common::*;
    import pipes::*;
(
    input  dbus_resp_t    dresp,
    input  execute_data_t dataE,
    input  u1             invalidate_mem,

    output dbus_req_t     dreq,
    output memory_data_t  dataM_nxt,
    output u1             dbus_not_busy
);

    // 数据内存
    word_t mdata;
    memdata memdata(
        .dresp,
        .dataE,
        .dreq,
        .invalidate_mem,
        .mdata,
        .ex(dataM_nxt.ex),
        .dbus_not_busy
    );

    mux_rst_mdata mux_rst_mdata(
        .erst(dataE.rst),
        .mdata,
        .ctl(dataE.ctl),
        .rst(dataM_nxt.rst)
    );

	assign dataM_nxt.srca  = dataE.srca;
    assign dataM_nxt.srcb  = dataE.srcb;
	assign dataM_nxt.imm   = dataE.imm;
    assign dataM_nxt.pc    = dataE.pc;
    assign dataM_nxt.raw_instr = dataE.raw_instr;
    assign dataM_nxt.ctl   = dataE.ctl;
    assign dataM_nxt.dst   = dataE.dst;

endmodule


`endif
