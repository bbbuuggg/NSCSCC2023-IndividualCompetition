`include "defines.v"

module mem(
	input wire clk,
	input wire rst,
	
	//from EX
	// input       wire[31:0]  mem_pc,
	input wire[`RegAddrBus] wd_i,
	input wire wreg_i,
	input wire[`RegBus] wdata_i,
	// input wire[`RegBus]           hi_i,
	// input wire[`RegBus]           lo_i,
	// input wire                    whilo_i,	
	
	// input wire[`AluOpBus]        aluop_i,
	// input wire[`RegBus]          mem_addr_i,
	// input wire[`RegBus]          reg2_i,
	input       wire[`AluOpBus]   mem_op,     
    input       wire[31:0]  mem_addr_i, 
    input       wire[31:0]  mem_data_i,
	
	input wire [31:0] mulans,
	//来自memory的信�?
	// input wire[`RegBus]          mem_data_i,
	
	// //LLbit_i是LLbit寄存器的�?
	// input wire                  LLbit_i,
	// //但不�?定是�?新�?�，回写阶段可能要写LLbit，所以还要进�?步判�?
	// input wire                  wb_LLbit_we_i,
	// input wire                  wb_LLbit_value_i,
	
	// //协处理器CP0的写信号
	// input wire                   cp0_reg_we_i,
	// input wire[4:0]              cp0_reg_write_addr_i,
	// input wire[`RegBus]          cp0_reg_data_i,
	
	// input wire[31:0]             excepttype_i,
	// input wire                   is_in_delayslot_i,
	// input wire[`RegBus]          current_inst_address_i,	
	
	// //CP0的各个寄存器的�?�，但不�?定是�?新的值，要防止回写阶段指令写CP0
	// input wire[`RegBus]          cp0_status_i,
	// input wire[`RegBus]          cp0_cause_i,
	// input wire[`RegBus]          cp0_epc_i,

	// //回写阶段的指令是否要写CP0，用来检测数据相�?
	// input wire                    wb_cp0_reg_we,
	// input wire[4:0]               wb_cp0_reg_write_addr,
	// input wire[`RegBus]           wb_cp0_reg_data,
	
	//send to WB
	output reg[`RegAddrBus] wd_o,
	output reg wreg_o,
	output reg[`RegBus] wdata_o,
	// output reg[`RegBus]          hi_o,
	// output reg[`RegBus]          lo_o,
	// output reg                   whilo_o,
	
	// output reg                   LLbit_we_o,
	// output reg                   LLbit_value_o,
	
	// output reg                   cp0_reg_we_o,
	// output reg[4:0]              cp0_reg_write_addr_o,
	// output reg[`RegBus]          cp0_reg_data_o,
	
	//送到memory的信�?
	output reg[`RegBus]          mem_addr_o,
	output reg					 mem_we_o,
	output reg[3:0]              mem_sel_o,
	output reg[`RegBus]          mem_data_o,
	output reg                   mem_ce_o,
	output reg   op_for_baseram,
	
	output reg is_base_ram,
	output reg is_ext_ram,
	
	// output reg[31:0]             excepttype_o,
	// output wire[`RegBus]          cp0_epc_o,
	// output wire                  is_in_delayslot_o,
	
	// output wire[`RegBus]         current_inst_address_o
	input       wire[31:0]  ram_data_i,

    output      wire        stallreq
);
	// reg LLbit;
	assign  stallreq    = (mem_addr_i >= 32'h80000000) 
							&& (mem_addr_i < 32'h80400000);
	// assign is_base_ram    = (mem_addr_i >= 32'h80000000) 
                    // && (mem_addr_i < 32'h80400000);
	// reg[`RegBus]          cp0_status;
	// reg[`RegBus]          cp0_cause;
	// reg[`RegBus]          cp0_epc;
	
	// wire[`RegBus] zero32;
	// reg  mem_we;
	// assign mem_we_o = mem_we; //& (~(|excepttype_o));//RAM读写信号
	// assign zero32 = `ZeroWord;
	
	// assign is_in_delayslot_o = is_in_delayslot_i;
	// assign current_inst_address_o = current_inst_address_i;
	// assign cp0_epc_o = cp0_epc;
	
  // //获取�?新的LLbit的�??
	// always @ (*) begin
		// if(rst == `RstEnable) begin
			// LLbit <= 1'b0;
		// end else begin
			// if(wb_LLbit_we_i == 1'b1) begin
				// LLbit <= wb_LLbit_value_i;//回写先写
			// end else begin
				// LLbit <= LLbit_i;
			// end
		// end
	// end
	reg is_base_ram_delay;
	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			is_base_ram_delay <= 1'b0;
		end else begin
			if(is_base_ram == 1'b1) begin
				is_base_ram_delay <= 1'b1;
			end else begin
				is_base_ram_delay <= 1'b0;
			end
		end
	end
	always @ (*) begin
		if(rst == `RstEnable) begin
			wd_o = `NOPRegAddr;
			wreg_o = `WriteDisable;
			wdata_o = `ZeroWord;
			// hi_o <= `ZeroWord;
			// lo_o <= `ZeroWord;
			// whilo_o <= `WriteDisable;
			mem_addr_o = `ZeroWord;
			mem_we_o = `WriteDisable_low;
			mem_sel_o = 4'b0000;
			mem_data_o = `ZeroWord;
			mem_ce_o = `ChipDisable;
			op_for_baseram = 1'b0;
			is_base_ram  = 1'b0;
			is_ext_ram = 1'b0;
			//LLbit_we_o <= 1'b0;
			//LLbit_value_o <= 1'b0;	
			//cp0_reg_we_o <= `WriteDisable;
			//cp0_reg_write_addr_o <= 5'b00000;
			//cp0_reg_data_o <= `ZeroWord;	
		end else begin
			wd_o = wd_i;
			wreg_o = wreg_i;
			// wdata_o <=wdata_i;
			// hi_o <= hi_i;
			// lo_o <= lo_i;
			// whilo_o <= whilo_i;
			// mem_we <= `WriteDisable_low;
			// mem_addr_o <= `ZeroWord;
			// mem_sel_o <= 4'b1111;
			// mem_ce_o <= `ChipDisable;
			//LLbit_we_o <= 1'b0;
			//LLbit_value_o <= 1'b0;
			//cp0_reg_we_o <= cp0_reg_we_i;
			//cp0_reg_write_addr_o <= cp0_reg_write_addr_i;
			//cp0_reg_data_o <= cp0_reg_data_i;
			case(mem_op)
					`EXE_LB_OP:  begin
						wdata_o = ram_data_i;
						mem_addr_o = mem_addr_i;
						mem_data_o = `ZeroWord;
						mem_we_o = `WriteDisable_low;
						mem_ce_o = `ChipEnable;
						op_for_baseram = 1'b1;
						is_base_ram  = (mem_addr_i >= 32'h80000000) && (mem_addr_i < 32'h80400000);
						is_ext_ram = (mem_addr_i >= 32'h80400000) && (mem_addr_i < 32'h80800000);
						case(mem_addr_i[1:0])
							2'b00: begin
								mem_sel_o = 4'b1110;
							end 
							2'b01: begin
								mem_sel_o = 4'b1101;
							end
							2'b10: begin
								mem_sel_o = 4'b1011;
							end
							2'b11: begin
								mem_sel_o = 4'b0111;
							end
							default : begin
								mem_sel_o = 4'b1111;
							end
						endcase
					end
					`EXE_LW_OP:  begin
						wdata_o = ram_data_i;
						mem_addr_o = mem_addr_i;
						mem_data_o = `ZeroWord;
						mem_we_o = `WriteDisable_low;
						mem_ce_o = `ChipEnable;
						mem_sel_o = 4'b0000;
						op_for_baseram = 1'b1;
						is_base_ram  = (mem_addr_i >= 32'h80000000) && (mem_addr_i < 32'h80400000);
						is_ext_ram = (mem_addr_i >= 32'h80400000) && (mem_addr_i < 32'h80800000);
					end
					`EXE_SB_OP:  begin
						wdata_o = `ZeroWord;
						mem_addr_o = mem_addr_i;
						mem_data_o = {4{mem_data_i[7:0]}};    //低字节存储到指定位置
						mem_we_o = `WriteEnable_low;
						mem_ce_o = `ChipEnable;
						op_for_baseram = 1'b1;
						is_base_ram  = (mem_addr_i >= 32'h80000000) && (mem_addr_i < 32'h80400000);
						is_ext_ram = (mem_addr_i >= 32'h80400000) && (mem_addr_i < 32'h80800000);
						case(mem_addr_i[1:0])
							2'b00: begin
								mem_sel_o = 4'b1110;
							end 
							2'b01: begin
								mem_sel_o = 4'b1101;
							end
							2'b10: begin
								mem_sel_o = 4'b1011;
							end
							2'b11: begin
								mem_sel_o = 4'b0111;
							end
							default : begin
								mem_sel_o = 4'b1111;
							end
						endcase
					end
					`EXE_SW_OP:  begin
						wdata_o = `ZeroWord;
						mem_addr_o = mem_addr_i;
						mem_data_o = mem_data_i;
						mem_we_o = `WriteEnable_low;
						mem_ce_o = `ChipEnable;
						mem_sel_o = 4'b0000;
						op_for_baseram = 1'b1;
						is_base_ram  = (mem_addr_i >= 32'h80000000) && (mem_addr_i < 32'h80400000);
						is_ext_ram = (mem_addr_i >= 32'h80400000) && (mem_addr_i < 32'h80800000);
					end
					`EXE_MUL_OP: begin
						wdata_o = mulans;
						mem_addr_o = `ZeroWord;
						mem_data_o = `ZeroWord;
						mem_we_o = `WriteDisable_low;
						mem_ce_o = `ChipDisable;
						mem_sel_o = 4'b1111;
						is_base_ram  = 1'b0;
						is_ext_ram = 1'b0;
					end
					default: begin
						wdata_o = wdata_i;
						mem_addr_o = `ZeroWord;
						mem_data_o = `ZeroWord;
						mem_we_o = `WriteDisable_low;
						mem_ce_o = `ChipDisable;
						mem_sel_o = 4'b1111;
						is_base_ram  = 1'b0;
						is_ext_ram = 1'b0;
					end
				endcase
			end
		end

endmodule 

			// case (aluop_i)
				// `EXE_LB_OP:		begin
					// mem_addr_o <= mem_addr_i;
					// mem_we <= `WriteDisable_low;
					// mem_ce_o <= `ChipEnable;
					// case (mem_addr_i[1:0])
						// 2'b00:	begin
							// wdata_o <= {{24{mem_data_i[31]}},mem_data_i[31:24]};
							// mem_sel_o <= 4'b1110;
						// end
						// 2'b01:	begin
							// wdata_o <= {{24{mem_data_i[23]}},mem_data_i[23:16]};
							// mem_sel_o <= 4'b1101;
						// end
						// 2'b10:	begin
							// wdata_o <= {{24{mem_data_i[15]}},mem_data_i[15:8]};
							// mem_sel_o <= 4'b1011;
						// end
						// 2'b11:	begin
							// wdata_o <= {{24{mem_data_i[7]}},mem_data_i[7:0]};
							// mem_sel_o <= 4'b0111;
						// end
						// default:	begin
							// wdata_o <= `ZeroWord;
						// end
					// endcase
				// end
				// `EXE_LBU_OP:		begin
					// mem_addr_o <= mem_addr_i;
					// mem_we <= `WriteDisable_low;
					// mem_ce_o <= `ChipEnable;
					// case (mem_addr_i[1:0])
						// 2'b00:	begin
							// wdata_o <= {{24{1'b0}},mem_data_i[31:24]};
							// mem_sel_o <= 4'b1000;
						// end
						// 2'b01:	begin
							// wdata_o <= {{24{1'b0}},mem_data_i[23:16]};
							// mem_sel_o <= 4'b0100;
						// end
						// 2'b10:	begin
							// wdata_o <= {{24{1'b0}},mem_data_i[15:8]};
							// mem_sel_o <= 4'b0010;
						// end
						// 2'b11:	begin
							// wdata_o <= {{24{1'b0}},mem_data_i[7:0]};
							// mem_sel_o <= 4'b0001;
						// end
						// default:	begin
							// wdata_o <= `ZeroWord;
						// end
					// endcase				
				// end
				// `EXE_LH_OP:		begin
					// mem_addr_o <= mem_addr_i;
					// mem_we <= `WriteDisable_low;
					// mem_ce_o <= `ChipEnable;
					// case (mem_addr_i[1:0])
						// 2'b00:	begin
							// wdata_o <= {{16{mem_data_i[31]}},mem_data_i[31:16]};
							// mem_sel_o <= 4'b1100;
						// end
						// 2'b10:	begin
							// wdata_o <= {{16{mem_data_i[15]}},mem_data_i[15:0]};
							// mem_sel_o <= 4'b0011;
						// end
						// default:	begin
							// wdata_o <= `ZeroWord;
						// end
					// endcase					
				// end
				// `EXE_LHU_OP:		begin
					// mem_addr_o <= mem_addr_i;
					// mem_we <= `WriteDisable_low;
					// mem_ce_o <= `ChipEnable;
					// case (mem_addr_i[1:0])
						// 2'b00:	begin
							// wdata_o <= {{16{1'b0}},mem_data_i[31:16]};
							// mem_sel_o <= 4'b1100;
						// end
						// 2'b10:	begin
							// wdata_o <= {{16{1'b0}},mem_data_i[15:0]};
							// mem_sel_o <= 4'b0011;
						// end
						// default:	begin
							// wdata_o <= `ZeroWord;
						// end
					// endcase				
				// end
				// `EXE_LW_OP:		begin
					// mem_addr_o <= mem_addr_i;
					// mem_we <= `WriteDisable_low;
					// wdata_o <= mem_data_i;
					// mem_sel_o <= 4'b0000;
					// mem_ce_o <= `ChipEnable;		
				// end
				// `EXE_LWL_OP:		begin
					// mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					// mem_we <= `WriteDisable_low;
					// mem_sel_o <= 4'b1111;
					// mem_ce_o <= `ChipEnable;
					// case (mem_addr_i[1:0])
						// 2'b00:	begin
							// wdata_o <= mem_data_i[31:0];
						// end
						// 2'b01:	begin
							// wdata_o <= {mem_data_i[23:0],reg2_i[7:0]};
						// end
						// 2'b10:	begin
							// wdata_o <= {mem_data_i[15:0],reg2_i[15:0]};
						// end
						// 2'b11:	begin
							// wdata_o <= {mem_data_i[7:0],reg2_i[23:0]};	
						// end
						// default:	begin
							// wdata_o <= `ZeroWord;
						// end
					// endcase				
				// end
				// `EXE_LWR_OP:		begin
					// mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					// mem_we <= `WriteDisable_low;
					// mem_sel_o <= 4'b1111;
					// mem_ce_o <= `ChipEnable;
					// case (mem_addr_i[1:0])
						// 2'b00:	begin
							// wdata_o <= {reg2_i[31:8],mem_data_i[31:24]};
						// end
						// 2'b01:	begin
							// wdata_o <= {reg2_i[31:16],mem_data_i[31:16]};
						// end
						// 2'b10:	begin
							// wdata_o <= {reg2_i[31:24],mem_data_i[31:8]};
						// end
						// 2'b11:	begin
							// wdata_o <= mem_data_i;	
						// end
						// default:	begin
							// wdata_o <= `ZeroWord;
						// end
					// endcase					
				// end
				// `EXE_LL_OP:		begin
					// mem_addr_o <= mem_addr_i;
					// mem_we <= `WriteDisable_low;
					// wdata_o <= mem_data_i;	
					// //LLbit_we_o <= 1'b1;
					// //LLbit_value_o <= 1'b1;
					// mem_sel_o <= 4'b1111;			
					// mem_ce_o <= `ChipEnable;						
				// end	
				// `EXE_SB_OP:		begin
					// mem_addr_o <= mem_addr_i;
					// mem_we <= `WriteEnable_low;
					// mem_data_o <= {reg2_i[7:0],reg2_i[7:0],reg2_i[7:0],reg2_i[7:0]};
					// mem_ce_o <= `ChipEnable;
					// case (mem_addr_i[1:0])
						// 2'b00:	begin
							// mem_sel_o <= 4'b1110;
						// end
						// 2'b01:	begin
							// mem_sel_o <= 4'b1101;
						// end
						// 2'b10:	begin
							// mem_sel_o <= 4'b1011;
						// end
						// 2'b11:	begin
							// mem_sel_o <= 4'b0111;	
						// end
						// default:	begin
							// mem_sel_o <= 4'b1111;
						// end
					// endcase				
				// end
				// `EXE_SH_OP:		begin
					// mem_addr_o <= mem_addr_i;
					// mem_we <= `WriteEnable_low;
					// mem_data_o <= {reg2_i[15:0],reg2_i[15:0]};
					// mem_ce_o <= `ChipEnable;
					// case (mem_addr_i[1:0])
						// 2'b00:	begin
							// mem_sel_o <= 4'b1100;
						// end
						// 2'b10:	begin
							// mem_sel_o <= 4'b0011;
						// end
						// default:	begin
							// mem_sel_o <= 4'b0000;
						// end
					// endcase						
				// end
				// `EXE_SW_OP:		begin
					// mem_addr_o <= mem_addr_i;
					// mem_we <= `WriteEnable_low;
					// mem_data_o <= reg2_i;
					// mem_sel_o <= 4'b0000;	
					// mem_ce_o <= `ChipEnable;		
				// end
				// `EXE_SWL_OP:		begin
					// mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					// mem_we <= `WriteEnable_low;
					// mem_ce_o <= `ChipEnable;
					// case (mem_addr_i[1:0])
						// 2'b00:	begin						  
							// mem_sel_o <= 4'b1111;
							// mem_data_o <= reg2_i;
						// end
						// 2'b01:	begin
							// mem_sel_o <= 4'b0111;
							// mem_data_o <= {zero32[7:0],reg2_i[31:8]};
						// end
						// 2'b10:	begin
							// mem_sel_o <= 4'b0011;
							// mem_data_o <= {zero32[15:0],reg2_i[31:16]};
						// end
						// 2'b11:	begin
							// mem_sel_o <= 4'b0001;	
							// mem_data_o <= {zero32[23:0],reg2_i[31:24]};
						// end
						// default:	begin
							// mem_sel_o <= 4'b0000;
						// end
					// endcase							
				// end
				// `EXE_SWR_OP:		begin
					// mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					// mem_we <= `WriteEnable_low;
					// mem_ce_o <= `ChipEnable;
					// case (mem_addr_i[1:0])
						// 2'b00:	begin						  
							// mem_sel_o <= 4'b1000;
							// mem_data_o <= {reg2_i[7:0],zero32[23:0]};
						// end
						// 2'b01:	begin
							// mem_sel_o <= 4'b1100;
							// mem_data_o <= {reg2_i[15:0],zero32[15:0]};
						// end
						// 2'b10:	begin
							// mem_sel_o <= 4'b1110;
							// mem_data_o <= {reg2_i[23:0],zero32[7:0]};
						// end
						// 2'b11:	begin
							// mem_sel_o <= 4'b1111;	
							// mem_data_o <= reg2_i[31:0];
						// end
						// default:	begin
							// mem_sel_o <= 4'b0000;
						// end
					// endcase											
					// end 
				// `EXE_SC_OP:		begin
						// if(LLbit == 1'b1) begin
							// //LLbit_we_o <= 1'b1;
							// //LLbit_value_o <= 1'b0;
							// mem_addr_o <= mem_addr_i;
							// mem_we <= `WriteEnable_low;
							// mem_data_o <= reg2_i;
							// wdata_o <= 32'b1;
							// mem_sel_o <= 4'b0000;		
							// mem_ce_o <= `ChipEnable;				
						// end else begin
							// wdata_o <= 32'b0;
						// end
					// end	
				// default:		begin
				// end
			// endcase							
		// end    
	// end      
	
// always @ (*) begin
		// if(rst == `RstEnable) begin
			// cp0_status <= `ZeroWord;
		// end else if((wb_cp0_reg_we == `WriteEnable) && 
								// (wb_cp0_reg_write_addr == `CP0_REG_STATUS ))begin
			// cp0_status <= wb_cp0_reg_data;
		// end else begin
		  // cp0_status <= cp0_status_i;
		// end
	// end
	
	// always @ (*) begin
		// if(rst == `RstEnable) begin
			// cp0_epc <= `ZeroWord;
		// end else if((wb_cp0_reg_we == `WriteEnable) && 
								// (wb_cp0_reg_write_addr == `CP0_REG_EPC ))begin
			// cp0_epc <= wb_cp0_reg_data;
		// end else begin
		  // cp0_epc <= cp0_epc_i;
		// end
	// end

  // always @ (*) begin
		// if(rst == `RstEnable) begin
			// cp0_cause <= `ZeroWord;
		// end else if((wb_cp0_reg_we == `WriteEnable) && 
								// (wb_cp0_reg_write_addr == `CP0_REG_CAUSE ))begin
			// cp0_cause[9:8] <= wb_cp0_reg_data[9:8];
			// cp0_cause[22] <= wb_cp0_reg_data[22];
			// cp0_cause[23] <= wb_cp0_reg_data[23];
		// end else begin
		  // cp0_cause <= cp0_cause_i;
		// end
	// end

	// always @ (*) begin
		// if(rst == `RstEnable) begin
			// excepttype_o <= `ZeroWord;
		// end else begin
			// excepttype_o <= `ZeroWord;
			
			// if(current_inst_address_i != `ZeroWord) begin
				// if(((cp0_cause[15:8] & (cp0_status[15:8])) != 8'h00) && (cp0_status[1] == 1'b0) && 
							// (cp0_status[0] == 1'b1)) begin
					// excepttype_o <= 32'h00000001;        //interrupt
				// end else if(excepttype_i[8] == 1'b1) begin
			  	// excepttype_o <= 32'h00000008;        //syscall
				// end else if(excepttype_i[9] == 1'b1) begin
					// excepttype_o <= 32'h0000000a;        //inst_invalid
				// end else if(excepttype_i[10] ==1'b1) begin
					// excepttype_o <= 32'h0000000d;        //trap
				// end else if(excepttype_i[11] == 1'b1) begin  //ov
					// excepttype_o <= 32'h0000000c;
				// end else if(excepttype_i[12] == 1'b1) begin  //返回指令
					// excepttype_o <= 32'h0000000e;
				// end
			// end
				
		// end
	// end			
	
// endmodule