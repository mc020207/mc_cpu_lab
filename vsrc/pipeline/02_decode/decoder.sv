`ifndef __DECODER_SV
`define __DECODER_SV

`ifdef  VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else
`endif

module decoder
    import common::*;
    import pipes::*;
(
    input  u32         raw_instr,
    input  exception_t ex,

    output control_t   ctl,
    output exception_t ex_nxt
);
    
    // 用wire可以直接赋值，用logic不行
    wire [6:0] o7 = raw_instr[6:0];
    wire [2:0] f3 = raw_instr[14:12];
    wire [6:0] f7 = raw_instr[31:25];
    wire [5:0] f6 = raw_instr[31:26];

    always_comb begin
        ctl = '0; // 先赋值，避免生成锁存器。在default里赋值也可以。
        unique case(o7)
            7'b0010011: begin
                ctl.regwrite = 1'b1;
                ctl.regusage = R1;
                unique case (f3)
                    3'b000: begin
                        ctl.op       = ADDI;
                        ctl.alufunc  = ALU_ADD;
                    end
                    3'b100: begin
                        ctl.op       = XORI;
                        ctl.alufunc  = ALU_XOR;
                    end
                    3'b110: begin
                        ctl.op       = ORI;
                        ctl.alufunc  = ALU_OR;
                    end
                    3'b111: begin
                        ctl.op       = ANDI;
                        ctl.alufunc  = ALU_AND;
                    end
                    3'b010: begin
                        ctl.op       = SLTI;
                        ctl.alufunc  = ALU_LT;
                    end
                    3'b011: begin
                        ctl.op       = SLTIU;
                        ctl.alufunc  = ALU_LTU;
                    end
                    3'b101: begin
                        unique case (f6)
                            6'b000000: begin
                                ctl.op       = SRLI;
                                ctl.alufunc  = ALU_SRL;
                            end
                            6'b010000: begin
                                ctl.op       = SRAI;
                                ctl.alufunc  = ALU_SRA;
                            end
                            default: begin
                            end
                        endcase
                    end
                    3'b001: begin
                        ctl.op       = SLLI;
                        ctl.alufunc  = ALU_SLL;
                    end
                    default: begin
                    end 
                endcase
            end
            7'b0011011: begin
                ctl.regwrite = 1'b1;
                ctl.regusage = R1;
                unique case (f3)
                    3'b000: begin
                        ctl.op       = ADDIW;
                        ctl.alufunc  = ALU_ADDW;
                    end
                    3'b101: begin
                        unique case (f7)
                            7'b0000000: begin
                                ctl.op       = SRLIW;
                                ctl.alufunc  = ALU_SRLW;
                            end
                            7'b0100000: begin
                                ctl.op       = SRAIW;
                                ctl.alufunc  = ALU_SRAW;
                            end
                            default: begin
                            end
                        endcase
                    end
                    3'b001: begin
                        ctl.op       = SLLIW;
                        ctl.alufunc  = ALU_SLLW;
                    end
                    default: begin
                    end 
                endcase
            end
            7'b0110011: begin
                ctl.regwrite = 1'b1;
                ctl.regusage = R2;
                unique case (f3)
                    3'b000: begin
                        unique case (f7)
                            7'b0000000: begin
                                ctl.op       = ADD;
                                ctl.alufunc  = ALU_ADD;
                            end
                            7'b0100000: begin
                                ctl.op       = SUB;
                                ctl.alufunc  = ALU_SUB;
                            end
                            7'b0000001: begin
                                ctl.op       = MUL;
                                ctl.alufunc  = ALU_MUL;
                            end
                            default: begin
                            end
                        endcase
                    end
                    3'b100: begin
                        unique case (f7)
                            7'b0000000: begin
                                ctl.op       = XOR;
                                ctl.alufunc  = ALU_XOR;
                            end
                            7'b0000001: begin
                                ctl.op       = DIV;
                                ctl.alufunc  = ALU_DIV;
                            end
                            default: begin
                            end
                        endcase
                        
                    end
                    3'b110: begin
                        unique case (f7)
                            7'b0000000: begin
                                ctl.op       = OR;
                                ctl.alufunc  = ALU_OR;
                            end
                            7'b0000001: begin
                                ctl.op       = REM;
                                ctl.alufunc  = ALU_REM;
                            end
                            default: begin
                            end
                        endcase
                    end
                    3'b111: begin
                        unique case (f7)
                            7'b0000000: begin
                                ctl.op       = AND;
                                ctl.alufunc  = ALU_AND;
                            end
                            7'b0000001: begin
                                ctl.op       = REMU;
                                ctl.alufunc  = ALU_REM;
                            end
                            default: begin
                            end
                        endcase
                    end
                    3'b101: begin
                        unique case (f7)
                            7'b0000000: begin
                                ctl.op       = SRL;
                                ctl.alufunc  = ALU_SRL;
                            end
                            7'b0100000: begin
                                ctl.op       = SRA;
                                ctl.alufunc  = ALU_SRA;
                            end
                            7'b0000001: begin
                                ctl.op       = DIVU;
                                ctl.alufunc  = ALU_DIV;
                            end
                            default: begin
                            end
                        endcase
                    end
                    3'b001: begin
                        ctl.op       = SLL;
                        ctl.alufunc  = ALU_SLL;
                    end
                    3'b010: begin
                        ctl.op       = SLT;
                        ctl.alufunc  = ALU_LT;
                    end
                    3'b011: begin
                        ctl.op       = SLTU;
                        ctl.alufunc  = ALU_LTU;
                    end
                    default: begin
                    end 
                endcase
            end
            7'b0111011: begin
                ctl.regwrite = 1'b1;
                ctl.regusage = R2;
                unique case (f3)
                    3'b000: begin
                        unique case (f7)
                            7'b0000000: begin
                                ctl.op       = ADDW;
                                ctl.alufunc  = ALU_ADDW;
                            end
                            7'b0100000: begin
                                ctl.op       = SUBW;
                                ctl.alufunc  = ALU_SUBW;
                            end
                            7'b0000001: begin
                                ctl.op       = MULW;
                                ctl.alufunc  = ALU_MULW;
                            end
                            default: begin
                            end
                        endcase
                    end
                    3'b101: begin
                        unique case (f7)
                            7'b0000000: begin
                                ctl.op       = SRLW;
                                ctl.alufunc  = ALU_SRLW;
                            end
                            7'b0100000: begin
                                ctl.op       = SRAW;
                                ctl.alufunc  = ALU_SRAW;
                            end
                            7'b0000001: begin
                                ctl.op       = DIVUW;
                                ctl.alufunc  = ALU_DIVW;
                            end
                            default: begin
                            end
                        endcase
                    end
                    3'b001: begin
                        ctl.op       = SLLW;
                        ctl.alufunc  = ALU_SLLW;
                    end
                    3'b100: begin
                        ctl.op       = DIVW;
                        ctl.alufunc  = ALU_DIVW;
                    end
                    3'b110: begin
                        ctl.op       = REMW;
                        ctl.alufunc  = ALU_REMW;
                    end
                    3'b111: begin
                        ctl.op       = REMUW;
                        ctl.alufunc  = ALU_REMW;
                    end
                    default: begin
                    end 
                endcase
            end
            7'b0110111: begin
                ctl.op       = LUI;
                ctl.alufunc  = ALU_ADD;
                ctl.regwrite = 1'b1;
                ctl.regusage = R0;
            end
            7'b0010111: begin
                ctl.op       = AUIPC;
                ctl.alufunc  = ALU_ADD;
                ctl.regwrite = 1'b1;
                ctl.regusage = R0;
            end
            7'b1100011: begin
                unique case (f3)
                    3'b000: begin
                        ctl.op       = BEQ;
                        ctl.alufunc  = ALU_EQ;
                        ctl.regwrite = 1'b0;
                        ctl.regusage = R2;
                    end
                    3'b001: begin
                        ctl.op       = BNE;
                        ctl.alufunc  = ALU_NEQ;
                        ctl.regwrite = 1'b0;
                        ctl.regusage = R2;
                    end
                    3'b100: begin
                        ctl.op       = BLT;
                        ctl.alufunc  = ALU_LT;
                        ctl.regwrite = 1'b0;
                        ctl.regusage = R2;
                    end
                    3'b101: begin
                        ctl.op       = BGE;
                        ctl.alufunc  = ALU_GE;
                        ctl.regwrite = 1'b0;
                        ctl.regusage = R2;
                    end
                    3'b110: begin
                        ctl.op       = BLTU;
                        ctl.alufunc  = ALU_LTU;
                        ctl.regwrite = 1'b0;
                        ctl.regusage = R2;
                    end
                    3'b111: begin
                        ctl.op       = BGEU;
                        ctl.alufunc  = ALU_GEU;
                        ctl.regwrite = 1'b0;
                        ctl.regusage = R2;
                    end
                    default: begin
                    end 
                endcase
            end
            7'b0000011: begin
                ctl.regwrite = 1'b1;
                ctl.regusage = R1;
                ctl.alufunc  = ALU_ADD;
                unique case (f3)
                    3'b011: begin
                        ctl.op = LD;
                    end
                    3'b000: begin
                        ctl.op = LB;
                    end
                    3'b001: begin
                        ctl.op = LH;
                    end
                    3'b010: begin
                        ctl.op = LW;
                    end
                    3'b100: begin
                        ctl.op = LBU;
                    end
                    3'b101: begin
                        ctl.op = LHU;
                    end
                    3'b110: begin
                        ctl.op = LWU;
                    end
                    default: begin
                    end 
                endcase
            end
            7'b0100011: begin
                ctl.regwrite = 1'b0;
                ctl.regusage = R2;
                ctl.alufunc  = ALU_ADD;
                unique case (f3)
                    3'b011: begin
                        ctl.op = SD;
                    end
                    3'b000: begin
                        ctl.op = SB;
                    end
                    3'b001: begin
                        ctl.op = SH;
                    end
                    3'b010: begin
                        ctl.op = SW;
                    end
                    default: begin
                    end 
                endcase
            end
            7'b1101111: begin
                ctl.op       = JAL;
                ctl.alufunc  = ALU_ADD;
                ctl.regwrite = 1'b1;
                ctl.regusage = R0;
            end
            7'b1100111: begin
                unique case (f3)
                    3'b000: begin
                        ctl.op       = JALR;
                        ctl.alufunc  = ALU_ADD;
                        ctl.regwrite = 1'b1;
                        ctl.regusage = R1;
                    end
                    default: begin
                    end 
                endcase
            end
            7'b1110011: begin 
                unique case (f3)
                    3'b000: begin
                        unique case (raw_instr[31:7])
                            25'b0_0000_0000_0000_0000_0000_0000: begin
                                ctl.op       = ECALL;
                                ctl.alufunc  = ALU_UNKNOWN;
                                ctl.regwrite = 1'b0;
                                ctl.regusage = R0;
                            end
                            25'b0_0110_0000_0100_0000_0000_0000: begin 
                                ctl.op       = MRET;
                                ctl.alufunc  = ALU_UNKNOWN;
                                ctl.regwrite = 1'b0;
                                ctl.regusage = R0;
                            end
                            default: begin
                            end 
                        endcase
                    end
                    3'b001: begin
                        ctl.op       = CSRRW;
                        ctl.alufunc  = ALU_CSR;
                        ctl.regwrite = 1'b1;
                        ctl.regusage = R1;
                    end
                    3'b010: begin
                        ctl.op       = CSRRS;
                        ctl.alufunc  = ALU_CSR;
                        ctl.regwrite = 1'b1;
                        ctl.regusage = R1;
                    end
                    3'b011: begin
                        ctl.op       = CSRRC;
                        ctl.alufunc  = ALU_CSR;
                        ctl.regwrite = 1'b1;
                        ctl.regusage = R1;
                    end
                    3'b101: begin
                        ctl.op       = CSRRWI;
                        ctl.alufunc  = ALU_CSR;
                        ctl.regwrite = 1'b1;
                        ctl.regusage = R0;
                    end
                    3'b110: begin
                        ctl.op       = CSRRSI;
                        ctl.alufunc  = ALU_CSR;
                        ctl.regwrite = 1'b1;
                        ctl.regusage = R0;
                    end
                    3'b111: begin
                        ctl.op       = CSRRCI;
                        ctl.alufunc  = ALU_CSR;
                        ctl.regwrite = 1'b1;
                        ctl.regusage = R0;
                    end
                    default: begin
                    end 
                endcase
            end
            default: begin
            end
        endcase
    end

    always_comb begin
        ex_nxt = ex;
        if(ex == NOEX && raw_instr != '0 && ctl == '0) begin 
            ex_nxt = INSTR_TYPE;
        end else if(ex == NOEX && raw_instr != '0 && ctl.op == ECALL) begin 
            ex_nxt = ENV_CALL;
        end
    end

endmodule


`endif