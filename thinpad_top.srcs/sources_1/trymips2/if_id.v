`include "defines.v"

module if_id(
	
	input wire clk,
	input wire rst,
	// input wire[5:0] stall,
	// input wire flush,
	input wire              stall,
	input wire baseram_finish,
	
	input wire load_baseram,
	input wire store_baseram,
	input wire store_extram,
	input wire ex_base_ram,
	input wire ex_ext_ram,
	input wire pre_load_baseram,
	input wire pre_load_extram,
	input wire store_bfd,
	input wire pre_load_bfd,
	input wire                    branch_flag_i,//译码阶段信号
	input wire[`RegBus]           branch_target_address_i,//跳转目的地址
	
	input wire related,
	
	output reg exe_ls,
	output wire bingo,//对baseram 使用store后紧接着用load
	input wire [`InstAddrBus] if_pc,//pc取得指令地址
	input wire [`InstBus] if_inst,//所取指令
	
	input wire [2:0]cnt_pc_o,
	
	output reg [2:0]cnt_o,
	output reg [2:0]cnt_bingo_o,
	output reg [2:0]scnt_o,
	output reg [2:0]cnt_ext_o,
	output reg [2:0]scnt_ext_o,
	output reg[`InstAddrBus] id_pc,
	output reg[`InstBus] id_inst
	
);
	reg[`InstAddrBus] id_pc1;
	reg[`InstBus] id_inst1;
	reg [`InstBus] id_inst_delay;//pc好像不用？
	reg [`InstAddrBus] id_pc_delay;
	reg delaysignal;
	reg delaysignal_bubble;
	reg delaysignal_use;
	reg sdelaysignal;
	reg sdelaysignal_bubble;
	reg sdelaysignal_use;
	reg exe_ls_delay;
	reg exe_store;
	reg exe_store_delay;
	reg exe_store_use;
	
	reg baseram_finish_delay;
	reg continuedelay;
	
	
	reg [`InstBus] id_inst_delay1;//pc好像不用？
	reg [`InstAddrBus] id_pc_delay1;
	reg branch_flag_i_delay;
	reg branch_flag_i_delay1;
	reg cnt_r;
	reg cnt_bingo_r;
	reg cnt_ext_r;
	reg cnt_branch_r;
	reg [2:0]cnt_branch_o;
	
	reg scnt_r;
	reg scnt_ext_r;
	reg signal; //在连续暂停两个周期后需要控制id_inst信号持续多一拍
	wire jump2;
	reg jump2_delay;
	reg jump2_delay1;
	reg store_baseram_delay;
	reg pre_is_store;
	reg pre_is_load;

	reg bingo_delay;
	reg bingo_delay2;
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			id_pc1 <= `ZeroWord; //复位pc地址置零
			id_inst1 <= `ZeroWord;//取空指
        end else if((cnt_pc_o == 3'd0 && !stall) || cnt_o == 3'd2 || scnt_o == 3'd2 || scnt_o == 3'd4 || branch_flag_i_delay1 && !(jump2 || jump2_delay1)) begin// || bingo_delay && !load_baseram || branch_flag_i_delay1
			id_pc1 <= id_pc1;
			id_inst1 <= 32'h34000000;
		end else if((cnt_o == 3'd4 && !stall) || (scnt_o == 3'd4 && !stall)) begin// || bingo_delay && !load_baseram || branch_flag_i_delay1
			id_pc1 <= id_pc_delay;
			id_inst1 <= id_inst_delay;
        end else if(stall == `NoStop && id_pc1 != `ZeroWord)begin//|| exe_ls;
            id_pc1 <= if_pc - 4'h4;
            id_inst1 <= if_inst;
		end else if(id_pc1 == `ZeroWord)begin//|| exe_ls;
            id_pc1 <= if_pc;
            id_inst1 <= if_inst;
        end else begin
            id_pc1 <= id_pc1;
            id_inst1 <= id_inst1;
        end
    end
	
	always @(*)begin
		if(rst)begin
			id_inst = `ZeroWord;
			id_pc = `ZeroWord;
		// end else if( store_extram || store_baseram || pre_load_baseram || pre_load_extram )begin
			// id_pc = id_pc;
			// id_inst = 32'h34000000;
		// end else if(related)begin
			// id_pc = id_pc_delay1;
			// id_inst = id_inst_delay1;
		end else begin
			id_pc = id_pc1;
			id_inst = id_inst1;
		end
	end
	
	always @ (posedge clk)begin
		if(rst == `RstEnable)begin
			id_inst_delay = `ZeroWord;
			id_pc_delay = `ZeroWord;
		end else if((pre_load_baseram && !stall) ||(cnt_o == 3'd1 && !stall && scnt_o == 3'd0) || (scnt_o == 3'd1 && !stall))begin//) || (branch_flag_i_delay1 && !stall) || (pre_load_extram && !stall) || (store_baseram && !stall) || (store_extram && !stall)
			id_inst_delay = if_inst;
			id_pc_delay = if_pc;
		end else if(cnt_o == 3'd4 || (scnt_o == 3'd4 && cnt_o == 3'd0) )begin//&& cnt_bingo_o == 3'd0   (cnt_o == 3'd3 && !bingo) || bingo_delay || scnt_o == 3'd3
			id_inst_delay = `ZeroWord;
			id_pc_delay = `ZeroWord;
		end else begin//if(exe_ls) begin
			id_inst_delay = id_inst_delay;
			id_pc_delay = id_pc_delay;
		end
	end
	
	always @ (posedge clk)begin
		if(rst == `RstEnable)begin
			id_inst_delay1 = `ZeroWord;
			id_pc_delay1 = `ZeroWord;
		// end else if((pre_load_baseram && !stall) || (pre_load_extram && !stall) || (store_baseram && !stall) || (store_extram && !stall))begin
			// id_inst_delay = if_inst;
			// // id_pc_delay <= id_pc +4'h4;
			// id_pc_delay = if_pc;
		// end else if((cnt_o == 3'd3 && !bingo) || bingo_delay || scnt_o == 3'd3)begin
			// id_inst_delay = `ZeroWord;
			// id_pc_delay = `ZeroWord;
		end else if( cnt_o == 3'd1 && !stall )begin
			id_inst_delay1 = id_inst_delay1;
			id_pc_delay1 = id_pc_delay1;
		end else if( scnt_o == 3'd1 && !stall)begin
			id_inst_delay1 = id_inst_delay1;
			id_pc_delay1 = id_pc_delay1;
		end else begin//if(exe_ls) begin
			id_inst_delay1 <= id_inst;
			id_pc_delay1 <= id_pc;
		end
	end
	
	always @ (posedge clk)begin
		if(rst == `RstEnable )begin
			delaysignal <= 1'b0;
		end else if(pre_load_baseram)begin//) || store_baseram
			delaysignal <= 1'b1;
		end else begin
			delaysignal <= 1'b0;
		end
	end
	always @ (posedge clk)begin
		if(rst == `RstEnable )begin
			sdelaysignal <= 1'b0;
		end else if(store_baseram)begin//) || store_baseram
			sdelaysignal <= 1'b1;
		end else begin
			sdelaysignal <= 1'b0;
		end
	end
	// always @ (posedge clk)begin
		// if(rst == `RstEnable )begin
			// bingo <= 1'b0;
		// end else if(exe_ls; && delaysignal_use)begin//) || store_baseram
			// bingo <= 1'b1;
		// end else begin
			// bingo <= 1'b0;
		// end
	// end
	assign jump2 = branch_flag_i && branch_flag_i_delay1;
	assign bingo = exe_store_use && (exe_ls && !exe_store);//(cnt_o != 3'd0 || scnt_o != 3'd0 || cnt_ext_o != 3'd0 || scnt_ext_o != 3'd0)
	always @ (posedge clk)begin
		delaysignal_bubble <= delaysignal;
		delaysignal_use <= delaysignal_bubble;
		sdelaysignal_bubble <= sdelaysignal;
		store_baseram_delay <= store_baseram;
		sdelaysignal_use <= sdelaysignal_bubble;
		pre_is_store <= sdelaysignal_use;
		pre_is_load <= delaysignal_use;
		signal <= stall;
		branch_flag_i_delay <= branch_flag_i;
		branch_flag_i_delay1 <= branch_flag_i_delay ;
		bingo_delay <= bingo;
		bingo_delay2 <= bingo_delay;
		jump2_delay <= jump2;
		jump2_delay1 <= jump2_delay;
		exe_ls_delay <= exe_ls;
		exe_store_delay <= exe_store;
		exe_store_use <= exe_store_delay;
		baseram_finish_delay <= baseram_finish;
		continuedelay <= baseram_finish_delay && branch_flag_i;
	end
	
	
	always @(posedge clk) begin
		if(rst) begin     
			cnt_o <= 3'd0;  
			cnt_r <= 1'b0;
		end else if(cnt_o == 3'd4) begin      
			cnt_r <= 1'b0;     
			cnt_o  <=  3'd0;
		end else if(pre_load_baseram) begin    
			cnt_r <= 1'b1;
			cnt_o  <=  3'd1;
		end  else if(cnt_r != 0 && !stall) begin    
			cnt_o <= cnt_o + 1'b1;
		end	else begin
			cnt_r <= cnt_r;
			cnt_o  <= cnt_o;
		end
	end
	
	always @(posedge clk) begin
		if(rst) begin     
			cnt_bingo_o <= 3'd0;  
			cnt_bingo_r <= 1'b0;
		end else if(cnt_bingo_o == 3'd7 || jump2_delay1) begin //|| jump2_delay1
			cnt_bingo_r <= 1'b0;     
			cnt_bingo_o  <=  3'd0;
		end else if((branch_flag_i_delay1 && !jump2_delay1)) begin//此时的二号延迟槽被放弃 
			cnt_bingo_r <= 1'b1;
			cnt_bingo_o  <=  3'd1;
		end  else if(cnt_bingo_r != 0 && !stall) begin    
			cnt_bingo_o <= cnt_bingo_o + 1'b1;
		end
	end
	
	
	always @(posedge clk) begin
		if(rst) begin     
			cnt_branch_o <= 3'd0;  
			cnt_branch_r <= 1'b0;
		end else if(cnt_branch_o == 3'd1) begin      
			cnt_branch_r <= 1'b0;     
			cnt_branch_o  <=  3'd0;
		end else if(branch_flag_i) begin    
			cnt_branch_r <= 1'b1;
			cnt_branch_o  <=  3'd1;
		end  else if(cnt_branch_r != 0) begin    
			cnt_branch_o <= cnt_branch_o + 1'b1;
		end
	end
	
	always @(posedge clk) begin
		if(rst) begin     
			cnt_ext_o <= 3'd0;  
			cnt_ext_r <= 1'b0;
		end else if(cnt_ext_o == 3'd1) begin      
			cnt_ext_r <= 1'b0;     
			cnt_ext_o  <=  3'd0;
		end else if(pre_load_extram ) begin//&& !stall 
			cnt_ext_r <= 1'b1;
			cnt_ext_o  <=  3'd1;
		end  else if(cnt_ext_r != 0) begin    
			cnt_ext_o <= cnt_ext_o + 1'b1;
		end
	end
	
	always @(posedge clk) begin
		if(rst) begin     
			scnt_o <= 3'd0;  
			scnt_r <= 1'b0;
		end else if(scnt_o == 3'd4) begin      
			scnt_r <= 1'b0;     
			scnt_o  <=  3'd0;
		end else if((store_baseram || store_bfd) && !stall) begin    
			scnt_r <= 1'b1;
			scnt_o  <=  3'd1;
		end  else if(scnt_r != 0) begin    
			scnt_o <= scnt_o + 1'b1;
		end
	end
	
	always @(posedge clk) begin
		if(rst) begin     
			scnt_ext_o <= 3'd0;  
			scnt_ext_r <= 1'b0;
		end else if(scnt_ext_o == 3'd1) begin      
			scnt_ext_r  <= 1'b0;     
			scnt_ext_o  <=  3'd0;
		end else if(store_extram && !stall) begin    
			scnt_ext_r  <= 1'b1;
			scnt_ext_o  <=  3'd1;
		end  else if(scnt_ext_r  != 0) begin    
			scnt_ext_o <= scnt_ext_o + 1'b1;
		end
	end
	
	wire[5:0] op = id_inst1[31:26];//指令码
	wire[15:0] addr = id_inst1[15:0];
	// wire[4:0] shamt = id_inst_delay[10:6];//位移量
	// wire[5:0] func = id_inst_delay[5:0];//功能码
	
	always @ (*) begin
		if(rst == `RstEnable)begin
			exe_ls = 1'b0;
		end else if(op == `EXE_SB || op == `EXE_SW || op == `EXE_LW || op == `EXE_LB)begin//先初始化) && (addr >= 16'h8000) && (addr < 16'h8080)
			exe_ls = 1'b1;
		end	else begin
			exe_ls = 1'b0;
		end
	end 
	always @ (*) begin
		if(rst == `RstEnable)begin
			exe_store = 1'b0;
		end else if(op == `EXE_SB || op == `EXE_SW )begin//先初始化		
			exe_store = 1'b1;
		end	else begin
			exe_store = 1'b0;
		end
	end 


endmodule