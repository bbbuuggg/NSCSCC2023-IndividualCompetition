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
	input wire id_pre_branch,
	input wire[`RegBus]           branch_target_address_i,//跳转目的地址
	input wire pre_exe_ls,
	
	input wire load_baseram,
	input wire store_baseram,
	input wire store_extram,
	input wire ex_base_ram,
	input wire ex_ext_ram,
	input wire pre_load_baseram,
	input wire pre_load_extram,
	input wire store_bfd,
	input wire pre_load_bfd,
	input wire [2:0]cnt_o,
	input wire [2:0]cnt_bingo_o,
	input wire [2:0]scnt_o,
	input wire [2:0]cnt_ext_o,
	input wire [2:0]scnt_ext_o,
	output reg [2:0]cnt_pc_o,
	input wire  bingo,
	output reg[`InstAddrBus] pc,
	output reg[`InstAddrBus] pre_pc,
	output reg pre_ce

);
	reg ce;
	reg bingo_delay;
	reg stall_delay;
	reg stall_delay2;
	reg baseram_finish_delay;
	// reg[`InstAddrBus] pre_ce;
	// reg[`InstAddrBus] pre_pc;
	reg branch_flag_i_delay;
	reg branch_flag_i_delay1;
	
	
	reg cnt_pc_r;
	always @(posedge clk) begin
		if(rst) begin     
			cnt_pc_o <= 3'd0;  
		end else if(cnt_pc_o == 3'd1) begin         
			cnt_pc_o <=  3'd0;
		end  else if(!stall) begin    
			cnt_pc_o <= cnt_pc_o + 1'b1;
		end
	end
	
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
		end else if(stall || bingo_delay) begin
				pre_pc<= pre_pc;
		end else if(branch_flag_i == `Branch ) begin//&& !load_baseram
				pre_pc <= branch_target_address_i ; //
		end else if(cnt_o == 3'd4 && scnt_o == 3'd2)begin
			pre_pc <= pre_pc - 3'd4;
		end else if((scnt_o != 3'd0 && scnt_o != 3'd4 ) || (cnt_o != 3'd0 && cnt_o != 3'd4  && !branch_flag_i_delay1)) begin
				pre_pc<= pre_pc;//
		end else if(cnt_pc_o == 3'd1) begin
			pre_pc <= pre_pc + 4'h4;//顺序取值
		end else begin
			pre_pc<= pre_pc;
		end
	end 
	// always @ (posedge clk) begin
		// if (pre_ce == `ChipDisable) begin
			// pre_pc <= 32'h80000000;//禁用时pc赋值为0
		// // end else begin 
			// // if(flush == 1'b1) begin
				// // pc <= new_pc;//例程序入口
		// // end else if(stall_delay)begin
				// // pre_pc <= pre_pc;
		// end else if(stall) begin
				// pre_pc<= pre_pc;
	    // // end else if(store_baseram || store_extram || pre_load_baseram || pre_load_extram || cnt_o != 3'd0 
					// // || scnt_o == 3'd1 || scnt_o == 3'd2 || scnt_o == 3'd3 )begin//|| cnt_o == 3'd3 (cnt_o == 3'd2 
				// // if((cnt_bingo_o != 3'd0 || bingo)&& cnt_o != 3'd3 && cnt_o != 3'd2)begin
					// // pre_pc <= pre_pc;
				// // end else if(cnt_o == 3'd2 && cnt_bingo_o == 3'd0)begin
					// // pre_pc <= pre_pc;
				// // end else begin
					// // pre_pc <= pre_pc + 4'h4;
				// // end
		// // // end else if(pre_exe_ls)begin//|| cnt_o == 3'd3 && !bingo || (id_pre_branch && !branch_flag_i)
				// // pre_pc <= pre_pc;
		// // end else if(cnt_o == 3'd3)begin
				// // pre_pc <= pre_pc + 4'h4;
		// // end else if(branch_flag_i == `Branch && baseram_finish_delay) begin//&& baseram_finish  if(stall == `NoStop ) 
				// // pre_pc <= branch_target_address_i ;
		// end else if(branch_flag_i == `Branch && !load_baseram) begin
				// pre_pc <= branch_target_address_i ; //+ 4'h4
		// end else  begin
			// pre_pc <= pre_pc + 4'h4;//顺序取值
		// end
	// end 
	always @ (posedge clk) begin
		if(stall) begin
			ce <= ce;
			pc <= pc; 
		// end else if(store_baseram || store_extram || pre_load_baseram || pre_load_extram || cnt_o == 3'd1 || cnt_o == 3'd2 
				// || scnt_o == 3'd1 || scnt_o == 3'd2 || scnt_o == 3'd3 || bingo)begin//|| cnt_o == 3'd3
			// pc <= pc; 
			// ce <= ce;
		// // end else if(cnt_o == 3'd3)begin//baseram_finish?
			// // pc <= pc + 4'h4;
			// // ce <= ce;
		end else if(branch_flag_i == `Branch) begin
			pc <= branch_target_address_i - 4'h4;
			ce <= ce;
		end else begin
			ce <= pre_ce;
			pc <= pre_pc; 
		end
	end
	
	// always @(*)begin
		// if(rst)begin
			// pre_pc = `ZeroWord;
			// pre_ce = `ZeroWord;
		// // end else if( store_extram || store_baseram || pre_load_baseram || pre_load_extram )begin
			// // pre_ce = pre_ce;
			// // pre_pc = 32'h34000000;
		// // end else if(branch_flag_i == `Branch ) begin//&& !load_baseram
				// // pre_pc = `ZeroWord;//branch_target_address_i + 4'h4
				// // pre_pc = pre_pc;
		// end else begin
			// pre_ce = pre_ce;
			// pre_pc = pre_pc;
		// end
	// end
	always @ (posedge clk) begin
		stall_delay <= stall;
		baseram_finish_delay <= baseram_finish;
		stall_delay2 <= stall_delay;
		bingo_delay <= bingo;
		branch_flag_i_delay <= branch_flag_i;
		branch_flag_i_delay1 <= branch_flag_i_delay ;
	end
endmodule