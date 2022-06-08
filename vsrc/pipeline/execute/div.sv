`ifndef __DIV_SV
`define __DIV_SV

`ifdef VERILATOR

`else

`endif

module div
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
    //int debug=0;
    logic waiting;
    always_ff @( posedge clk ) begin
        if (valid) begin
            if (i==0&&waiting==0) begin
                data_ok=0;
                result=0;
                rem={64{srca[63]}};
                i=1;
            end
            if (waiting==1) begin
                data_ok=0;
                result=0;
                rem={64{srca[63]}};
                i=1;
                waiting=0;
            end
            if (i==65) begin
                data_ok=1;
                i=0;
                waiting=1;
            end
            if (i>=1) begin
                if (i<=2) rem={64{srca[63]}};
                result=result<<1;
                //j=i;
                rem=(rem<<1)+{63'b0,srca[64-i]};
                //if (rem==0) debug+=1;
                if (rem!=0&&$signed(rem)>0&&$signed(srcb)>0) begin
                    if ($signed(rem-srcb)>=0) begin
                        rem-=srcb;
                        result+=1;
                    end
                end
                else if (rem!=0&&$signed(rem)<0&&$signed(srcb)>0) begin
                    if ($signed(rem+srcb)<=0) begin
                        rem+=srcb;
                        result+=1;
                    end
                end
                if (rem!=0&&$signed(rem)>0&&$signed(srcb)<0) begin
                    if ($signed(rem+srcb)>=0) begin
                        rem+=srcb;
                        result+=1;
                    end
                end
                if (rem!=0&&$signed(rem)<0&&$signed(srcb)<0) begin
                    if ($signed(rem-srcb)<=0) begin
                        rem-=srcb;
                        result+=1;
                    end
                end
                i+=1;
            end
        end
        else begin
            result=0;
            i=0;
            waiting=0;
        end
    end
endmodule

`endif
