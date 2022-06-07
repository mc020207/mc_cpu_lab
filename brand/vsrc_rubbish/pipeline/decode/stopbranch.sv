`ifndef __STOPBRANCH_SV
`define __STOPBRANCH_SV
`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else
`endif 
module stopbranch
    import common::*;
    import pipes::*;(
    input u1 a,
    output u1 b
);
    always_comb begin
        if (a) begin
            b=1;
        end
    end
endmodule
`endif 