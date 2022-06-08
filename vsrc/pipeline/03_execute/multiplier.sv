`ifndef __MUL_SV
`define __MUL_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module multiplier 
	import common::*; 
	import pipes::*;
(
    input  u1  clk, reset,
    input  u64 a, b,
    input  control_t ctl,
    input  execute_data_t dataE,
    input  decode_data_t dataD,
    input  flush_t bubble,
    output u1 done_mul, // 握手信号，done 上升沿时的输出是有效的
    output u64 c_mul // c = a * b, 截断
);

    /* if multiplier is valid */
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
    assign valid = !stop && (ctl.op == MUL || ctl.op == MULW);


    /* get unsigned num */
    // convert a&b to num_a&num_b
    u64 num_a, num_b;
    always_comb begin 
        {num_a, num_b} = {a, b};
        if(ctl.op == DIVW || ctl.op == REMW) begin 
            num_a = {{32{a[31]}}, a[31:0]};
            num_b = {{32{b[31]}}, b[31:0]};
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
        if(nega) begin
            unum_a = ~num_a + 1'b1; 
        end
        if(negb) begin
            unum_b = ~num_b + 1'b1;
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
    assign done_mul = (state_nxt == INIT);


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
                if (p_nxt[0]) begin
                    p_nxt[128:64] = p_nxt[128:64] + unum_b;
            	end
            	p_nxt = {1'b0, p_nxt[128:1]};
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
    u129 mul;
    // get signed div&rem
    always_comb begin 
        mul = p;
        if((nega && !negb) || (!nega && negb)) begin 
            mul = ~p + 1'b1;
        end
    end
    // get final result
    always_comb begin 
        c_mul = mul[63:0];
        if(ctl.op == MULW) begin 
            c_mul = {{32{mul[31]}}, mul[31:0]};
        end
    end


endmodule

`endif