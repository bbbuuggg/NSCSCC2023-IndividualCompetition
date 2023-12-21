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
	input wire pre_load_baseram,
	input wire pre_load_extram,
	input wire                    branch_flag_i,//译码阶段信号
	input wire[`RegBus]           branch_target_address_i,//跳转目的地址
	
	output wire bingo,//对baseram 使用store后紧接着用load
	input wire [`InstAddrBus] if_pc,//pc取得指令地址
	input wire [`InstBus] if_inst,//所取指令
	output reg [2:0]cnt_o,
	output reg [2:0]scnt_o,
	output reg [2:0]cnt_ext_o,
	output reg [2:0]scnt_ext_o,
	output reg[`InstAddrBus] id_pc,
	output reg[`InstBus] id_inst
	
);
	reg [`InstBus] id_inst_delay;//pc好像不用？
	reg [`InstAddrBus] id_pc_delay;
	reg delaysignal;
	reg delaysignal_bubble;
	reg delaysignal_use;
	reg sdelaysignal;
	reg sdelaysignal_bubble;
	reg sdelaysignal_use;

	reg cnt_r;
	reg cnt_ext_r;


	reg scnt_r;
	reg scnt_ext_r;
	reg signal; //在连续暂停两个周期后需要控制id_inst信号持续多一拍
	reg exe_store;
	reg store_baseram_delay;
	reg pre_is_store;
	reg pre_is_load;

	reg bingo_delay;
	reg bingo_delay2;
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			id_pc <= `ZeroWord; //复位pc地址置零
			id_inst <= `ZeroWord;//取空指
		// end else if(flush == 1'b1)begin
			// id_pc <= `ZeroWord;
			// id_inst <= `ZeroWord;
		// end else if(stall[1] == `Stop && stall[2] == `NoStop) begin//取指停译码不停，表示取指阶段暂停
			// id_pc <= `ZeroWord;
			// id_inst <= `ZeroWord;	
		// end else if(stall[1] == `NoStop) begin//取指不停
		end else if(scnt_o != 3'd0 || scnt_ext_o != 3'd0 || store_baseram || store_extram)begin
			if(stall)begin 
				id_pc <= id_pc;
				id_inst <= id_inst;
			end else if(store_baseram || store_extram ||sdelaysignal ||sdelaysignal_bubble)begin
				id_pc <= id_pc;
				id_inst <= 32'h34000000;
			end else if(sdelaysignal_use || scnt_ext_o == 3'd1 ) begin
				id_pc <= id_pc_delay;
				id_inst <= id_inst_delay;
			end else begin
				id_pc <= if_pc;
				id_inst <= if_inst;
			end
		end else if(cnt_o != 3'd0 || cnt_ext_o != 3'd0 || pre_load_baseram || pre_load_extram||bingo_delay)begin
			// if((signal && stall)||baseram_finish)begin//idinst
				// id_pc <= id_pc;
				// id_inst <= id_inst;
			// if(signal && stall ||baseram_finish)begin//idinst
				// id_pc <= id_pc;
				// id_inst <= 32'h34000000;
			// end else if(delaysignal_bubble ) begin
				// id_pc <= id_pc_delay;
				// id_inst <= id_inst_delay;
			// end else if(delaysignal_use)begin
				// id_pc <= id_pc_delay;
				// id_inst <= 32'h34000000;
			if(stall || bingo_delay2)begin
				id_pc <= id_pc;
				id_inst <= id_inst;
			end else if((cnt_o == 3'd3 && !bingo) || bingo_delay || cnt_ext_o == 3'd1)begin //&& !(exe_store && delaysignal_use))||bingo
				id_pc <= id_pc_delay;
				id_inst <= id_inst_delay;
			end	else if(pre_load_baseram || pre_load_extram || delaysignal ||delaysignal_bubble || delaysignal_use ||bingo)begin//||bingo
				id_pc <= id_pc;
				id_inst <= 32'h34000000;
			end else begin
				id_pc <= if_pc;
				id_inst <= if_inst;
			end
		// end else if(branch_flag_i == `Branch && !load_baseram) begin
			// id_pc <= branch_target_address_i - 4'h4;
			// id_inst <= if_inst;
		end else if(stall == `NoStop )begin//|| exe_store
			id_pc <= if_pc;
			id_inst <= if_inst;
		// end else if(stall == `NoStop)begin
			// id_pc <= if_pc;
			// id_inst <= if_inst;
		end else begin
			id_pc <= id_pc;
			id_inst <= id_inst;
		end
	end
	
	always @ (posedge clk)begin
		if(rst == `RstEnable)begin
			id_inst_delay <= `ZeroWord;
			id_pc_delay <= `ZeroWord;
		end else if((pre_load_baseram && !stall) || (pre_load_extram && !stall) || (store_baseram && !stall) || (store_extram && !stall))begin
			id_inst_delay <= if_inst;
			// id_pc_delay <= id_pc +4'h4;
			id_pc_delay <= if_pc;
		end else if((cnt_o == 3'd3 && !bingo) || bingo_delay || scnt_o == 3'd3)begin
			id_inst_delay <= `ZeroWord;
			id_pc_delay <= `ZeroWord;
		end else begin
			id_inst_delay <= id_inst_delay;
			id_pc_delay <= id_pc_delay;
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
		// end else if(exe_store && delaysignal_use)begin//) || store_baseram
			// bingo <= 1'b1;
		// end else begin
			// bingo <= 1'b0;
		// end
	// end
	assign bingo = exe_store && delaysignal_use;
	always @ (posedge clk)begin
		delaysignal_bubble <= delaysignal;
		delaysignal_use <= delaysignal_bubble;
		sdelaysignal_bubble <= sdelaysignal;
		store_baseram_delay <= store_baseram;
		sdelaysignal_use <= sdelaysignal_bubble;
		pre_is_store <= sdelaysignal_use;
		pre_is_load <= delaysignal_use;
		signal <= stall;
		bingo_delay <= bingo;
		bingo_delay2 <= bingo_delay;
	end
	
	always @(posedge clk) begin
		if(rst) begin     
			cnt_o <= 3'd0;  
			cnt_r <= 1'b0;
		end else if(cnt_o == 3'd3) begin      
			cnt_r <= 1'b0;     
			cnt_o  <=  3'd0;
		end else if(pre_load_baseram && !stall) begin    
			cnt_r <= 1'b1;
			cnt_o  <=  3'd1;
		end  else if(cnt_r != 0) begin    
			cnt_o <= cnt_o + 1'b1;
		end
	end
	always @(posedge clk) begin
		if(rst) begin     
			cnt_ext_o <= 3'd0;  
			cnt_ext_r <= 1'b0;
		end else if(cnt_ext_o == 3'd1) begin      
			cnt_ext_r <= 1'b0;     
			cnt_ext_o  <=  3'd0;
		end else if(pre_load_extram && !stall) begin    
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
		end else if(scnt_o == 3'd3) begin      
			scnt_r <= 1'b0;     
			scnt_o  <=  3'd0;
		end else if(store_baseram && !stall) begin    
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
	
	wire[5:0] op = id_inst_delay[31:26];//指令码
	// wire[4:0] shamt = id_inst_delay[10:6];//位移量
	// wire[5:0] func = id_inst_delay[5:0];//功能码
	
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