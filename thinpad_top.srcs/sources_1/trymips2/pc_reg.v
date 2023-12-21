`include "defines.v"

module pc_reg(
	input wire clk,
	input wire rst,
	//来自控制模块的信息
	// input wire[5:0]               stall,
	// input wire                    flush,
	input wire              stall,
	// input wire[`RegBus]           new_pc,
	input wire baseram_finish,
	
	input wire                    branch_flag_i,//译码阶段信号
	input wire[`RegBus]           branch_target_address_i,//跳转目的地址
	input wire load_baseram,
	input wire store_baseram,
	input wire pre_load_baseram,
	input wire [2:0]cnt_o,
	input wire [2:0]scnt_o,
	input wire  bingo,
	output reg[`InstAddrBus] pc,
	output reg[`InstAddrBus] pre_pc,
	output reg pre_ce

);
	reg ce;
	reg stall_delay;
	reg stall_delay2;
	reg baseram_finish_delay;
	always @ (posedge clk) begin
		if(rst == `RstEnable) begin//复位禁用存储芯片
			pre_ce <= `ChipDisable;      
		end else begin
			pre_ce <= `ChipEnable; //指令存储芯片使能
		end
	end
	
	always @ (posedge clk) begin
		if (pre_ce == `ChipDisable) begin
			pre_pc <= 32'h80000000;//禁用时pc赋值为0
		// end else begin 
			// if(flush == 1'b1) begin
				// pc <= new_pc;//例程序入口
		// end else if(stall_delay)begin
				// pre_pc <= pre_pc;
		end else if(stall ) begin
				pre_pc<= pre_pc;
	    end else if(store_baseram || pre_load_baseram ||cnt_o == 3'd1 || cnt_o == 3'd2 
					|| scnt_o == 3'd1 || scnt_o == 3'd2 || scnt_o == 3'd3 || bingo)begin//|| cnt_o == 3'd3
				pre_pc <= pre_pc;
		end else if(cnt_o == 3'd3)begin
				pre_pc <= pre_pc + 4'h4;
		end else if(branch_flag_i == `Branch && baseram_finish_delay) begin//&& baseram_finish  if(stall == `NoStop ) 
				pre_pc <= branch_target_address_i ;
		end else if(branch_flag_i == `Branch && !load_baseram) begin
				pre_pc <= branch_target_address_i + 4'h4;
		end else  begin
			pre_pc <= pre_pc + 4'h4;//顺序取值
		end
	end 
	always @ (posedge clk) begin
		if(stall) begin
			ce <= ce;
			pc <= pc; 
		end else if(store_baseram || pre_load_baseram || cnt_o == 3'd1 || cnt_o == 3'd2 
				|| scnt_o == 3'd1 || scnt_o == 3'd2 || scnt_o == 3'd3 || bingo)begin//|| cnt_o == 3'd3
			pc <= pc; 
			ce <= ce;
		end else if(cnt_o == 3'd3)begin//baseram_finish?
			pc <= pc + 4'h4;
			ce <= ce;
		end else if(branch_flag_i == `Branch) begin
			pc <= branch_target_address_i;
			ce <= ce;
		end else begin
			ce <= pre_ce;
			pc <= pre_pc; 
		end
	end
	always @ (posedge clk) begin
		     stall_delay <= stall;
			 baseram_finish_delay <= baseram_finish;
			 stall_delay2 <= stall_delay;
	end
endmodule