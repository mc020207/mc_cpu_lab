`ifndef __MEMINSTR_SV
`define __MEMINSTR_SV

`ifdef  VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else
`endif

module meminstr
    import common::*;
    import pipes::*;
(
    input  ibus_resp_t    iresp,
    input  addr_t         pc,

    output ibus_req_t     ireq,
    output instr_t        raw_instr,
    output exception_t    ex
);
    always_comb begin
        if(pc[1:0] == '0) begin
            ireq.valid = 1'b1;
            ireq.addr  = pc;
            raw_instr  = iresp.data;
            ex         = NOEX;
        end else begin // instr addr misaligned
            ireq.valid = 1'b0;
            raw_instr  = '0;
            ex         = INSTR_ADDR;
        end
    end

endmodule


`endif
