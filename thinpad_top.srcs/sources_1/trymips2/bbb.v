`include "defines.v"

module bbb(

	input wire rst,
	input wire clk,
	input    wire        pre_inst_is_load,	
	//EX的前递
	input wire ex_wreg_i,
	input wire[`RegBus] ex_wdata_i,
	input wire[`RegAddrBus] ex_wd_i,
	

	//mem的前递
	input wire mem_wreg_i,
	input wire[`RegBus] mem_wdata_i,
	input wire[`RegAddrBus] mem_wd_i,
	
	//输出到寄存器
	input wire reg1_read_o,
	input wire reg2_read_o,
	input wire[`RegAddrBus] reg1_addr_o,
	input wire[`RegAddrBus] reg2_addr_o,
	
	//输入ex模块的信号
	input wire[`AluOpBus] aluop_i,
	input wire[`AluSelBus] alusel_i,
	input wire[`RegBus]bbb_reg1,
	input wire[`RegBus]bbb_reg2,
	input wire[`RegBus] reg1_data_i,
	input wire[`RegBus] reg2_data_i,
	input wire bbb_reg1_file,
	input wire bbb_reg2_file,
	
	input wire[`RegAddrBus] wd_i,
	input wire wreg_i,
	input wire[`RegBus]           inst_i,
	input   wire[31:0]  bbb_pc,
	input wire[`RegBus]           link_address_i,
	input wire                    is_in_delayslot_i,	
	input wire[`RegBus] imm,
	input wire[`RegBus] pc_plus_8,//保存第二条地址
	input wire[`RegBus] pc_plus_4,//保存下一条地址
	input wire[`RegBus] imm_sll2_signedext, //offset左移两位再扩展
	
	output reg   next_inst_in_delayslot_o,
	output wire  stallreq,//id发出的暂停请求	
	
	output reg        store_baseram,
	output reg        store_extram,
	output reg        pre_load_baseram,
	output reg        pre_load_extram,
	output reg        store_bfd,
	output reg        pre_load_bfd,
	
	
	input wire id_pre_branch,
	output wire                    branch_flag_o,
	output reg[`RegBus]           branch_target_address_o,   
	
	output wire  bbb_inst_is_load,
	output reg[`AluOpBus] aluop_o,
	output reg[`AluSelBus] alusel_o,
	(*mark_debug = "true"*)output reg[`RegBus] reg1_o,
	(*mark_debug = "true"*)output reg[`RegBus] reg2_o,
	output reg[`RegAddrBus] wd_o,
	output reg wreg_o,
	output wire[`RegBus]           inst_o,
	output reg[31:0]  ex_pc,
	output reg[`RegBus]           link_address_o,
	output reg                    is_in_delayslot_o
	
	
	
);
	reg[`RegBus]branch_target_address_delay;  
    reg[`RegBus]branch_target_address;
	reg branch_flag;
	// reg stallreq_for_reg1_loadrelate;
	// reg stallreq_for_reg2_loadrelate;
	reg reg1_read_o_delay;
	reg reg2_read_o_delay;
	// assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;//stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate
	assign branch_flag_o = branch_flag ;//&& id_pre_branch
	
	
	assign bbb_inst_is_load = (aluop_i == `EXE_LB_OP) | (aluop_i == `EXE_LW_OP);
	always @ (posedge clk) begin
		branch_target_address_delay <= branch_target_address;
		reg1_read_o_delay <= reg1_read_o;
		reg2_read_o_delay <= reg2_read_o;
	end
	always @ (*)begin
		if(rst) begin
			branch_target_address_o = `ZeroWord;
		// end else if(branch_flag && id_pre_branch)begin
			// branch_target_address_o = branch_target_address_delay;
		end else begin
			branch_target_address_o = branch_target_address;
		end
	end
	always @(*)begin
		if(rst == `RstEnable)begin
			aluop_o = 8'd0;
			alusel_o = 3'd0;
			wd_o = 5'd0;
			reg1_o = `ZeroWord;
			reg2_o = `ZeroWord;
			wreg_o = 1'b0;
			ex_pc = `ZeroWord;
			is_in_delayslot_o =	1'b0;
		end else begin
			aluop_o = aluop_i;
			alusel_o = aluop_i;
			wd_o = wd_i;
			wreg_o = wreg_i;
			ex_pc = bbb_pc;
			is_in_delayslot_o =	is_in_delayslot_i;
			if(bbb_reg1_file)begin
				reg1_o = reg1_data_i;
			end else begin
				reg1_o = bbb_reg1;
			end
			if(bbb_reg2_file)begin
				reg2_o = reg2_data_i;
			end else begin
				reg2_o = bbb_reg2;
			end
		end
	end
	
	// always @ (*) begin
		// if(rst == `RstEnable) begin//load暂停
			// reg1_o = `ZeroWord;
		// end else  begin//&& stall == `NoStop
			// case (bbb_reg1)
		    	// `ZeroReg:begin
					// reg1_o = `ZeroWord;
				// end
				// `ex_reg:begin
					// reg1_o = ex_wdata_i;
				// end
				// `mem_reg:begin
					// reg1_o = mem_wdata_i;
				// end
				// `regfile:begin
					// reg1_o = reg1_data_i;
				// end
				// `imm:begin
					// reg1_o = imm;
				// end
				// default:	begin
					// reg1_o = `ZeroWord;
				// end
			// endcase
		// end
	// end
	// always @ (*) begin
		// if(rst == `RstEnable) begin//load暂停
			// reg2_o = `ZeroWord;
		// end else  begin//&& stall == `NoStop
			// case (bbb_reg2)
		    	// `ZeroReg:begin
					// reg2_o = `ZeroWord;
				// end
				// `ex_reg:begin
					// reg2_o = ex_wdata_i;
				// end
				// `mem_reg:begin
					// reg2_o = mem_wdata_i;
				// end
				// `regfile:begin
					// reg2_o = reg2_data_i;
				// end
				// `imm:begin
					// reg2_o = imm;
				// end
				// default:	begin
					// reg2_o = `ZeroWord;
				// end
			// endcase
		// end
	// end
		
	wire[5:0] op = inst_i[31:26];//指令码
	wire[4:0] shamt = inst_i[10:6];//位移量
	wire[5:0] func = inst_i[5:0];//功能码
	wire[4:0] rt = inst_i[20:16];//第二个操作数地址

	wire [31:0]store_addr;

	assign inst_o = inst_i;
	assign store_addr = reg1_o + {{16{inst_i[15]}},inst_i[15:0]};
	
	always @ (*) begin
			if(rst == `RstEnable)begin
				link_address_o = `ZeroWord;
				branch_target_address = `ZeroWord;
				branch_flag = `NotBranch;
				next_inst_in_delayslot_o = `NotInDelaySlot;
				store_baseram = 1'b0;store_extram = 1'b0;
				pre_load_baseram = 1'b0;pre_load_extram = 1'b0;
				store_bfd = 1'b0;
				pre_load_bfd = 1'b0;
			end else if(inst_i == `ZeroWord)begin
				link_address_o = `ZeroWord;
				branch_target_address = `ZeroWord;
				branch_flag = `NotBranch;
				next_inst_in_delayslot_o = `NotInDelaySlot;
				store_baseram = 1'b0;store_extram = 1'b0;
				pre_load_baseram = 1'b0;pre_load_extram = 1'b0;
				store_bfd = 1'b0;
				pre_load_bfd = 1'b0;
			end else begin//先初始化
				link_address_o = `ZeroWord;
				branch_target_address = `ZeroWord;
				branch_flag = `NotBranch;	
				next_inst_in_delayslot_o = `NotInDelaySlot; 		
				case (op)
				`EXE_SPECIAL_INST:		begin
					case (shamt)
						5'b00000:			begin
							case (func)		
								`EXE_JR: begin//
								link_address_o = `ZeroWord;//返回地址
								branch_target_address = reg1_o;//设置目标底点
								branch_flag = `Branch;//是branch
								next_inst_in_delayslot_o = `InDelaySlot;//在延迟槽中
								pre_load_baseram = 1'b0;pre_load_extram = 1'b0;
								store_baseram = 1'b0;store_extram = 1'b0;
								store_bfd = 1'b0;
								pre_load_bfd = 1'b0;
								end
								`EXE_JALR: begin//
								link_address_o = pc_plus_8;		
								branch_target_address = reg1_o;//读取跳转的值
								branch_flag = `Branch;	
								next_inst_in_delayslot_o = `InDelaySlot;
								store_baseram = 1'b0;store_extram = 1'b0;	
								pre_load_baseram = 1'b0;pre_load_extram = 1'b0;	
								store_bfd = 1'b0;
								pre_load_bfd = 1'b0;
								end								
								default:	begin
									end
							  endcase
							end																		  	
						default:  begin
						end
					endcase		
				end
				`EXE_J:			begin//
					link_address_o = `ZeroWord;
					branch_target_address = {pc_plus_4[31:28], inst_i[25:0], 2'b00};//？
					branch_flag = `Branch;				
					next_inst_in_delayslot_o = `InDelaySlot;		  	
					store_baseram = 1'b0;store_extram = 1'b0;
					pre_load_baseram = 1'b0;pre_load_extram = 1'b0;
					store_bfd = 1'b0;
					pre_load_bfd = 1'b0;
					end
				`EXE_JAL:			begin//
					link_address_o = pc_plus_8 ;
					branch_target_address = {pc_plus_4[31:28], inst_i[25:0], 2'b00};
					branch_flag = `Branch;				
					next_inst_in_delayslot_o = `InDelaySlot;		  	
					store_baseram = 1'b0;store_extram = 1'b0;
					pre_load_baseram = 1'b0;pre_load_extram = 1'b0;
					store_bfd = 1'b0;
					pre_load_bfd = 1'b0;pre_load_bfd = 1'b0;
					store_bfd = 1'b0;
					pre_load_bfd = 1'b0;
					end
				`EXE_BEQ:			begin//	
					link_address_o = `ZeroWord;
					store_baseram = 1'b0;store_extram = 1'b0;
					pre_load_baseram = 1'b0;pre_load_extram = 1'b0;
					store_bfd = 1'b0;
					pre_load_bfd = 1'b0;
					if(reg1_o == reg2_o) begin//相等
						branch_target_address = pc_plus_4 + imm_sll2_signedext;//pc+4 +offset
						branch_flag = `Branch;
						next_inst_in_delayslot_o = `InDelaySlot;		  	
					end
					end
				`EXE_BGTZ:			begin//
					link_address_o = `ZeroWord;
					store_baseram = 1'b0;store_extram = 1'b0;
					pre_load_baseram = 1'b0;pre_load_extram = 1'b0;
					store_bfd = 1'b0;
					pre_load_bfd = 1'b0;
					if((reg1_o[31] == 1'b0) && (reg1_o != `ZeroWord)) begin
						branch_target_address = pc_plus_4 + imm_sll2_signedext;
						branch_flag = `Branch;
						next_inst_in_delayslot_o = `InDelaySlot;		  	
					end
					end
				`EXE_BLEZ:			begin//
					link_address_o = `ZeroWord;	
					store_baseram = 1'b0;store_extram = 1'b0;
					pre_load_baseram = 1'b0;pre_load_extram = 1'b0;
					store_bfd = 1'b0;
					pre_load_bfd = 1'b0;
					if((reg1_o[31] == 1'b1) || (reg1_o == `ZeroWord)) begin
						branch_target_address = pc_plus_4 + imm_sll2_signedext;
						branch_flag = `Branch;
						next_inst_in_delayslot_o = `InDelaySlot;		  	
					end
					end
				`EXE_BNE:			begin//
					link_address_o = `ZeroWord;	
					store_baseram = 1'b0;store_extram = 1'b0;
					pre_load_baseram = 1'b0;pre_load_extram = 1'b0;
					store_bfd = 1'b0;
					pre_load_bfd = 1'b0;
					if(reg1_o != reg2_o) begin
						branch_target_address = pc_plus_4 + imm_sll2_signedext;
						branch_flag = `Branch;
						next_inst_in_delayslot_o = `InDelaySlot;		  	
					end
					end
				`EXE_LB:			begin//
					link_address_o = `ZeroWord;
					branch_target_address = `ZeroWord;
					branch_flag = `NotBranch;
					store_baseram = 1'b0;store_extram = 1'b0;
					store_bfd = 1'b0;
					pre_load_bfd = store_addr == 32'hbfd003f8 || store_addr == 32'hbfd003fc;
					pre_load_baseram = (store_addr >= 32'h80000000) && (store_addr < 32'h80400000);
					pre_load_extram = (store_addr >= 32'h80400000) && (store_addr < 32'h80800000);
						
				end
				`EXE_LW:			begin
					link_address_o = `ZeroWord;
					branch_target_address = `ZeroWord;
					branch_flag = `NotBranch;
					store_baseram = 1'b0;store_extram = 1'b0;
					store_bfd = 1'b0;
					pre_load_bfd = store_addr == 32'hbfd003f8 || store_addr == 32'hbfd003fc;
					pre_load_baseram = (store_addr >= 32'h80000000) && (store_addr < 32'h80400000);
					pre_load_extram = (store_addr >= 32'h80400000) && (store_addr < 32'h80800000);	
				end
				`EXE_SB:			begin//
					link_address_o = `ZeroWord;
					branch_target_address = `ZeroWord;
					branch_flag = `NotBranch;
					pre_load_baseram = 1'b0;pre_load_extram = 1'b0;	
					store_bfd = store_addr == 32'hbfd003f8 || store_addr == 32'hbfd003fc;
					pre_load_bfd = 1'b0;					
					store_baseram = (store_addr >= 32'h80000000) && (store_addr < 32'h80400000);
					store_extram = (store_addr >= 32'h80400000) && (store_addr < 32'h80800000);
				end
				`EXE_SW:			begin
					link_address_o = `ZeroWord;
					branch_target_address = `ZeroWord;
					branch_flag = `NotBranch;
					pre_load_baseram = 1'b0;pre_load_extram = 1'b0;
					store_bfd = store_addr == 32'hbfd003f8 || store_addr == 32'hbfd003fc;
					pre_load_bfd = 1'b0;	
					store_baseram = (store_addr >= 32'h80000000) && (store_addr < 32'h80400000);
					store_extram = (store_addr >= 32'h80400000) && (store_addr < 32'h80800000);
				end
				`EXE_REGIMM_INST:		begin
						case (rt)
							`EXE_BGEZ:	begin//	
								link_address_o = `ZeroWord;
								store_baseram = 1'b0;store_extram = 1'b0;
								pre_load_baseram = 1'b0;pre_load_extram = 1'b0;
								store_bfd = 1'b0;
								pre_load_bfd = 1'b0;
								if(reg1_o[31] == 1'b0) begin
									branch_target_address = pc_plus_4 + imm_sll2_signedext;
									branch_flag = `Branch;
									next_inst_in_delayslot_o = `InDelaySlot;		  	
								end
							end
							`EXE_BGEZAL:		begin//
								link_address_o = pc_plus_8; 
								store_baseram = 1'b0;store_extram = 1'b0;
								pre_load_baseram = 1'b0;pre_load_extram = 1'b0;
								store_bfd = 1'b0;
								pre_load_bfd = 1'b0;
								if(reg1_o[31] == 1'b0) begin
									branch_target_address = pc_plus_4 + imm_sll2_signedext;
									branch_flag = `Branch;
									next_inst_in_delayslot_o = `InDelaySlot;
								end
							end
							`EXE_BLTZ:		begin//
								link_address_o = `ZeroWord;
								store_baseram = 1'b0;store_extram = 1'b0;
								pre_load_baseram = 1'b0;pre_load_extram = 1'b0;
								store_bfd = 1'b0;
								pre_load_bfd = 1'b0;
								if(reg1_o[31] == 1'b1) begin
									branch_target_address = pc_plus_4 + imm_sll2_signedext;
									branch_flag = `Branch;
									next_inst_in_delayslot_o = `InDelaySlot;		  	
								end
							end
							`EXE_BLTZAL:		begin//
								link_address_o = pc_plus_8;	
								store_baseram = 1'b0;store_extram = 1'b0;
								pre_load_baseram = 1'b0;pre_load_extram = 1'b0;
								store_bfd = 1'b0;
								pre_load_bfd = 1'b0;
								if(reg1_o[31] == 1'b1) begin
									branch_target_address = pc_plus_4 + imm_sll2_signedext;
									branch_flag = `Branch;
									next_inst_in_delayslot_o = `InDelaySlot;
								end
							end
							default:	begin
								link_address_o = `ZeroWord;
								branch_target_address = `ZeroWord;
								branch_flag = `NotBranch;
								next_inst_in_delayslot_o = `NotInDelaySlot;
								store_baseram = 1'b0;store_extram = 1'b0;
								pre_load_baseram = 1'b0;pre_load_extram = 1'b0;
								store_bfd = 1'b0;
								pre_load_bfd = 1'b0;
							end
						endcase
					end
					default:	begin
						link_address_o = `ZeroWord;
						branch_target_address = `ZeroWord;
						branch_flag = `NotBranch;
						next_inst_in_delayslot_o = `NotInDelaySlot;
						store_baseram = 1'b0;store_extram = 1'b0;
						pre_load_baseram = 1'b0;pre_load_extram = 1'b0;
						store_bfd = 1'b0;
						pre_load_bfd = 1'b0;
					end
				endcase
		end  
	end         

	
endmodule

	
	
	