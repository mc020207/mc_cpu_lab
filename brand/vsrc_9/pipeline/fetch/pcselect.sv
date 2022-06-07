`ifndef __PCSELECT_SV
`define __PCSELECT_SV
`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else
`endif   
module pcselect
    import common::*;
    import pipes::*;(
    input u1 reset,
    input u64 pcplus4,
    input logic branch,
    input u64 jump,
    output u64 pc_selected,
    input u1 stop,
    input u64 pc_stop,
    input u1 stop_forbranch,stop_forfetch,stop_formem,stop_forexe,
    output u1 move
);
    always_comb begin
        move=0;
        if (reset) begin
            pc_selected=64'h8000_0000;
        end
        else if (stop_formem) begin
            pc_selected=pc_stop;
        end
        else if (stop_forexe) begin
            pc_selected=pc_stop;
        end
        else if (stop_forbranch) begin
            if (branch) begin
                pc_selected=jump;
                move=1;
            end
            else begin
                pc_selected=pc_stop;
            end
        end
        else if (stop) begin
            pc_selected=pc_stop;
        end
        else if (branch) begin
            pc_selected=jump;
            move=1;
        end 
        else if (stop_forfetch) begin
            pc_selected=pc_stop;
        end
        else begin
            pc_selected=pcplus4;
            move=1;
        end
    end
endmodule
`endif