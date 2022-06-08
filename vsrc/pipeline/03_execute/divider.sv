`ifndef __DIV_SV
`define __DIV_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module divider
	import common::*; 
	import pipes::*;
(
    input  u1  clk, reset,
    input  u64 a, b,
    input  control_t ctl,
    input  execute_data_t dataE,
    input  decode_data_t dataD,
    input  flush_t bubble,
    output u1  done_div,
    output u64 c_div // c 前or后 {a % b, a / b}
);

    u64 num_a, num_b;

    /* if divider is valid */
    u1 stop;
    always_comb begin 
        stop = '0;
        if(
            (
                dataE.ctl.op == LD  || dataE.ctl.op == LB  || dataE.ctl.op == LH  || dataE.ctl.op == LW ||
                dataE.ctl.op == LBU || dataE.ctl.op == LHU || dataE.ctl.op == LWU
            ) && (
                (dataD.ctl.regusage == R1 && dataD.raw_instr[19:15] == dataE.dst) || 
                (dataD.ctl.regusage == R2 && (dataD.raw_instr[19:15] == dataE.dst || dataD.raw_instr[24:20] == dataE.dst))
            )
        ) begin 
            stop = '1;
        end
    end
    u1 valid;
    assign valid = !stop &&
                    ((ctl.op == DIV || ctl.op == DIVU || ctl.op == DIVW || ctl.op == DIVUW ||
                    ctl.op == REM || ctl.op == REMU || ctl.op == REMW || ctl.op == REMUW) &&
                    (num_b != '0)); // not a zero divisor


    /* get unsigned num */
    // convert a&b to num_a&num_b
    always_comb begin 
        {num_a, num_b} = {a, b};
        if(ctl.op == DIVW || ctl.op == REMW) begin 
            num_a = {{32{a[31]}}, a[31:0]};
            num_b = {{32{b[31]}}, b[31:0]};
        end else if(ctl.op == DIVUW || ctl.op == REMUW) begin 
            num_a = {{32{1'b0}}, a[31:0]};
            num_b = {{32{1'b0}}, b[31:0]};
        end
    end
    // judge num_a& num_b are signed or unsigned
    u1 nega, negb;
    assign nega = (num_a[63] == 1'b1);
    assign negb = (num_b[63] == 1'b1);
    // convert signed to unsigned
    u64 unum_a, unum_b;
    always_comb begin 
        {unum_a, unum_b} = {num_a, num_b}; // default
        if(ctl.op == DIV || ctl.op == DIVW || ctl.op == REM || ctl.op == REMW) begin 
            if(nega) begin
                unum_a = ~num_a + 1'b1; 
            end
            if(negb) begin
                unum_b = ~num_b + 1'b1;
            end
        end
    end


    /* calculate state&count */
    state_t state, state_nxt;
    u65 count, count_nxt;
    localparam u65 DIV_DELAY = {1'b1, 64'b0};
    // get state_nxt&count_nxt
    always_comb begin
        {state_nxt, count_nxt} = {state, count}; // default
        unique case(state)
            INIT: begin
                if (valid) begin
                    state_nxt = DOING;
                    count_nxt = DIV_DELAY;
                end
            end
            DOING: begin
                count_nxt = {1'b0, count_nxt[64:1]};
                if (count_nxt == '0 || bubble != NOFLUSH) begin
                    state_nxt = INIT;
                end
            end
        endcase
    end
    // update state&count
    always_ff @(posedge clk) begin
        if (reset) begin
            {state, count} <= '0; // state is default INIT
        end else begin
            {state, count} <= {state_nxt, count_nxt};
        end
    end
    // judge if is done
    assign done_div = (state_nxt == INIT);


    /* calculate unsigned result */
    u129 p, p_nxt;
    // get p_next
    always_comb begin
        p_nxt = p;
        unique case(state)
            INIT: begin
                p_nxt = {65'b0, unum_a};
            end
            DOING: begin
                p_nxt = {p_nxt[127:0], 1'b0};
                if (p_nxt[127:64] >= unum_b) begin
                    p_nxt[127:64] -= unum_b;
                    p_nxt[0] = 1'b1;
                end
            end
        endcase
    end
    // update p
    always_ff @(posedge clk) begin
        if (reset) begin
            p <= '0;
        end else begin
            p <= p_nxt;
        end
    end


    /* get signed result */
    u64 div, rem;
    // get signed div&rem
    always_comb begin 
        {rem, div} = {p[127:64], p[63:0]};
        if(num_b == '0) begin
            rem = a;
            div = '1;
        end else begin
            if(ctl.op == DIV || ctl.op == DIVW || ctl.op == REM || ctl.op == REMW) begin
                if(nega && negb) begin
                    rem = ~p[127:64] + 1'b1;
                end else if(nega && !negb) begin 
                    rem = ~p[127:64] + 1'b1;
                    div = ~p[63:0] + 1'b1;
                end else if(!nega && negb) begin
                    div = ~p[63:0] + 1'b1;
                end
            end
        end
    end
    // get final result
    always_comb begin
        c_div = div;
        if(ctl.op == REM || ctl.op == REMU) begin
            c_div = rem;
        end else if(ctl.op == REMW || ctl.op == REMUW) begin
            c_div = {{32{rem[31]}}, rem[31:0]};
        end else if(ctl.op == DIVW || ctl.op == DIVUW) begin 
            c_div = {{32{div[31]}}, div[31:0]};
        end
    end

endmodule

`endif