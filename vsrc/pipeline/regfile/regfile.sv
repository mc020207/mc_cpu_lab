`ifndef __REGFILE_SV
`define __REGFILE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/config.sv"
`else

`endif
module regfile 
	import common::*;
	import config_pkg::*;
#(
	parameter READ_PORTS = AREG_READ_PORTS,
	parameter WRITE_PORTS = AREG_WRITE_PORTS
) (
	input logic clk, reset,
	
	input creg_addr_t [READ_PORTS-1:0] ra1, ra2,
	output u64 [READ_PORTS-1:0] rd1, rd2,

	input creg_addr_t [WRITE_PORTS-1:0] wa,
	input u1 [WRITE_PORTS-1:0] wvalid,
	input u64 [WRITE_PORTS-1:0] wd
);

	// 以下语句顺序不重要，并行的

	// 声明寄存器的该状态与下一个状态
	// 31个64位寄存器
	// typedef logic [63:0] u64定义了64位合并型数组
	// u64 [31:0]相当于31个64位数组，总体也是合并型的
	// 效果等同于：logic [31:0][63:0] regs
	/*1*/
	u64 [31:0] regs, regs_nxt;

	// 读
	// 从regs里读
	// typedef u5 creg_addr_t;即ra的范围为0~31，刚好对应32个寄存器
	// 遍历所有端口，将该端口(i)处于ra地址(第ra[i]个)的寄存器的内容(regs[ra[i]])读到该端口的rd(rd[i])
	/*2*/
	for (genvar i = 0; i < READ_PORTS; i++) begin
		assign rd1[i] = regs[ra1[i]];
		assign rd2[i] = regs[ra2[i]];
	end
	
	// 写准备
	// 写进regs_nxt里
	// 具体：赋值下一个状态+写数据（有的话）
	// 遍历32个寄存器
	for (genvar i = 1; i < 32; i++) begin
		always_comb begin
			// 赋值下一个状态
			regs_nxt[i] = regs[i];
			// 遍历写端口
			for (int j = 0; j < WRITE_PORTS; j++) begin
				// 看是否激活写操作+是否写入该寄存器
				if (i == wa[j] && wvalid[j]) begin
					regs_nxt[i] = wd[j];
				end
			end
		end
	end
	// 写更新
	// 触发器的标准写法
	// 由于是合并型数组，因此可以直接赋值regs <= regs_nxt;
	/*3*/
	always_ff @(posedge clk) begin
		if (reset) begin
			regs <= '0;
		end else begin
			regs <= regs_nxt;
			// 0号寄存器存0
			regs[0] <= '0;
		end
	end

endmodule


`endif


/* 1

	2种数组：
	
	一、定义
	合并型数组：在内存中连续存放的数组
	非合并型数组：在内存中非连续存放的数组
	bit [3][7:0]b_pack;//合并型
	bit [7:0]b_unpack[3];//非合并型

	二、详释
	b_unpack实际会占据3个WORD的存储空间。
	原因： 很多SV仿真器在存放数组元素时使用32比特的字边界，所有byte,shortint,int都是存在1个字中，而longint则存放到两个字中。
	但是b_pack则只会占据1个WORD的存储空间。原因是合并型数组在内存中连续存放。

	三、区别
	存储方式不同
	赋值方式不同
		合并型数组赋值时不需要使用单引号 '
		非合并型数组赋值时需要使用单引号
	初始化方式不同
		合并型数组初始化时，同向量初始化一致
		logic [3:0][7:0] a=32'h0;
		非合并型数组初始化时，则需要通过`{}来对数组的每一个维度进行赋值
		int d [0:1][0:3]='{'{0,1,2,3},'{4,5,6,7}};
	
	四、注意
	非合并型数组无法直接赋值给合并型数组
	合并型数组也无法直接赋值给非合并型数组

	五、混合数组
	其实看混合数组时候就是先看右侧的非合并数组，再看左侧的合并数组，看数组时都是从左往右看，那么总结起来就是逆时针规则了。

	六、typedef
	typedef logic logic_7_0_t [7:0];  // Unpacked array of logic, which is OK
	typedef logic [7:0] logic_7_0_t;  // Packed array of logic, which is OK

*/

/*2

	genvar与for循环————好用！！！

*/

/*3

	logic, always_ff与always_comb

	Verilog中我们有wire 和reg，当然reg可能对应组合逻辑中的信号线，也可能对应时序逻辑中的flip-flop。
	在System Verilog中我们可以把wire和reg替换成logic，至于综合成什么，交给综合工具吧。

	不过作为数字电路设计工程师，代码写下之前你就应该知道综合成组合逻辑还是时序逻辑。
	你可以继续使用always，组合逻辑使用always @(*)，时序逻辑用always @(posedge clk)之类。
	或者更进一步，我们使用System Verilog里的always_ff和always_comb。
	顾名思义，always_ff是要综合成时序逻辑中的flip-flop，always_comb是综合成组合逻辑。
	如果实际综合结果不是名字所提示的那样，那么工具会报错的，这时你可以有改正的机会。比如下面这段代码：
	always_comb
	if (en)
		a = b;
	对应的电路是个latch，和组合电路的期望不符，会得到compiler的报错。
	tips: if永远加else，case永远加default

*/

