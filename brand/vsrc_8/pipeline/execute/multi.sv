`ifndef __MULTI_SV
`define __MULTI_SV

`ifdef VERILATOR

`else

`endif

module multi
	import common::*;
	import pipes::*;(
    input logic clk,
    input u64 srca, srcb,
	output u64 result,
    output logic data_ok,
    input valid
);
    //u64 b=srcb;
    //u64 add;
    int i=0;
    logic waiting=0;
    always_ff @( posedge clk ) begin
        if (valid) begin
            if (i==0&&waiting==0) begin
                result=0;
                //b=srcb;
                i=1;
                data_ok=0;
            end
            if (waiting==1) begin
                i=0;
                data_ok=0;
                waiting=0;
                result=0;
            end
            if (i==65) begin
                data_ok=1;
                i=0;
                waiting=1;
            end
            if (i>=1) begin
                //b=(srcb>>i);
                //add=srca<<i;
                if (((srcb>>i)&1)==1) result+=(srca<<i);
                i+=1;
            end 
        end
        else begin
            i=0;
            data_ok=0;
            waiting=0;
            result=0;
        end
    end
endmodule

`endif
