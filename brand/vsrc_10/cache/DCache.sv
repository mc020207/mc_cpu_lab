`ifndef __DCACHE_SV
`define __DCACHE_SV

`ifdef VERILATOR
`include "include/common.sv"
/* You should not add any additional includes in this file */
`endif

module DCache 
	import common::*; #(
		/* You can modify this part to support more parameters */
		/* e.g. OFFSET_BITS, INDEX_BITS, TAG_BITS */
	)(
	input logic clk, reset,

	input  dbus_req_t  dreq,
    output dbus_resp_t dresp,
    output cbus_req_t  creq,
    input  cbus_resp_t cresp
);

`ifndef REFERENCE_CACHE

	/* TODO: Lab3 Cache */
    typedef struct packed{
        u1 valid;
        u1 dirty;
        u54 tag;
    } meta_t;
    typedef enum logic[2:0] {
        COMPARETAG,READY,FETCH,WRITEBACK,FINAL,WRITEREADY
    }state_t;
    typedef struct packed{
        u1 cnt;
        meta_t meta1;
        meta_t meta2;
    } meta_union;
    // control meta_ram
    meta_union metaread,metawrite,metarecord;
    //meta_t meta_choose;
    u1 meta_valid;
    u1 meta_strobe;
    u3 meta_addr;
    // control data_ram
    word_t dataread,datawrite;
    u1 data_valid;
    u8 data_strobe;
    u8 data_addr;

    state_t state=COMPARETAG;
    RAM_SinglePort #(
        .ADDR_WIDTH(8),
        .DATA_WIDTH(64),
        .BYTE_WIDTH(8),
        .MEM_TYPE(0),
        .READ_LATENCY(0)
    ) data_ram (
        .clk,  .en(data_valid),
        .addr(data_addr),
        .strobe(data_strobe),
        .wdata(datawrite),
        .rdata(dataread)
    );

    RAM_SinglePort #(
        .ADDR_WIDTH(3),
        .DATA_WIDTH($size(meta_union)),
        .BYTE_WIDTH($size(meta_union)),
        .MEM_TYPE(0),
        .READ_LATENCY(0)
    ) meta_ram (
        .clk,  .en(meta_valid),
        .addr(meta_addr),
        .strobe(meta_strobe),
        .wdata(metawrite),
        .rdata(metaread)
    );
    
    u1 uncache;
    u2 hit;// hit[1] 是否命中 hit[0] 命中编号
    u54 tag;
    u3 hash;
    u4 wordaddr;
    u4 index;
    u3 reset_metaindex=-1;
    u8 reset_dataindex=-1;
    assign tag=dreq.addr[63:10];
    assign hash=dreq.addr[9:7];
    assign wordaddr=dreq.addr[6:3];
    assign uncache=dreq.valid&(~dreq.addr[31]);
    
    assign dresp.data=reset?'0:(uncache?cresp.data:dataread);
    assign dresp.data_ok=reset?0:(uncache?cresp.ready:((state==READY&&dreq.strobe==0)||state==WRITEREADY))&dreq.valid;
    assign dresp.addr_ok=1;

    assign meta_valid=reset?1:((uncache)?0:dreq.valid&(~uncache));
    assign meta_addr=reset?reset_metaindex:hash;
    assign meta_strobe=(state==FETCH||reset/*||(state==WRITEREADY&&dreq.strobe!=0)*/)?1:0;
    //assign metawrite=replace?
    
    assign data_valid=reset?1:((uncache)?0:dreq.valid);
    assign data_addr=reset?reset_dataindex:(state==WRITEBACK||state==FETCH)?{hash,hit[0],index}:{hash,hit[0],wordaddr};
    assign data_strobe=(reset||state==FETCH)?8'b11111111:((((state==COMPARETAG||state==READY)&&hit[1])||state==FINAL)?dreq.strobe:0);
    assign datawrite=reset?'0:(state==FETCH)?cresp.data:dreq.data;

    assign creq.valid=(uncache|(state==FETCH)|(state==WRITEBACK))&dreq.valid;
    assign creq.addr=uncache?dreq.addr:((state==WRITEBACK)?{hit[0]?metarecord.meta2.tag:metarecord.meta1.tag,hash,7'b0}:{dreq.addr[63:7],7'b0});
    assign creq.is_write=uncache?(dreq.strobe!=0):(state==WRITEBACK);
    assign creq.size=uncache?(dreq.size):MSIZE8;
    assign creq.strobe=uncache?(dreq.strobe):8'b11111111;
    assign creq.data=uncache?(dreq.data):dataread;
    assign creq.len=uncache?MLEN1:MLEN16;
    assign creq.burst=uncache?AXI_BURST_FIXED:AXI_BURST_INCR;
    always_comb begin
        // unique case(state)
        //     COMPARETAG:begin
        //         metarecord=metaread;
        //         if(metaread.meta1.tag==tag) begin
        //             hit=2'b10;
        //             state_next=READY;
        //         end
        //         else if (metaread.meta2.tag==tag) begin
        //             hit=2'b01;
        //             state_next=READY;
        //         end
        //         else if (metaread.meta1.valid==0) begin
        //             hit=2'b00;
        //             state_next=FETCH;
        //         end
        //         else if (metaread.meta2.valid==0) begin
        //             hit=2'b01;
        //             state_next=FETCH;
        //         end
        //         else begin
        //             hit[0]=1'b0;
        //             hit[1]=metaread.cnt;
        //             state_next=(((~hit[1])&metaread.meta1.dirty)|(hit[1]&metaread.meta2.dirty))?WRITEBACK:FETCH;
        //         end
        //     end
        //     WRITEBACK : begin
        //         if (cresp.last) state_next=FETCH;
        //         else state_next=WRITEBACK;
        //     end
        //     FETCH : begin
        //         metawrite.cnt=!metarecord.cnt;
        //         if (hit[1]==0) begin
        //             metawrite.meta2=metarecord.meta2;
        //             metawrite.meta1={2'b10,tag};
        //         end
        //         if (cresp.last) state_next=COMPARETAG;
        //         else state_next=FETCH;
        //     end
        //     READY : begin
        //         state_next=COMPARETAG;
        //     end
        //     default : begin
                
        //     end
        // endcase
    end
    u1 debug;
    //u1 fetchwait=0;
    u64 debug2;
    assign debug2=64'h80028868;
    //assign debug=((dreq.addr[63:7])==debug2[63:7]);
    assign debug=(state==WRITEBACK);
    always_ff @( posedge clk ) begin
        if (reset) begin
            state<=COMPARETAG;
            // if(reset_metaindex[0]==X) reset_metaindex=0;
            // if(reset_dataindex[0]==X) reset_dataindex=0;
            reset_metaindex<=reset_metaindex+1;
            reset_dataindex<=reset_dataindex+1;
            metawrite.cnt<=0;
            metawrite.meta1.valid<=0;
            metawrite.meta1.dirty<=0;
            metawrite.meta1.tag<=0;
            metawrite.meta2.valid<=0;
            metawrite.meta2.dirty<=0;
            metawrite.meta2.tag<=0;
            //datawrite=0;
        end
        else if (~dreq.valid) begin
            state<=COMPARETAG;
        end
        else begin 
            //state_next<=state;
            unique case(state)
                COMPARETAG:begin
                    index<=0;
                    metarecord<=metaread;
                    if(metaread.meta1.tag==tag) begin
                        hit<=2'b10;
                        state<=READY;
                        //meta_choose<=metaread.meta1;
                    end
                    else if (metaread.meta2.tag==tag) begin
                        hit<=2'b11;
                        state<=READY;
                        //meta_choose<=metaread.meta2;
                    end
                    else if (metaread.meta1.valid==0) begin
                        hit<=2'b00;
                        state<=FETCH;
                        //meta_choose<=metaread.meta1;
                    end
                    else if (metaread.meta2.valid==0) begin
                        hit<=2'b01;
                        state<=FETCH;
                        //meta_choose<=metaread.meta2;
                    end
                    else begin
                        hit[0]<=1'b0;
                        hit[1]<=metaread.cnt;
                        state<=(((~hit[0])&metaread.meta1.dirty)|(hit[0]&metaread.meta2.dirty))?WRITEBACK:FETCH;
                        //meta_choose=hit[1]?metaread.meta2:metaread.meta1;
                    end
                end
                WRITEBACK : begin
                    if (cresp.last) begin
                        state<=FETCH;
                        index<=0;
                    end
                    else if (cresp.ready)begin
                        state<=WRITEBACK;
                        index<=index+1;
                    end 
                    else state<=WRITEBACK;
                end
                FETCH : begin
                    metawrite.cnt<=~metarecord.cnt;
                    if (hit[0]==0) begin
                        metawrite.meta2<=metarecord.meta2;
                        metawrite.meta1<={2'b11,tag};
                    end
                    else begin
                        metawrite.meta1<=metarecord.meta1;
                        metawrite.meta2<={2'b11,tag};
                    end
                    /*if (fetchwait) begin
                        state<=COMPARETAG;
                        fetchwait<=0;
                        index<=0;
                    end
                    else*/ if (cresp.last) begin
                        // state<=FETCH;
                        // fetchwait<=1;
                        state<=FINAL;
                        index<=0;
                    end
                    else if (cresp.ready)begin
                        state<=FETCH;
                        index<=index+1;
                        //fetchwait<=0;
                    end 
                    else begin
                        state<=FETCH;
                        //fetchwait<=0;
                    end 
                end
                FINAL:begin
                    index<=0;
                    state<=READY;
                end
                READY : begin
                    if (dreq.strobe==0) begin
                        state<=COMPARETAG;
                        hit<=2'b00; 
                    end
                    else begin
                        state<=WRITEREADY;
                        // if (hit[0]==0) begin
                        //     metawrite.meta2<=metarecord.meta2;
                        //     metawrite.meta1<={2'b11,metaread.meta1.tag};
                        // end
                        // else begin
                        //     metawrite.meta1<=metarecord.meta1;
                        //     metawrite.meta2<={2'b11,metaread.meta2.tag};
                        // end
                    end
                end
                WRITEREADY:begin
                    state<=COMPARETAG;
                    hit<=2'b00; 
                end
                default : begin
                    
                end
            endcase
        end 
        // if (dreq.valid) begin
        //     if (state==WRITEBACK||state==FETCH) begin
        //         if (cresp.last) index=-1;
        //         else if (cresp.ready) index+=1;
        //     end
        //     else index=-1;
        //     state=state_next;
        // end
        // else begin
        //     state=COMPARETAG;
        //     index=-1;
        // end
    end
/************************************************************************************/   
/************************************************************************************/   
/************************************************************************************/   
/************************************************************************************/   
/************************************************************************************/   
/************************************************************************************/   
/************************************************************************************/   
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

    typedef u4 offset_t;

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
