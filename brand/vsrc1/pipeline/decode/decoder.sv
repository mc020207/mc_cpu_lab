`ifndef __DECODER_SV
`define __DECODER_SV
`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else
`endif 
module decoder 
    import common::*;
	import pipes::*;(
    input u32 raw_instr,
    output contral_t ctl
);
    logic [6:0] f7;
    assign f7=raw_instr[6:0];
    logic [2:0] f3;
    assign f3=raw_instr[14:12];
    u7 f7_first;
    assign f7_first=raw_instr[31:25];
    always_comb begin
        ctl.op=UNKNOWN;
        ctl.alufunc=NOTALU;
        ctl.regwrite=1'b1;
        unique case(f7)
            F7_ALUI:begin
                ctl.op=ALUI;
                ctl.regwrite=1'b1;
                unique case(f3)
                    F3_ADD: begin
                        ctl.alufunc=ALU_ADD;
                    end
                    F3_XOR: begin
                        ctl.alufunc=ALU_XOR;
                    end
                    F3_OR: begin
                        ctl.alufunc=ALU_OR;
                    end
                    F3_AND: begin
                        ctl.alufunc=ALU_AND;
                    end
                    F3_SLT: begin
                        ctl.alufunc=ALU_SLT;
                    end
                    F3_SLTU: begin
                        ctl.alufunc=ALU_SLTU;
                    end
                    F3_SLL: begin
                        ctl.alufunc=ALU_SLL;
                    end
                    F3_SR: begin
                        if (raw_instr[30]) begin
                            ctl.alufunc=ALU_SRA;
                        end
                        else begin
                            ctl.alufunc=ALU_SRL;
                        end
                    end
                    default :begin
                        
                    end
                endcase 
            end
            F7_ALU: begin
                ctl.op=ALU;
                ctl.regwrite=1'b1;
                unique case(f3)
                    F3_ADD: begin
                        if (f7_first==F7_FIRST_ADD) begin
                            ctl.alufunc=ALU_ADD;
                        end 
                        else if (f7_first==F7_FIRST_SUB) begin
                            ctl.alufunc=ALU_SUB;
                        end
                        else if (f7_first==F7_FIRST_MUL) begin
                            ctl.alufunc=ALU_MULT;
                        end
                    end
                    F3_XOR: begin
                        if (f7_first==F7_FIRST_MUL) ctl.alufunc=ALU_DIV;
                        else ctl.alufunc=ALU_XOR;
                    end
                    F3_OR: begin
                        if (f7_first==F7_FIRST_MUL) ctl.alufunc=ALU_REM;
                        else ctl.alufunc=ALU_OR;
                    end
                    F3_AND: begin
                        if (f7_first==F7_FIRST_MUL) ctl.alufunc=ALU_REMU;
                        else ctl.alufunc=ALU_AND;
                    end
                    F3_SLT: begin
                        ctl.alufunc=ALU_SLT;
                    end
                    F3_SLTU: begin
                        ctl.alufunc=ALU_SLTU;
                    end
                    F3_SLL: begin
                        ctl.alufunc=ALU_SLL;
                    end
                    F3_SR: begin
                        if (f7_first==F7_FIRST_SUB) begin
                            ctl.alufunc=ALU_SRA;
                        end
                        else if(f7_first==F7_FIRST_ADD)begin
                            ctl.alufunc=ALU_SRL;
                        end
                        else if (f7_first==F7_FIRST_MUL) begin
                            ctl.alufunc=ALU_DIVU;
                        end
                    end
                    default :begin
                        
                    end
                endcase 
            end
            F7_ALUIW:begin
                ctl.op=ALUIW;
                ctl.regwrite=1'b1;
                unique case(f3)
                    F3_ADD: begin
                        ctl.alufunc=ALU_ADD;
                    end
                    F3_XOR: begin
                        ctl.alufunc=ALU_XOR;
                    end
                    F3_OR: begin
                        ctl.alufunc=ALU_OR;
                    end
                    F3_AND: begin
                        ctl.alufunc=ALU_AND;
                    end
                    F3_SLT: begin
                        ctl.alufunc=ALU_SLT;
                    end
                    F3_SLTU: begin
                        ctl.alufunc=ALU_SLTU;
                    end
                    F3_SLL: begin
                        ctl.alufunc=ALU_SLL;
                    end
                    F3_SR: begin
                        if (raw_instr[30]) begin
                            ctl.alufunc=ALU_SRA;
                        end
                        else begin
                            ctl.alufunc=ALU_SRL;
                        end
                    end
                    default :begin
                        
                    end
                endcase 
            end
            F7_ALUW: begin
                ctl.op=ALUW;
                ctl.regwrite=1'b1;
                unique case(f3)
                    F3_ADD: begin
                        if (f7_first==F7_FIRST_ADD) begin
                            ctl.alufunc=ALU_ADD;
                        end 
                        else if (f7_first==F7_FIRST_SUB) begin
                            ctl.alufunc=ALU_SUB;
                        end
                        else if (f7_first==F7_FIRST_MUL) begin
                            ctl.alufunc=ALU_MULT;
                        end
                    end
                    F3_XOR: begin
                        if (f7_first==F7_FIRST_MUL) ctl.alufunc=ALU_DIV;
                        else ctl.alufunc=ALU_XOR;
                    end
                    F3_OR: begin
                        if (f7_first==F7_FIRST_MUL) ctl.alufunc=ALU_REM;
                        else ctl.alufunc=ALU_OR;
                    end
                    F3_AND: begin
                        if (f7_first==F7_FIRST_MUL) ctl.alufunc=ALU_REMU;
                        else ctl.alufunc=ALU_AND;
                    end
                    F3_SLT: begin
                        ctl.alufunc=ALU_SLT;
                    end
                    F3_SLTU: begin
                        ctl.alufunc=ALU_SLTU;
                    end
                    F3_SLL: begin
                        ctl.alufunc=ALU_SLL;
                    end
                    F3_SR: begin
                        if (f7_first==F7_FIRST_SUB) begin
                            ctl.alufunc=ALU_SRA;
                        end
                        else if(f7_first==F7_FIRST_ADD)begin
                            ctl.alufunc=ALU_SRL;
                        end
                        else if (f7_first==F7_FIRST_MUL) begin
                            ctl.alufunc=ALU_DIVU;
                        end
                    end
                    default :begin
                        
                    end
                endcase 
            end
            F7_LUI:begin
                ctl.op=LUI;
                ctl.regwrite=1'b1;
                ctl.alufunc=ALU_LUI;
            end
            F7_JAL: begin
                ctl.op=JAL;
                ctl.regwrite=1'b1;
                ctl.alufunc=ALU_ADD;
            end
            F7_BRANCH: begin
                ctl.regwrite=1'b0;
                unique case(f3)
                    F3_BEQ: begin
                        ctl.op=BEQ;
                        ctl.alufunc=ALU_COMPARE;
                    end
                    F3_BNE: begin
                        ctl.op=BNE;
                        ctl.alufunc=ALU_COMPARE;
                    end
                    F3_BLT: begin
                        ctl.op=BLT;
                        ctl.alufunc=ALU_SMALL;
                    end
                    F3_BGE: begin
                        ctl.op=BGE;
                        ctl.alufunc=ALU_SMALL;
                    end
                    F3_BLTU: begin
                        ctl.op=BLTU;
                        ctl.alufunc=ALU_SMALLU;
                    end
                    F3_BGEU: begin
                        ctl.op=BGEU;
                        ctl.alufunc=ALU_SMALLU;
                    end
                    default begin
                        
                    end
                endcase 
            end
            F7_CSR:begin
                unique case (f3)
                    F3_CSRRC:begin
                        ctl.op=CSR;
                        ctl.alufunc=ALU_CSRC;
                    end
                    F3_CSRRCI:begin
                        ctl.op=CSRI;
                        ctl.alufunc=ALU_CSRC;
                    end
                    F3_CSRRS:begin
                        ctl.op=CSR;
                        ctl.alufunc=ALU_CSRS;
                    end
                    F3_CSRRSI:begin
                        ctl.op=CSRI;
                        ctl.alufunc=ALU_CSRS;
                    end
                    F3_CSRRW:begin
                        ctl.op=CSR;
                        ctl.alufunc=ALU_CSRW;
                    end
                    F3_CSRRWI:begin
                        ctl.op=CSRI;
                        ctl.alufunc=ALU_CSRW;
                    end
                    default: begin
                        
                    end
                endcase
            end
            F7_LD: begin
                ctl.op=LD;
                ctl.regwrite=1'b1;
                ctl.alufunc=ALU_ADD;
            end
            F7_SD: begin
                ctl.op=SD;
                ctl.regwrite=1'b0;
                ctl.alufunc=ALU_ADD;
            end
            F7_AUIPC: begin
                ctl.op=AUIPC;
                ctl.regwrite=1'b1;
                ctl.alufunc=ALU_ADD;
            end
            F7_JALR:begin
                ctl.op=JALR;
                ctl.regwrite=1'b1;
                ctl.alufunc=ALU_ADD;
            end
            default : begin
                
            end
        endcase
    end
endmodule
`endif