`ifndef __DCACHE_SV
`define __DCACHE_SV

`ifdef VERILATOR
`include "include/common.sv"
/* You should not add any additional includes in this file */
`include "ram/RAM_SinglePort.sv"
`endif

module DCache 
	import common::*; #(
		/* You can modify this part to support more parameters */
		/* e.g. OFFSET_BITS, INDEX_BITS, TAG_BITS */
        parameter int SET_NUM        = 8,
        parameter int ASSOCIATIVITY  = 2,
        parameter int WORDS_PER_LINE = 16,
        
        localparam int INDEX_BITS     = $clog2(SET_NUM),
        localparam int COUNTER_BITS   = $clog2(ASSOCIATIVITY),
        localparam int OFFSET_BITS    = $clog2(WORDS_PER_LINE),
        localparam int TAG_BITS       = 64 - INDEX_BITS - OFFSET_BITS - 3,

        localparam type index_t       = logic[INDEX_BITS   - 1 : 0],
        localparam type counter_t     = logic[COUNTER_BITS - 1 : 0],
        localparam type offset_t      = logic[OFFSET_BITS  - 1 : 0],
        localparam type tag_t         = logic[TAG_BITS     - 1 : 0]

	)(
	input logic clk, reset,

	input  dbus_req_t  dreq,
    output dbus_resp_t dresp,
    output cbus_req_t  creq,
    input  cbus_resp_t cresp
);

