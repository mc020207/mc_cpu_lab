`ifndef __DIVU_SV
`define __DIVU_SV

`ifdef VERILATOR

`else

`endif

module divu
	import common::*;
	import pipes::*;(
    input logic clk,
    input u64 srca, srcb,
	output u64 result,
    output u64 rem,
    output logic data_ok,
    input valid
);
    //u64 a=srca,b=srcb;
    int i=0;
    //int j=0;
    logic waiting;
    //u64 debug,debug1;
    always_ff @( posedge clk ) begin
        if (valid) begin
            if (i==0&&waiting==0) begin
                data_ok=0;
                result=0;
                rem=0;
                i=1;
            end
            if (waiting==1) begin
                waiting=0;
                result=0;
                rem=0;
                i=0;
                waiting=0;
                data_ok=0;
            end
            if (i==65) begin
                //if (srca[63]!=srcb[63]) result=0-$signed(result);
                data_ok=1;
                i=0;
                waiting=1;
            end
            if (i>=1) begin
                //j=i;
                if (i==1) rem=0;
                //debug=rem;
                rem=(rem<<1)+{63'b0,srca[64-i]};
                //debug1=rem;
                result=result<<1;
                if (rem>=srcb) begin
                    rem-=srcb;
                    result+=1;
                end
                i+=1; 
            end
        end
        else begin
            result=0;
            rem=0;
            i=0;
            waiting=0;
            data_ok=0;
        end
    end
endmodule

`endif
