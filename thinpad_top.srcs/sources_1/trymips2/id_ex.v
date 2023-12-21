`include "defines.v"

module id_ex(
	
	input wire clk,
	input wire rst,
	
	// input wire[5:0]							 stall,
	// input wire                   flush,
	input  wire stall,
	//id 传输的信息
	input wire[`AluOpBus] id_aluop,
	input wire[`AluSelBus] id_alusel,
	input wire[`RegBus] id_reg1,
	input wire[`RegBus] id_reg2,
	input wire id_reg1_read_o,
	input wire id_reg2_read_o,
	input wire id_reg1_file,
	input wire id_reg2_file,
	
	input wire[`RegAddrBus] id_reg1_addr_o,
	input wire[`RegAddrBus] id_reg2_addr_o,
	
	input wire[`RegAddrBus] id_wd,
	input wire  id_wreg,
	input wire[`RegBus]           id_link_address,
	input wire                    id_is_in_delayslot,
	input wire                    next_inst_in_delayslot_i,		
	input wire[`RegBus]           id_inst,	
	input    wire[31:0]  id_pc,
	// input wire[`RegBus]           id_current_inst_address,
	// input wire[31:0]              id_excepttype,
	input wire[`RegBus] id_imm,
	
	input wire[`RegBus] pc_plus_8,//保存第二条地址
	input wire[`RegBus] pc_plus_4,//保存下一条地址
	input wire[`RegBus] imm_sll2_signedext, //offset左移两位再扩展
	
	input wire mem_op_check,
	input wire will_be_baseram,
	
	input wire load_baseram,
	input wire store_baseram,
	input wire store_extram,
	input wire pre_load_baseram,
	input wire pre_load_extram,
	input wire                    branch_flag_i,//译码阶段信号
	input wire[`RegBus]           branch_target_address_i,//跳转目的地址
	
	input wire related,
	input wire  bingo,
	// output wire bingo,//对baseram 使用store后紧接着用load
	// output reg [2:0]cnt_o,
	// output reg [2:0]scnt_o,
	// output reg [2:0]cnt_ext_o,
	// output reg [2:0]scnt_ext_o,
	// //传输到EX的信息
	// output reg[`AluOpBus] ex_aluop,
	// output reg[`AluSelBus] ex_alusel,
	// output reg[`RegBus] ex_reg1,
	// output reg[`RegBus] ex_reg2,
	// output reg[`RegAddrBus] ex_wd,
	// output reg  ex_wreg,
	// output reg[`RegBus]           ex_link_address,
	// output   reg [31:0]  ex_pc,
	// output reg                    ex_is_in_delayslot,
	// output reg                    is_in_delayslot_o,
	// output reg[`RegBus]           ex_inst
	
	//传输到bbb的信息
	output reg bbb_reg1_read_o,
	output reg bbb_reg2_read_o,
	output reg[`RegAddrBus] bbb_reg1_addr_o,
	output reg[`RegAddrBus] bbb_reg2_addr_o,
	output reg[`AluOpBus] bbb_aluop,
	output reg[`AluSelBus] bbb_alusel,
	output reg[`RegBus] bbb_reg1,
	output reg[`RegBus] bbb_reg2,
	output reg bbb_reg1_file,
	output reg bbb_reg2_file,
	output reg[`RegAddrBus] bbb_wd,
	output reg  bbb_wreg,
	output reg[`RegBus]           bbb_link_address,
	output reg [31:0]  bbb_pc,
	output reg [`RegBus] bbb_imm,
	output reg [`RegBus] bbb_pc_plus_8,//保存第二条地址
	output reg [`RegBus] bbb_pc_plus_4,//保存下一条地址
	output reg [`RegBus] bbb_imm_sll2_signedext, //offset左移两位再扩展
	output reg                    bbb_is_in_delayslot,
	output reg                    is_in_delayslot_o,
	output reg[`RegBus]           bbb_inst
	// output reg[31:0]              ex_excepttype,
	// output reg[`RegBus]          ex_current_inst_address
	
);

	always @(posedge clk)begin
		if (rst == `RstEnable)begin
			bbb_aluop <= `EXE_NOP_OP;
			bbb_alusel <= `EXE_RES_NOP;
			bbb_reg1 <= `ZeroReg;
			bbb_reg2 <= `ZeroReg;
			bbb_wd <= `NOPRegAddr;
			bbb_wreg <= `WriteDisable;
			bbb_link_address <= `ZeroWord;
			bbb_is_in_delayslot <= `NotInDelaySlot;
			is_in_delayslot_o <= `NotInDelaySlot;	
			bbb_inst <= `ZeroWord;	
			bbb_pc <= `ZeroWord;
			bbb_imm <= `ZeroWord;
			bbb_reg1_read_o <= `ZeroWord;
			bbb_reg2_read_o <= `ZeroWord;
			bbb_reg1_addr_o <= `ZeroWord;
			bbb_reg2_addr_o <= `ZeroWord;
			bbb_reg1_file <= 1'b0;
			bbb_reg2_file <= 1'b0;
			bbb_pc_plus_8 <= `ZeroWord;//保存第二条地址
			bbb_pc_plus_4 <= `ZeroWord;//保存下一条地址
			bbb_imm_sll2_signedext <= `ZeroWord;//offset左移两位再扩展
			//ex_excepttype <= `ZeroWord;
			// ex_current_inst_address <= `ZeroWord;
		// end else if(flush == 1'b1 ) begin
			// ex_aluop <= `EXE_NOP_OP;
			// ex_alusel <= `EXE_RES_NOP;
			// ex_reg1 <= `ZeroWord;
			// ex_reg2 <= `ZeroWord;
			// ex_wd <= `NOPRegAddr;
			// ex_wreg <= `WriteDisable;
			// // ex_excepttype <= `ZeroWord;
			// ex_link_address <= `ZeroWord;
			// ex_inst <= `ZeroWord;
			// ex_is_in_delayslot <= `NotInDelaySlot;
			// // ex_current_inst_address <= `ZeroWord;	
			// // is_in_delayslot_o <= `NotInDelaySlot;
		end else if(stall) begin//寄存器写读相关 || bingo
			bbb_aluop <= `EXE_NOP_OP;
			bbb_alusel <= `EXE_RES_NOP;
			// bbb_reg1 <= `ZeroWord;
			// bbb_reg2 <= `ZeroWord;
			bbb_wd <= `NOPRegAddr;
			bbb_wreg <= `WriteDisable;
			bbb_link_address <= `ZeroWord;
			bbb_is_in_delayslot <= `NotInDelaySlot;
			is_in_delayslot_o <= `NotInDelaySlot;	
			bbb_inst <= 32'h34000000;	
			bbb_pc <= `ZeroWord;
			bbb_imm <= `ZeroWord;
			bbb_reg1_read_o <= `ZeroWord;
			bbb_reg2_read_o <= `ZeroWord;
			bbb_reg1_addr_o <= `ZeroWord;
			bbb_reg2_addr_o <= `ZeroWord;
			bbb_reg1_file <= 1'b0;
			bbb_reg2_file <= 1'b0;
			bbb_pc_plus_8 <= `ZeroWord;//保存第二条地址
			bbb_pc_plus_4 <= `ZeroWord;//保存下一条地址
			bbb_imm_sll2_signedext <= `ZeroWord;//offset左移两位再扩展
			// ex_excepttype <= `ZeroWord;
			// ex_current_inst_address <= `ZeroWord;				
		end else begin		//stall[2] == `NoStop
			bbb_aluop <= id_aluop;
			bbb_alusel <= id_alusel;
			bbb_reg1 <= id_reg1;
			bbb_reg2 <= id_reg2;
			bbb_wd <= id_wd;
			bbb_wreg <= id_wreg;	
			bbb_link_address <= id_link_address;
			bbb_is_in_delayslot <= id_is_in_delayslot;
			is_in_delayslot_o <= next_inst_in_delayslot_i;
			bbb_inst <= id_inst;	
			bbb_pc <= id_pc;
			bbb_imm <= id_imm;
			bbb_reg1_read_o <= id_reg1_read_o;
			bbb_reg2_read_o <= id_reg2_read_o;
			bbb_reg1_addr_o <= id_reg1_addr_o;
			bbb_reg2_addr_o <= id_reg2_addr_o;
			bbb_reg1_file <= id_reg1_file;
			bbb_reg2_file <= id_reg2_file;
			bbb_pc_plus_8 <= pc_plus_8;//保存第二条地址
			bbb_pc_plus_4 <= pc_plus_4;//保存下一条地址
			bbb_imm_sll2_signedext <= imm_sll2_signedext;//offset左移两位再扩展
			// ex_excepttype <= id_excepttype;
			// ex_current_inst_address <= id_current_inst_address;			
		end
	end
	// reg [`InstBus] bbb_inst_delay;//pc好像不用？
	// reg [`InstAddrBus] bbb_pc_delay;
	// reg delaysignal;
	// reg delaysignal_bubble;
	// reg delaysignal_use;
	// reg sdelaysignal;
	// reg sdelaysignal_bubble;
	// reg sdelaysignal_use;

	// reg cnt_r;
	// reg cnt_ext_r;


	// reg scnt_r;
	// reg scnt_ext_r;
	// reg signal; //在连续暂停两个周期后需要控制bbb_inst信号持续多一拍
	// reg exe_store;
	// reg store_baseram_delay;
	// reg pre_is_store;
	// reg pre_is_load;

	// reg bingo_delay;
	// reg bingo_delay2;
	// always @ (posedge clk) begin
		// if (rst == `RstEnable) begin
			// bbb_pc <= `ZeroWord; //复位pc地址置零
			// bbb_inst <= `ZeroWord;//取空指
		// end else if(scnt_o != 3'd0 || scnt_ext_o != 3'd0 || store_baseram || store_extram)begin
			// if(stall)begin 
				// bbb_pc <= bbb_pc;
				// bbb_inst <= bbb_inst;
			// end else if(store_baseram || store_extram ||sdelaysignal ||sdelaysignal_bubble)begin
				// bbb_pc <= bbb_pc;
				// bbb_inst <= 32'h34000000;
			// end else if(sdelaysignal_use || scnt_ext_o == 3'd1 ) begin
				// bbb_pc <= bbb_pc_delay;
				// bbb_inst <= bbb_inst_delay;
			// end else begin
				// bbb_pc <= id_pc;
				// bbb_inst <= id_inst;
			// end
		// end else if(cnt_o != 3'd0 || cnt_ext_o != 3'd0 || pre_load_baseram || pre_load_extram||bingo_delay)begin
			// // if((signal && stall)||baseram_finish)begin//idinst
				// // bbb_pc <= bbb_pc;
				// // bbb_inst <= bbb_inst;
			// // if(signal && stall ||baseram_finish)begin//idinst
				// // bbb_pc <= bbb_pc;
				// // bbb_inst <= 32'h34000000;
			// // end else if(delaysignal_bubble ) begin
				// // bbb_pc <= bbb_pc_delay;
				// // bbb_inst <= bbb_inst_delay;
			// // end else if(delaysignal_use)begin
				// // bbb_pc <= bbb_pc_delay;
				// // bbb_inst <= 32'h34000000;
			// if(stall || bingo_delay2)begin
				// bbb_pc <= bbb_pc;
				// bbb_inst <= bbb_inst;
			// end else if((cnt_o == 3'd3 && !bingo) || bingo_delay || cnt_ext_o == 3'd1)begin //&& !(exe_store && delaysignal_use))||bingo
				// bbb_pc <= bbb_pc_delay;
				// bbb_inst <= bbb_inst_delay;
			// end	else if(pre_load_baseram || pre_load_extram || delaysignal ||delaysignal_bubble || delaysignal_use ||bingo)begin//||bingo
				// bbb_pc <= bbb_pc;
				// bbb_inst <= 32'h34000000;
			// end else begin
				// bbb_pc <= id_pc;
				// bbb_inst <= id_inst;
			// end
		// // end else if(branch_flag_i == `Branch && !load_baseram) begin
			// // bbb_pc <= branch_target_address_i - 4'h4;
			// // bbb_inst <= id_inst;
		// end else if(stall == `NoStop )begin//|| exe_store
			// bbb_pc <= id_pc;
			// bbb_inst <= id_inst;
		// // end else if(stall == `NoStop)begin
			// // bbb_pc <= id_pc;
			// // bbb_inst <= id_inst;
		// end else begin
			// bbb_pc <= bbb_pc;
			// bbb_inst <= bbb_inst;
		// end
	// end
	
	// always @ (posedge clk)begin
		// if(rst == `RstEnable)begin
			// bbb_inst_delay <= `ZeroWord;
			// bbb_pc_delay <= `ZeroWord;
		// end else if((pre_load_baseram && !stall) || (pre_load_extram && !stall) || (store_baseram && !stall) || (store_extram && !stall))begin
			// bbb_inst_delay <= id_inst;
			// // bbb_pc_delay <= bbb_pc +4'h4;
			// bbb_pc_delay <= id_pc;
		// end else if((cnt_o == 3'd3 && !bingo) || bingo_delay || scnt_o == 3'd3)begin
			// bbb_inst_delay <= `ZeroWord;
			// bbb_pc_delay <= `ZeroWord;
		// end else begin
			// bbb_inst_delay <= bbb_inst_delay;
			// bbb_pc_delay <= bbb_pc_delay;
		// end
	// end
	// always @ (posedge clk)begin
		// if(rst == `RstEnable )begin
			// delaysignal <= 1'b0;
		// end else if(pre_load_baseram)begin//) || store_baseram
			// delaysignal <= 1'b1;
		// end else begin
			// delaysignal <= 1'b0;
		// end
	// end
	// always @ (posedge clk)begin
		// if(rst == `RstEnable )begin
			// sdelaysignal <= 1'b0;
		// end else if(store_baseram)begin//) || store_baseram
			// sdelaysignal <= 1'b1;
		// end else begin
			// sdelaysignal <= 1'b0;
		// end
	// end
	// // always @ (posedge clk)begin
		// // if(rst == `RstEnable )begin
			// // bingo <= 1'b0;
		// // end else if(exe_store && delaysignal_use)begin//) || store_baseram
			// // bingo <= 1'b1;
		// // end else begin
			// // bingo <= 1'b0;
		// // end
	// // end
	// assign bingo = exe_store && delaysignal_use;
	// always @ (posedge clk)begin
		// delaysignal_bubble <= delaysignal;
		// delaysignal_use <= delaysignal_bubble;
		// sdelaysignal_bubble <= sdelaysignal;
		// store_baseram_delay <= store_baseram;
		// sdelaysignal_use <= sdelaysignal_bubble;
		// pre_is_store <= sdelaysignal_use;
		// pre_is_load <= delaysignal_use;
		// signal <= stall;
		// bingo_delay <= bingo;
		// bingo_delay2 <= bingo_delay;
	// end
	
	// always @(posedge clk) begin
		// if(rst) begin     
			// cnt_o <= 3'd0;  
			// cnt_r <= 1'b0;
		// end else if(cnt_o == 3'd3) begin      
			// cnt_r <= 1'b0;     
			// cnt_o  <=  3'd0;
		// end else if(pre_load_baseram && !stall) begin    
			// cnt_r <= 1'b1;
			// cnt_o  <=  3'd1;
		// end  else if(cnt_r != 0) begin    
			// cnt_o <= cnt_o + 1'b1;
		// end
	// end
	// always @(posedge clk) begin
		// if(rst) begin     
			// cnt_ext_o <= 3'd0;  
			// cnt_ext_r <= 1'b0;
		// end else if(cnt_ext_o == 3'd1) begin      
			// cnt_ext_r <= 1'b0;     
			// cnt_ext_o  <=  3'd0;
		// end else if(pre_load_extram && !stall) begin    
			// cnt_ext_r <= 1'b1;
			// cnt_ext_o  <=  3'd1;
		// end  else if(cnt_ext_r != 0) begin    
			// cnt_ext_o <= cnt_ext_o + 1'b1;
		// end
	// end
	
	// always @(posedge clk) begin
		// if(rst) begin     
			// scnt_o <= 3'd0;  
			// scnt_r <= 1'b0;
		// end else if(scnt_o == 3'd3) begin      
			// scnt_r <= 1'b0;     
			// scnt_o  <=  3'd0;
		// end else if(store_baseram && !stall) begin    
			// scnt_r <= 1'b1;
			// scnt_o  <=  3'd1;
		// end  else if(scnt_r != 0) begin    
			// scnt_o <= scnt_o + 1'b1;
		// end
	// end
	
	// always @(posedge clk) begin
		// if(rst) begin     
			// scnt_ext_o <= 3'd0;  
			// scnt_ext_r <= 1'b0;
		// end else if(scnt_ext_o == 3'd1) begin      
			// scnt_ext_r  <= 1'b0;     
			// scnt_ext_o  <=  3'd0;
		// end else if(store_extram && !stall) begin    
			// scnt_ext_r  <= 1'b1;
			// scnt_ext_o  <=  3'd1;
		// end  else if(scnt_ext_r  != 0) begin    
			// scnt_ext_o <= scnt_ext_o + 1'b1;
		// end
	// end
endmodule