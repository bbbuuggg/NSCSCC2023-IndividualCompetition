`include "defines.v"

module regfile(
	
	input wire clk,
	input wire rst,
	
	input wire we,//写使能
	input wire [`RegAddrBus] waddr,
	input wire [`RegBus] wdata,
	input wire [`RegAddrBus] pre_waddr,
	input wire [`RegBus] pre_wdata,
	input wire pre_we,
	//r1
	input wire re1,//读使能
	input wire [`RegAddrBus] raddr1,
	(*mark_debug = "true"*)output reg [`RegBus]     rdata1,
	//r2
	input wire  re2,
	input wire [`RegAddrBus] raddr2,
	(*mark_debug = "true"*)output reg [`RegBus] rdata2

);
reg[`RegBus] regs[0:`RegNum-1];//32个32位寄存器
(*mark_debug = "true"*)wire[31:0] watch_zero_0 = regs[0];
(*mark_debug = "true"*)wire[31:0] watch_at_1 = regs[1];
(*mark_debug = "true"*)wire[31:0] watch_v0_2 = regs[2];
(*mark_debug = "true"*)wire[31:0] watch_v1_3 = regs[3];
(*mark_debug = "true"*)wire[31:0] watch_a0_4 = regs[4];
(*mark_debug = "true"*)wire[31:0] watch_a1_5 = regs[5];
(*mark_debug = "true"*)wire[31:0] watch_a2_6 = regs[6];
(*mark_debug = "true"*)wire[31:0] watch_a3_7 = regs[7];
(*mark_debug = "true"*)wire[31:0] watch_t0_8 = regs[8];
(*mark_debug = "true"*)wire[31:0] watch_t1_9 = regs[9];
(*mark_debug = "true"*)wire[31:0] watch_t2_10 = regs[10];
(*mark_debug = "true"*)wire[31:0] watch_t3_11 = regs[11];
(*mark_debug = "true"*)wire[31:0] watch_t4_12 = regs[12];
(*mark_debug = "true"*)wire[31:0] watch_t5_13 = regs[13];
(*mark_debug = "true"*)wire[31:0] watch_t6_14 = regs[14];
(*mark_debug = "true"*)wire[31:0] watch_t7_15 = regs[15];
(*mark_debug = "true"*)wire[31:0] watch_s0_16 = regs[16];
(*mark_debug = "true"*)wire[31:0] watch_s1_17 = regs[17];
(*mark_debug = "true"*)wire[31:0] watch_s2_18 = regs[18];
(*mark_debug = "true"*)wire[31:0] watch_s3_19 = regs[19];
(*mark_debug = "true"*)wire[31:0] watch_s4_20 = regs[20];
(*mark_debug = "true"*)wire[31:0] watch_s5_21 = regs[21];
(*mark_debug = "true"*)wire[31:0] watch_s6_22 = regs[22];
(*mark_debug = "true"*)wire[31:0] watch_s7_23 = regs[23];
(*mark_debug = "true"*)wire[31:0] watch_t8_24 = regs[24];
(*mark_debug = "true"*)wire[31:0] watch_t9_25 = regs[25];
(*mark_debug = "true"*)wire[31:0] watch_26 = regs[26];
(*mark_debug = "true"*)wire[31:0] watch_27 = regs[27];
(*mark_debug = "true"*)wire[31:0] watch_gp_28 = regs[28];
(*mark_debug = "true"*)wire[31:0] watch_sp_29 = regs[29];
(*mark_debug = "true"*)wire[31:0] watch_fp_30 = regs[30];
(*mark_debug = "true"*)wire[31:0] watch_ra_31 = regs[31];

integer i;
	always @ (posedge clk) begin//写
		if(rst == `RstEnable)begin
			for(i = 0; i<32;i = i + 1)begin
				regs[i] <= `ZeroWord;
				end
		end
		else begin
			if((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin//waddr != 5'h0即空地址
				regs[waddr] <= wdata;
			end
		end
	end
	
	always @ (posedge clk) begin//读1
		if(rst == `RstEnable) begin
			rdata1 <= `ZeroWord;
		end else if(raddr1 == `RegNumLog2'h0) begin
			rdata1 <= `ZeroWord;
		end else if((raddr1 == waddr) && (we == `WriteEnable) && (re1 == `ReadEnable)) begin//若读写相同则直接输出
			rdata1 <= wdata;
		end else if(re1 == `ReadEnable)begin//从寄存器中读值
			rdata1 <= regs[raddr1];
		end else begin
			rdata1 <= `ZeroWord;
		end
	end
	
	always @ (posedge clk) begin//读2
		if(rst == `RstEnable) begin
			rdata2 <= `ZeroWord;
		end else if(raddr2 == `RegNumLog2'h0) begin
			rdata2 <= `ZeroWord;
		end else if((raddr2 == waddr) && (we == `WriteEnable) && (re2 == `ReadEnable)) begin//写值
			rdata2 <= wdata;
		end else if(re2 == `ReadEnable)begin//从寄存器中读值
			rdata2 <= regs[raddr2];
		end else begin
			rdata2 <= `ZeroWord;
		end
	end
	
endmodule