`ifndef REFERENCE_CACHE

	/* TODO: Lab3 Cache */

    /**
     * typedefs and functions
     */
    // cache states
	typedef enum u2 {
		IDLE, 
        FLUSH,
        FETCH,
        DIRECT_FETCH
	} state_t;
    // meta and set(ASSOCIATIVITY meta)
    typedef struct packed {
        u1 valid, dirty;
        counter_t age;
        tag_t tag;
    } meta_t;
    typedef struct packed {
        counter_t cnt;
        meta_t[ASSOCIATIVITY - 1 : 0] meta;
    } set_t;
    // get addr info
    function offset_t get_offset(addr_t addr);
        return addr[OFFSET_BITS + 3 - 1 : 3];
    endfunction
    function index_t get_index(addr_t addr);
        return addr[INDEX_BITS + OFFSET_BITS + 3 - 1 : OFFSET_BITS + 3];
    endfunction
    function tag_t get_tag(addr_t addr);
        return addr[TAG_BITS + INDEX_BITS + OFFSET_BITS + 3 - 1 : INDEX_BITS + OFFSET_BITS + 3];
    endfunction


    /**
     * variables ahead
     */
    // control info
    u1 cached_request, uncached_request; // if is request
    u1 hit; // if cache is hit
    u1 dirty; // if cache is dirty
    u1 is_write; // if this instr is memwrite
    u1 is_ok; // if memdata is prepared
    // important status
    state_t state, state_nxt; // cache state
    meta_t meta_new, meta; // meta
    set_t set_new, set; // set
    word_t word_new, word; // data
    // assign control info
    assign cached_request = dreq.valid && (dreq.addr[31] != 1'b0);
    assign uncached_request = dreq.valid && (dreq.addr[31] == 1'b0);
    assign dirty = meta.dirty;
    assign is_write = dreq.strobe != '0;
    always_comb begin
        is_ok = (cresp.last == 1'b1);
        if(state == DIRECT_FETCH) begin 
            is_ok = (cresp.ready == 1'b1);
        end
    end


    /**
     * update state of cache
     */
    // get state_nxt
    always_comb begin 
        state_nxt = state; // default
        unique case(state)
            IDLE: begin 
                if(cached_request && hit) begin
                    state_nxt = IDLE;
                end else if(cached_request && !hit && dirty) begin
                    state_nxt = FLUSH;
                end else if(cached_request && !hit && !dirty) begin
                    state_nxt = FETCH;
                end else if(uncached_request) begin 
                    state_nxt = DIRECT_FETCH;
                end else begin
                    state_nxt = IDLE;
                end
            end
            FLUSH: begin 
                if(is_ok) begin 
                    state_nxt = FETCH;
                end else begin 
                    state_nxt = FLUSH;
                end
            end
            FETCH: begin
                if(is_ok) begin 
                    state_nxt = IDLE;
                end else begin 
                    state_nxt = FETCH;
                end
            end
            DIRECT_FETCH: begin 
                if(is_ok) begin 
                    state_nxt = IDLE;
                end else begin 
                    state_nxt = DIRECT_FETCH;
                end
            end
            default: begin end
        endcase
    end
    // update state
    always_ff @(posedge clk) begin 
        if(reset) begin 
            state <= IDLE;
        end else begin 
            state <= state_nxt;
        end
    end


    /**
     * main process of cache: 
     * fetch set, fetch meta, fetch date, replace, writeback
     */
    // get set & update meta_ram
    logic[INDEX_BITS : 0] reset_cnt, reset_cnt_nxt;  // 0~SET_NUM-1
    u1 reset_cache;
    u1 update_meta_ram;
    index_t set_addr;
    always_comb begin
        if(reset && (reset_cnt < SET_NUM[INDEX_BITS : 0])) begin
            reset_cnt_nxt = reset_cnt + 1'b1;
            reset_cache = 1'b1;
        end else if(reset && reset_cnt >= SET_NUM[INDEX_BITS : 0]) begin 
            reset_cnt_nxt = reset_cnt;
            reset_cache = 1'b0;
        end else begin
            reset_cnt_nxt = '0;
            reset_cache = 1'b0;
        end
    end
    always_ff @(posedge clk) begin 
        if(reset) begin
            reset_cnt <= reset_cnt_nxt;
        end else begin
            reset_cnt <= '0;
        end
    end
    assign update_meta_ram = (!reset && (
                             (state == IDLE && cached_request && hit) || // if hit
                             (state == IDLE && cached_request && !hit && !dirty) || // if not FLUSH but enter FETCH
                             (state == FLUSH && is_ok) ) ) || // if finish FLUSH
                             reset_cache; // if need to reset_cache
    assign set_addr = reset_cache ? 
                        reset_cnt[INDEX_BITS - 1 : 0] : 
                        get_index(dreq.addr);
    RAM_SinglePort #(
        .ADDR_WIDTH(INDEX_BITS),
        .DATA_WIDTH($bits(set_t)),
        .BYTE_WIDTH($bits(set_t)),
        .MEM_TYPE(0),
        .READ_LATENCY(0)
    ) meta_ram (
        .clk,
        .en(update_meta_ram),
        .addr(set_addr),
        .strobe('1),
        .wdata(set_new),
        .rdata(set)
    );
    // get meta & compose meta_new & compose set_new
    counter_t max;
    u1 is_replaced;
    counter_t pos;
    always_comb begin 
        {hit, max, is_replaced, pos} = '0;
        // try to hit and find pos
        for(int i = 0; i < ASSOCIATIVITY; i++) begin
            if(set.meta[i].valid && set.meta[i].tag == get_tag(dreq.addr)) begin 
                hit = 1'b1;
                pos = i[COUNTER_BITS - 1 : 0];
                break;
            end
        end
        // if not hit, find replacement using LRU
        if(!hit) begin
            is_replaced = 1'b1;
            for(int j = 0; j < ASSOCIATIVITY; j++) begin
                if(!set.meta[j].valid) begin 
                    pos = j[COUNTER_BITS - 1 : 0];
                    break;
                end else if(set.meta[j].valid && max < set.meta[j].age) begin 
                    max = set.meta[j].age;
                    pos = j[COUNTER_BITS - 1 : 0];
                end
            end
        end
        // get meta
        meta = set.meta[pos];
        // compose meta_new
        meta_new.valid = '1;
        meta_new.age   = '0;
        if(is_replaced) begin 
            meta_new.dirty = is_write;
            meta_new.tag   = get_tag(dreq.addr);
        end else begin 
            meta_new.dirty = meta.dirty ? meta.dirty : is_write;
            meta_new.tag   = meta.tag;
        end
        // compose set_new
        if(reset_cache) begin
            set_new = '0;
        end else begin
            for(int l = 0; l < ASSOCIATIVITY; l++) begin
                set_new.cnt = pos;
                if(l[COUNTER_BITS - 1 : 0] == pos) begin
                    set_new.meta[l] = meta_new;
                end else begin
                    set_new.meta[l].valid = set.meta[l].valid;
                    set_new.meta[l].dirty = set.meta[l].dirty;
                    set_new.meta[l].age = (set.meta[l].valid && set.meta[l].age < set.meta[pos].age) ?
                                            set.meta[l].age + 1'b1 : set.meta[l].age; 
                                            // recursively do this will not add 1 because it's set to 0
                    set_new.meta[l].tag = set.meta[l].tag;
                end
            end
        end
    end
    // fetch word & update data_cache
    u1 update_data_ram;
    offset_t flush_offset, flush_offset_nxt, fetch_offset, fetch_offset_nxt;
    logic[$clog2(SET_NUM * ASSOCIATIVITY * WORDS_PER_LINE) - 1 : 0] data_addr;
    assign update_data_ram = (state == IDLE && hit && is_write) || // if hit and write data
                             (state == FETCH && cresp.ready); // if fetch and update data
    always_comb begin
        flush_offset_nxt = '0;
        if(state == FLUSH && !cresp.ready) begin 
            flush_offset_nxt = flush_offset;
        end else if(state == FLUSH && cresp.ready && !is_ok) begin
            flush_offset_nxt = flush_offset + 1'b1;
        end
    end
    always_ff @(posedge clk) begin 
        if(reset) begin 
            flush_offset <= '0;
        end else begin
            flush_offset <= flush_offset_nxt;
        end
    end
    always_comb begin
        fetch_offset_nxt = '0;
        if(state == FETCH && !cresp.ready) begin 
            fetch_offset_nxt = fetch_offset;
        end else if(state == FETCH && cresp.ready && !is_ok) begin 
            fetch_offset_nxt = fetch_offset + 1'b1;
        end
    end
    always_ff @(posedge clk) begin 
        if(reset) begin 
            fetch_offset <= '0;
        end else begin
            fetch_offset <= fetch_offset_nxt;
        end
    end
    u1 placehoder;
    always_comb begin
        {placehoder, data_addr} = '0;
        if((state == IDLE && cached_request && hit)) begin 
            {placehoder, data_addr} = ({5'b0, set_addr} * 'd2 + {7'b0, pos}) * 'd16 + {5'b0, get_offset(dreq.addr)};
        end else if(state == FLUSH) begin 
            {placehoder, data_addr} = ({5'b0, set_addr} * 'd2 + {7'b0, pos}) * 'd16 + {5'b0, flush_offset};
        end else if(state == FETCH) begin 
            {placehoder, data_addr} = ({5'b0, set_addr} * 'd2 + {7'b0, pos}) * 'd16 + {5'b0, fetch_offset};
        end
    end
    RAM_SinglePort #(
        .ADDR_WIDTH($clog2(SET_NUM * ASSOCIATIVITY * WORDS_PER_LINE)),
        .DATA_WIDTH($bits(word_t)),
        .BYTE_WIDTH($bits(word_t)),
        .MEM_TYPE(0),
        .READ_LATENCY(0)
    ) data_ram (
        .clk,
        .en(update_data_ram),
        .addr(data_addr),
        .strobe('1),
        .wdata(word_new),
        .rdata(word)
    );
    // compose word_new
    always_comb begin 
        word_new = '0;
        if(state == IDLE && hit) begin 
            word_new = word;
            for(int i = 0; i < 8; i++) begin 
                if(dreq.strobe[i]) begin 
                    word_new[(8*(i+1)-1)-:8] = dreq.data[(8*(i+1)-1)-:8];
                end
            end
        end else if(state == FETCH && cresp.ready) begin 
            word_new = cresp.data;
        end
    end


    /**
     * creq&dresp driver
     */
    // creq
    assign creq.valid = (state == FLUSH) || (state == FETCH) || (state == DIRECT_FETCH);
    assign creq.is_write = (state == FLUSH) || (state == DIRECT_FETCH && is_write);
    always_comb begin
        creq.addr = {get_tag(dreq.addr), get_index(dreq.addr), 7'b0};
        if(state == FLUSH) begin 
            creq.addr = {meta.tag, get_index(dreq.addr), 7'b0};
        end else if(uncached_request) begin 
            creq.addr = dreq.addr;
        end
    end
    always_comb begin
        creq.size = MSIZE8;
        creq.len  = MLEN16;
        creq.burst = AXI_BURST_INCR;
        creq.data = word;
        creq.strobe = '1;
        if(uncached_request) begin 
            creq.size = dreq.size;
            creq.len  = MLEN1;
            creq.burst = AXI_BURST_FIXED;
            creq.data = dreq.data;
            creq.strobe = dreq.strobe;
        end
    end
    // dresp
    assign dresp.addr_ok = (cached_request || uncached_request) && (state == IDLE);
    assign dresp.data_ok = ((state == IDLE && cached_request && hit) || (state == DIRECT_FETCH && is_ok));
    always_comb begin 
        dresp.data = word;
        if(uncached_request) begin 
            dresp.data = cresp.data;
        end
    end


`else

	typedef enum u2 {
		IDLE,
		FETCH,
		READY,
		FLUSH
	} state_t /* verilator public */;

	// typedefs
    typedef union packed {
        word_t data;
        u8 [7:0] lanes;
    } view_t;

    // typedef u4 offset_t;

    // registers
    state_t    state /* verilator public_flat_rd */;
    dbus_req_t req;  // dreq is saved once addr_ok is asserted.
    offset_t   offset;

    // wires
    offset_t start;
    assign start = dreq.addr[6:3];

    // the RAM
    struct packed {
        logic    en;
        strobe_t strobe;
        word_t   wdata;
    } ram;
    word_t ram_rdata;

    always_comb
    unique case (state)
    FETCH: begin
        ram.en     = 1;
        ram.strobe = 8'b11111111;
        ram.wdata  = cresp.data;
    end

    READY: begin
        ram.en     = 1;
        ram.strobe = req.strobe;
        ram.wdata  = req.data;
    end

    default: ram = '0;
    endcase

    RAM_SinglePort #(
		.ADDR_WIDTH(4),
		.DATA_WIDTH(64),
		.BYTE_WIDTH(8),
		.READ_LATENCY(0)
	) ram_inst (
        .clk(clk), .en(ram.en),
        .addr(offset),
        .strobe(ram.strobe),
        .wdata(ram.wdata),
        .rdata(ram_rdata)
    );

    // DBus driver
    assign dresp.addr_ok = state == IDLE;
    assign dresp.data_ok = state == READY;
    assign dresp.data    = ram_rdata;

    // CBus driver
    assign creq.valid    = state == FETCH || state == FLUSH;
    assign creq.is_write = state == FLUSH;
    assign creq.size     = MSIZE8;
    assign creq.addr     = req.addr;
    assign creq.strobe   = 8'b11111111;
    assign creq.data     = ram_rdata;
    assign creq.len      = MLEN16;
	assign creq.burst	 = AXI_BURST_INCR;

    // the FSM
    always_ff @(posedge clk)
    if (~reset) begin
        unique case (state)
        IDLE: if (dreq.valid) begin
            state  <= FETCH;
            req    <= dreq;
            offset <= start;
        end

        FETCH: if (cresp.ready) begin
            state  <= cresp.last ? READY : FETCH;
            offset <= offset + 1;
        end

        READY: begin
            state  <= (|req.strobe) ? FLUSH : IDLE;
        end

        FLUSH: if (cresp.ready) begin
            state  <= cresp.last ? IDLE : FLUSH;
            offset <= offset + 1;
        end

        endcase
    end else begin
        state <= IDLE;
        {req, offset} <= '0;
    end

`endif

endmodule

`endif
