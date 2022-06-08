`ifndef __FETCH_SV
`define __FETCH_SV

`ifdef  VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/01_fetch/pcselect.sv"
`include "pipeline/01_fetch/pcupdate.sv"
`include "pipeline/01_fetch/meminstr.sv"
`else
`endif

module fetch
    import common::*;
    import pipes::*;
(
    input  u1             clk, reset, 
    input  flush_t        bubble,
    input  stall_t        stop,
    input  ibus_resp_t    iresp,
    input  execute_data_t dataE,
    input  u64            ex_pc,

    output ibus_req_t     ireq,
    output fetch_data_t   dataF_nxt,
    output u1             ibus_not_busy
);

    addr_t pc, pc_nxt;

    // 选取下个pc
    pcselect pcselect(
		.dataE, // 跳转
        .bubble,
		.pcplus4(pc + 64'd4),
        .ex_pc,
		.pc_nxt(pc_nxt)
	);

    // pc更新
    pcupdate pcupdate(
		.clk,
		.reset,
		.stop,
		.pc_nxt,
		.pc
	);

    // 取指令
    instr_t raw_instr;
    meminstr meminstr(
        .iresp,
        .pc,
        .ireq,
        .raw_instr,
        .ex(dataF_nxt.ex)
    );

    // 生成dataF_nxt
    assign dataF_nxt.pc        = pc;
    assign dataF_nxt.raw_instr = raw_instr;

    assign ibus_not_busy = (ireq.valid == 1'b0) || 
                           (ireq.valid == 1'b1 && iresp.data_ok == 1'b1);

endmodule


`endif


