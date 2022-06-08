`ifndef __EXTEND_SV
`define __EXTEND_SV

`ifdef  VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/csr_pkg.sv"
`else
`endif

module extend
    import common::*;
    import pipes::*;
    import csr_pkg::*;
(
    input instr_t raw_instr,
    input word_t csr_imm,
    output word_t imm
);

    u7 o7;
    assign o7 = raw_instr[6:0];

    always_comb begin
        if(o7 == 7'b0010011 || o7 == 7'b0011011 || o7 == 7'b0000011 || o7 == 7'b1100111) begin
            imm = {{52{raw_instr[31]}}, raw_instr[31:20]};
        end else if(o7 == 7'b0110111 || o7 == 7'b0010111) begin
            imm = {{32{raw_instr[31]}}, raw_instr[31:12], 12'b0};
        end else if(o7 == 7'b0100011) begin
            imm = {{52{raw_instr[31]}}, raw_instr[31:25], raw_instr[11:7]};
        end else if(o7 == 7'b1100011) begin
            imm = {{51{raw_instr[31]}}, raw_instr[31], raw_instr[7], raw_instr[30:25], raw_instr[11:8], 1'b0};
        end else if(o7 == 7'b1101111) begin
            imm = {{43{raw_instr[31]}}, raw_instr[31], raw_instr[19:12], raw_instr[20], raw_instr[30:21], 1'b0};
        end else if(o7 == 7'b1110011) begin
            imm = csr_imm;
        end else begin
            imm = '0;
        end
    end
endmodule


`endif
