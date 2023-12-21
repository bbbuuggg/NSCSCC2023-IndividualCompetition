`include "defines.v"

module ex(

	input wire rst,
	
	//输入ex模块的信号
	input wire[`AluOpBus] aluop_i,
	input wire[`AluSelBus] alusel_i,
	input wire[`RegBus] reg1_i,
	input wire[`RegBus] reg2_i,
	input wire[`RegAddrBus] wd_i,
	input wire wreg_i,
	input wire[`RegBus]           inst_i,
	input   wire[31:0]  ex_pc,
	// input wire[31:0]              excepttype_i,
	// input wire[`RegBus]          current_inst_address_i,

	// //HI、LO寄存器的值
	// input wire[`RegBus]           hi_i,
	// input wire[`RegBus]           lo_i,

	// //回写阶段的指令是否要写HI、LO，用于检测HI、LO的数据相关
	// input wire[`RegBus]           wb_hi_i,
	// input wire[`RegBus]           wb_lo_i,
	// input wire                    wb_whilo_i,
	
	// //访存阶段的指令是否要写HI、LO，用于检测HI、LO的数据相关
	// input wire[`RegBus]           mem_hi_i,
	// input wire[`RegBus]           mem_lo_i,
	// input wire                    mem_whilo_i,
	
	// input wire[`DoubleRegBus]     hilo_temp_i,
	// input wire[1:0]               cnt_i,

	// //与除法模块相连
	// input wire[`DoubleRegBus]     div_result_i,
	// input wire                    div_ready_i,
	
	//是否转移、以及link address
	input wire[`RegBus]           link_address_i,
	input wire                    is_in_delayslot_i,	
	
	// //访存阶段的指令是否要写CP0，用来检测数据相关
	// input wire                    mem_cp0_reg_we,
	// input wire[4:0]               mem_cp0_reg_write_addr,
	// input wire[`RegBus]           mem_cp0_reg_data,
	
	// //回写阶段的指令是否要写CP0，用来检测数据相关
	// input wire                    wb_cp0_reg_we,
	// input wire[4:0]               wb_cp0_reg_write_addr,
	// input wire[`RegBus]           wb_cp0_reg_data,

	// //与CP0相连，读取其中CP0寄存器的值
	// input wire[`RegBus]           cp0_reg_data_i,
	// output reg[4:0]               cp0_reg_read_addr_o,

	// //向下一流水级传递，用于写CP0中的寄存器
	// output reg                    cp0_reg_we_o,
	// output reg[4:0]               cp0_reg_write_addr_o,
	// output reg[`RegBus]           cp0_reg_data_o,
	
	// output reg[`RegBus]           hi_o,
	// output reg[`RegBus]           lo_o,
	// output reg                    whilo_o,	
	
	// output reg[`DoubleRegBus]     hilo_temp_o,
	// output reg[1:0]               cnt_o,

	// output reg[`RegBus]           div_opdata1_o,
	// output reg[`RegBus]           div_opdata2_o,
	// output reg                    div_start_o,
	// output reg                    signed_div_o,
	//mem
    // output  reg [3:0]    mem_op,         //存储类型,同时要送往id阶段以判断load相关
    output  wire [`RegBus]   mem_addr_o,     //存储地址
    output  wire [`RegBus]   mem_data_o,     //存储数据
    output  wire         this_inst_is_load,
	//提前给sram准备输入
	output 	reg [31:0]load_addr,//控制load_addr输出
	output  reg load_we,
	output  reg [31:0]load_data,
	output  reg load_ce,
	output  reg [3:0] load_sel,
	//wb
	output reg[`RegAddrBus] wd_o,
	output reg wreg_o,
	output reg[`RegBus] wdata_o,
	output wire will_be_baseram,
	// //for s &load
	output wire[`AluOpBus]        aluop_o
	// output wire[`RegBus]          mem_addr_o,
	// output wire[`RegBus]          reg2_o

	// output wire[31:0]             excepttype_o,
	// output wire                   is_in_delayslot_o,
	// output wire[`RegBus]          current_inst_address_o,	

	// output reg										stallreq    
	
);

	reg[`DoubleRegBus] mulres;//乘法结果	
	reg[`RegBus] moveres;//移动结果
	
	// //特殊寄存器
	// reg[`RegBus] HI;
	// reg[`RegBus] LO;
	
	wire[`RegBus] reg2_i_mux;//reg2补码
	wire[`RegBus] reg1_i_not;//reg1取反	
	wire[`RegBus] result_sum;//保存加法结果
	wire ov_sum;//溢出情况
	wire reg1_eq_reg2;//第一个操作数是否等于第二个
	wire reg1_lt_reg2;//第一个操作数是否小于第二个
	// wire[`RegBus] opdata1_mult;//被乘数
	// wire[`RegBus] opdata2_mult;//乘数
	// wire[`DoubleRegBus] hilo_temp;//临时乘法结果
	// reg[`DoubleRegBus] hilo_temp1;
	// reg stallreq_for_madd_msub;		
	// reg stallreq_for_div;
	// reg trapassert;
	// reg ovassert;
	
  //aluop_o传递到访存阶段，用于加载、存储指令
   assign aluop_o = aluop_i;
  


  //将两个操作数也传递到访存阶段，也是为记载、存储指令准备的
  assign mem_data_o = reg2_i;
  
  // assign excepttype_o = {excepttype_i[31:12],ovassert,trapassert,excepttype_i[9:8],8'h00};
  
	// assign is_in_delayslot_o = is_in_delayslot_i;
	// assign current_inst_address_o = current_inst_address_i;
	
	assign this_inst_is_load = (aluop_i == `EXE_LB_OP) | (aluop_i == `EXE_LW_OP);
	
	always @(*)begin
		if(rst == `RstEnable)begin
			wdata_o = `ZeroWord;
			wd_o = `ZeroWord;
			wreg_o = `WriteDisable;
		end else begin
			wd_o = wd_i;
			wdata_o = `ZeroWord;
			wreg_o = wreg_i;
			case (aluop_i)
				`EXE_OR_OP: begin //或运算
					wdata_o = reg1_i | reg2_i;
				end
				`EXE_AND_OP:		begin
					wdata_o = reg1_i & reg2_i;
				end
				`EXE_NOR_OP:		begin//或非
					wdata_o = ~(reg1_i |reg2_i);
				end
				`EXE_XOR_OP:		begin//异或
					wdata_o = reg1_i ^ reg2_i;
				end
				`EXE_MUL_OP: begin
                    wdata_o = reg1_i * reg2_i;   //无符号乘法代替有符号乘法
                end      
				`EXE_JALR_OP: begin
                    wdata_o = link_address_i;
                end
				`EXE_JR_OP: begin
                    wdata_o = link_address_i;
                end
				`EXE_J_OP: begin
                    wdata_o = link_address_i;
                end
				`EXE_JAL_OP: begin
                    wdata_o = link_address_i;
                end
				`EXE_BEQ_OP: begin
                    wdata_o = link_address_i;
                end
				`EXE_SLL_OP:	begin
					wdata_o = reg2_i << reg1_i[4:0] ;
				end
				`EXE_SRL_OP:	begin
					wdata_o = reg2_i >> reg1_i[4:0];
				end
				`EXE_SRA_OP:	begin//算术右移
					wdata_o = ({32{reg2_i[31]}} << (6'd32-{1'b0, reg1_i[4:0]})) 
												| reg2_i >> reg1_i[4:0];
				end
				`EXE_SLT_OP, `EXE_SLTU_OP:		begin
					wdata_o = reg1_lt_reg2 ;
				end
				`EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP:		begin
					wdata_o = result_sum; 
				end
				`EXE_SUB_OP, `EXE_SUBU_OP:		begin
					wdata_o = result_sum; 
				end		
				default: begin
					wdata_o = `ZeroWord;
				end
			endcase
		end
	end

	//mem_addr传递到访存阶段，是加载、存储指令对应的存储器地址
     assign mem_addr_o = reg1_i + {{16{inst_i[15]}},inst_i[15:0]};
	 assign will_be_baseram    = (mem_addr_o >= 32'h80000000) 
                    && (mem_addr_o < 32'h80400000);
					
	always @(*)begin
		case(aluop_o)
					`EXE_LB_OP:  begin
						load_addr = mem_addr_o;
						load_data = `ZeroWord;
						load_we = `WriteDisable_low;
						load_ce = `ChipEnable;
						case(load_addr[1:0])
							2'b00: begin
								load_sel = 4'b1110;
							end 
							2'b01: begin
								load_sel = 4'b1101;
							end
							2'b10: begin
								load_sel = 4'b1011;
							end
							2'b11: begin
								load_sel = 4'b0111;
							end
							default : begin
								load_sel = 4'b1111;
							end
						endcase
					end
					`EXE_LW_OP:  begin
						load_addr = mem_addr_o;
						load_data = `ZeroWord;
						load_we = `WriteDisable_low;
						load_ce = `ChipEnable;
						load_sel = 4'b0000;
					end
					`EXE_SB_OP:  begin
						load_addr = mem_addr_o;
						load_data = {4{mem_data_o[7:0]}};    //低字节存储到指定位置
						load_we = `WriteEnable_low;
						load_ce = `ChipEnable;
						case(load_addr[1:0])
							2'b00: begin
								load_sel = 4'b1110;
							end 
							2'b01: begin
								load_sel = 4'b1101;
							end
							2'b10: begin
								load_sel = 4'b1011;
							end
							2'b11: begin
								load_sel = 4'b0111;
							end
							default : begin
								load_sel = 4'b1111;
							end
						endcase
					end
					`EXE_SW_OP:  begin
						load_addr = mem_addr_o;
						load_data = mem_data_o;
						load_we = `WriteEnable_low;
						load_ce = `ChipEnable;
						load_sel = 4'b0000;
					end
					default: begin
						load_addr = `ZeroWord;
						load_data = `ZeroWord;
						load_we = `WriteDisable_low;
						load_ce = `ChipDisable;
						load_sel = 4'b1111;
					end
				endcase
	end
	
    // wire[31:0]  adr_a   =   {{16{inst_i[15]}},inst_i[15:0]};
	
	// always @ (*) begin
		// if(rst == `RstEnable) begin
			// wdata_o <= `ZeroWord;
		// end else begin
			// case (aluop_i)
				// `EXE_SLL_OP:	begin
					// wdata_o <= reg2_i << reg1_i[4:0] ;
				// end
				// `EXE_SRL_OP:	begin
					// wdata_o <= reg2_i >> reg1_i[4:0];
				// end
				// `EXE_SRA_OP:	begin//算术右移
					// wdata_o <= ({32{reg2_i[31]}} << (6'd32-{1'b0, reg1_i[4:0]})) 
												// | reg2_i >> reg1_i[4:0];
				// end
				// default:				begin
					// wdata_o <= `ZeroWord;
				// end
			// endcase
		// end    
	// end   
	
	assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) || (aluop_i == `EXE_SUBU_OP) ||(aluop_i == `EXE_SLT_OP) )  ? (~reg2_i)+1 : reg2_i;//减法或有符号取补码

	assign result_sum = reg1_i + reg2_i_mux;//加减										 

	assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31]) && result_sum[31]) || ((reg1_i[31] && reg2_i_mux[31]) && (!result_sum[31]));//溢出计算  
									
	assign reg1_lt_reg2 = ((aluop_i == `EXE_SLT_OP)) ?((reg1_i[31] && !reg2_i[31]) || (!reg1_i[31] && !reg2_i[31] && result_sum[31])||
	(reg1_i[31] && reg2_i[31] && result_sum[31])) :	(reg1_i < reg2_i);
  
	assign reg1_i_not = ~reg1_i;//取反
	
		// //mem
	 // always @(*) begin
        // if(rst == `RstEnable) begin
            // mem_op = `MEM_NOP_OP;
			// mem_addr_o = `ZeroWord;
            // mem_data_o = `ZeroWord;
        // end else begin
            // case(aluop_i)
                // `EXE_LB_OP: begin
                    // mem_op = `MEM_LB_OP;
					// mem_addr_o = reg1_i + adr_a;
                    // mem_data_o = `ZeroWord;
                // end       
                // `EXE_LW_OP: begin
                    // mem_op = `MEM_LW_OP;
					// mem_addr_o = reg1_i + adr_a;
                    // mem_data_o = `ZeroWord;
                // end       
                // `EXE_SB_OP: begin
                    // mem_op = `MEM_SB_OP;
					// mem_addr_o = reg1_i + adr_a;
                    // mem_data_o = reg2_i;
                // end       
                // `EXE_SW_OP: begin
                    // mem_op = `MEM_SW_OP;
					// mem_addr_o = reg1_i + adr_a;
                    // mem_data_o = reg2_i;
                // end       
                // default: begin
                    // mem_op = `MEM_NOP_OP;
					// mem_addr_o = `ZeroWord;
                    // mem_data_o = `ZeroWord;
                // end
            // endcase
        // end
    // end
endmodule
	// always @ (*) begin
		// if(rst == `RstEnable) begin
			// wdata_o <= `ZeroWord;
		// end else begin
			// case (aluop_i)
				// `EXE_SLT_OP, `EXE_SLTU_OP:		begin
					// wdata_o <= reg1_lt_reg2 ;
				// end
				// `EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP:		begin
					// wdata_o <= result_sum; 
				// end
				// `EXE_SUB_OP, `EXE_SUBU_OP:		begin
					// wdata_o <= result_sum; 
				// end		
				// // `EXE_CLZ_OP:		begin
					// // wdata_o <= reg1_i[31] ? 0 : reg1_i[30] ? 1 : reg1_i[29] ? 2 :
													 // // reg1_i[28] ? 3 : reg1_i[27] ? 4 : reg1_i[26] ? 5 :
													 // // reg1_i[25] ? 6 : reg1_i[24] ? 7 : reg1_i[23] ? 8 : 
													 // // reg1_i[22] ? 9 : reg1_i[21] ? 10 : reg1_i[20] ? 11 :
													 // // reg1_i[19] ? 12 : reg1_i[18] ? 13 : reg1_i[17] ? 14 : 
													 // // reg1_i[16] ? 15 : reg1_i[15] ? 16 : reg1_i[14] ? 17 : 
													 // // reg1_i[13] ? 18 : reg1_i[12] ? 19 : reg1_i[11] ? 20 :
													 // // reg1_i[10] ? 21 : reg1_i[9] ? 22 : reg1_i[8] ? 23 : 
													 // // reg1_i[7] ? 24 : reg1_i[6] ? 25 : reg1_i[5] ? 26 : 
													 // // reg1_i[4] ? 27 : reg1_i[3] ? 28 : reg1_i[2] ? 29 : 
													 // // reg1_i[1] ? 30 : reg1_i[0] ? 31 : 32 ;
				// // end
				// // `EXE_CLO_OP:		begin
					// // wdata_o <= (reg1_i_not[31] ? 0 : reg1_i_not[30] ? 1 : reg1_i_not[29] ? 2 :
													 // // reg1_i_not[28] ? 3 : reg1_i_not[27] ? 4 : reg1_i_not[26] ? 5 :
													 // // reg1_i_not[25] ? 6 : reg1_i_not[24] ? 7 : reg1_i_not[23] ? 8 : 
													 // // reg1_i_not[22] ? 9 : reg1_i_not[21] ? 10 : reg1_i_not[20] ? 11 :
													 // // reg1_i_not[19] ? 12 : reg1_i_not[18] ? 13 : reg1_i_not[17] ? 14 : 
													 // // reg1_i_not[16] ? 15 : reg1_i_not[15] ? 16 : reg1_i_not[14] ? 17 : 
													 // // reg1_i_not[13] ? 18 : reg1_i_not[12] ? 19 : reg1_i_not[11] ? 20 :
													 // // reg1_i_not[10] ? 21 : reg1_i_not[9] ? 22 : reg1_i_not[8] ? 23 : 
													 // // reg1_i_not[7] ? 24 : reg1_i_not[6] ? 25 : reg1_i_not[5] ? 26 : 
													 // // reg1_i_not[4] ? 27 : reg1_i_not[3] ? 28 : reg1_i_not[2] ? 29 : 
													 // // reg1_i_not[1] ? 30 : reg1_i_not[0] ? 31 : 32) ;
				// // end
				// default:				begin
					// wdata_o <= `ZeroWord;
				// end
			// endcase
		// end
	// end

	// always @ (*) begin
		// if(rst == `RstEnable) begin
			// trapassert <= `TrapNotAssert;
		// end else begin
			// trapassert <= `TrapNotAssert;
			// case (aluop_i)
				// `EXE_TEQ_OP, `EXE_TEQI_OP:		begin
					// if( reg1_i == reg2_i ) begin
						// trapassert <= `TrapAssert;
					// end
				// end
				// `EXE_TGE_OP, `EXE_TGEI_OP, `EXE_TGEIU_OP, `EXE_TGEU_OP:		begin
					// if( ~reg1_lt_reg2 ) begin
						// trapassert <= `TrapAssert;
					// end
				// end
				// `EXE_TLT_OP, `EXE_TLTI_OP, `EXE_TLTIU_OP, `EXE_TLTU_OP:		begin
					// if( reg1_lt_reg2 ) begin
						// trapassert <= `TrapAssert;
					// end
				// end
				// `EXE_TNE_OP, `EXE_TNEI_OP:		begin
					// if( reg1_i != reg2_i ) begin
						// trapassert <= `TrapAssert;
					// end
				// end
				// default:				begin
					// trapassert <= `TrapNotAssert;
				// end
			// endcase
		// end
	// end
	
	// //取得乘法操作的操作数，如果是有符号除法且操作数是负数，那么取反加一
		// assign opdata1_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP) ||
													// (aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MSUB_OP))
													// && (reg1_i[31] == 1'b1)) ? (~reg1_i + 1) : reg1_i;

		// assign opdata2_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP) ||
													// (aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MSUB_OP))
													// && (reg2_i[31] == 1'b1)) ? (~reg2_i + 1) : reg2_i;		

		// assign hilo_temp = opdata1_mult * opdata2_mult;																				

		// always @ (*) begin
			// if(rst == `RstEnable) begin
				// mulres <= {`ZeroWord,`ZeroWord};
			// end else if ((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MSUB_OP))begin
				// if(reg1_i[31] ^ reg2_i[31] == 1'b1) begin
					// mulres <= ~hilo_temp + 1;
				// end else begin
				  // mulres <= hilo_temp;
				// end
			// end else begin
					// mulres <= hilo_temp;
			// end
		// end

	// //得到最新的HI、LO寄存器的值，此处要解决指令数据相关问题
	// always @ (*) begin
		// if(rst == `RstEnable) begin
			// {HI,LO} <= {`ZeroWord,`ZeroWord};
		// end else if(mem_whilo_i == `WriteEnable) begin
			// {HI,LO} <= {mem_hi_i,mem_lo_i};
		// end else if(wb_whilo_i == `WriteEnable) begin
			// {HI,LO} <= {wb_hi_i,wb_lo_i};
		// end else begin
			// {HI,LO} <= {hi_i,lo_i};			
		// end
	// end	

	// // always @ (*) begin
		// // stallreq = stallreq_for_madd_msub || stallreq_for_div;
	// // end

	 // // //MADD、MADDU、MSUB、MSUBU指令
	// // always @ (*) begin
		// // if(rst == `RstEnable) begin
			// // hilo_temp_o <= {`ZeroWord,`ZeroWord};
			// // cnt_o <= 2'b00;
			// // stallreq_for_madd_msub <= `NoStop;
		// // end else begin
			
			// // case (aluop_i) 
				// // `EXE_MADD_OP, `EXE_MADDU_OP:		begin
					// // if(cnt_i == 2'b00) begin//第一个时钟周期
						// // hilo_temp_o <= mulres;
						// // cnt_o <= 2'b01;
						// // stallreq_for_madd_msub <= `Stop;
						// // hilo_temp1 <= {`ZeroWord,`ZeroWord};
					// // end else if(cnt_i == 2'b01) begin//第二个时钟周期
						// // hilo_temp_o <= {`ZeroWord,`ZeroWord};						
						// // cnt_o <= 2'b10;
						// // hilo_temp1 <= hilo_temp_i + {HI,LO};
						// // stallreq_for_madd_msub <= `NoStop;
					// // end
				// // end
				// // `EXE_MSUB_OP, `EXE_MSUBU_OP:		begin
					// // if(cnt_i == 2'b00) begin//第一个时钟周期
						// // hilo_temp_o <=  ~mulres + 1 ;
						// // cnt_o <= 2'b01;
						// // stallreq_for_madd_msub <= `Stop;
					// // end else if(cnt_i == 2'b01)begin//第二个时钟周期
						// // hilo_temp_o <= {`ZeroWord,`ZeroWord};						
						// // cnt_o <= 2'b10;
						// // hilo_temp1 <= hilo_temp_i + {HI,LO};
						// // stallreq_for_madd_msub <= `NoStop;
					// // end				
				// // end
				// // default:	begin
					// // hilo_temp_o <= {`ZeroWord,`ZeroWord};
					// // cnt_o <= 2'b00;
					// // stallreq_for_madd_msub <= `NoStop;				
				// // end
			// // endcase
		// // end
	// // end	
	
	// //DIV、DIVU指令	
	// always @ (*) begin
		// if(rst == `RstEnable) begin
			// stallreq_for_div <= `NoStop;
			// div_opdata1_o <= `ZeroWord;
			// div_opdata2_o <= `ZeroWord;
			// div_start_o <= `DivStop;
			// signed_div_o <= 1'b0;
		// end else begin
			// stallreq_for_div <= `NoStop;
			// div_opdata1_o <= `ZeroWord;
			// div_opdata2_o <= `ZeroWord;
			// div_start_o <= `DivStop;
			// signed_div_o <= 1'b0;	
			// case (aluop_i) 
				// `EXE_DIV_OP:		begin
					// if(div_ready_i == `DivResultNotReady) begin
						// div_opdata1_o <= reg1_i;
						// div_opdata2_o <= reg2_i;
						// div_start_o <= `DivStart;
						// signed_div_o <= 1'b1;
						// stallreq_for_div <= `Stop;
					// end else if(div_ready_i == `DivResultReady) begin
						// div_opdata1_o <= reg1_i;
						// div_opdata2_o <= reg2_i;
						// div_start_o <= `DivStop;
						// signed_div_o <= 1'b1;
						// stallreq_for_div <= `NoStop;
					// end else begin						
						// div_opdata1_o <= `ZeroWord;
						// div_opdata2_o <= `ZeroWord;
						// div_start_o <= `DivStop;
						// signed_div_o <= 1'b0;
						// stallreq_for_div <= `NoStop;
					// end					
				// end
				// `EXE_DIVU_OP:		begin
					// if(div_ready_i == `DivResultNotReady) begin
	    			// div_opdata1_o <= reg1_i;
						// div_opdata2_o <= reg2_i;
						// div_start_o <= `DivStart;
						// signed_div_o <= 1'b0;
						// stallreq_for_div <= `Stop;
					// end else if(div_ready_i == `DivResultReady) begin
	    			// div_opdata1_o <= reg1_i;
						// div_opdata2_o <= reg2_i;
						// div_start_o <= `DivStop;
						// signed_div_o <= 1'b0;
						// stallreq_for_div <= `NoStop;
					// end else begin						
	    			// div_opdata1_o <= `ZeroWord;
						// div_opdata2_o <= `ZeroWord;
						// div_start_o <= `DivStop;
						// signed_div_o <= 1'b0;
						// stallreq_for_div <= `NoStop;
					// end					
				// end
				// default: begin
				// end
			// endcase
		// end
	// end	
	
	// //MFHI、MFLO、MOVN、MOVZ指令
	// always @ (*) begin
		// if(rst == `RstEnable) begin
	  	// moveres <= `ZeroWord;
	  // end else begin
	   // moveres <= `ZeroWord;
	   // case (aluop_i)
	   	// `EXE_MFHI_OP:		begin
	   		// moveres <= HI;
	   	// end
	   	// `EXE_MFLO_OP:		begin
	   		// moveres <= LO;
	   	// end
	   	// `EXE_MOVZ_OP:		begin
	   		// moveres <= reg1_i;
	   	// end
	   	// `EXE_MOVN_OP:		begin
	   		// moveres <= reg1_i;
	   	// end
		// `EXE_MFC0_OP:		begin
			// // cp0_reg_read_addr_o <= inst_i[15:11];
	   		// moveres <= cp0_reg_data_i;
	   		// // if( mem_cp0_reg_we == `WriteEnable && mem_cp0_reg_write_addr == inst_i[15:11] ) begin
	   				// // moveres <= mem_cp0_reg_data;
	   		// // end else if( wb_cp0_reg_we == `WriteEnable && wb_cp0_reg_write_addr == inst_i[15:11] ) begin
	   				// // moveres <= wb_cp0_reg_data;
	   		// // end
	   	// end	   	
	   	// default : begin
	   	// end
	   // endcase
	  // end
	// end	 

 // always @ (*) begin//选数据输出
	 // wd_o <= wd_i;
	 	 	 	
	 // if(((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_ADDI_OP) || //溢出不写
	      // (aluop_i == `EXE_SUB_OP)) && (ov_sum == 1'b1)) begin
	 	// wreg_o <= `WriteDisable;
		// // ovassert <= 1'b1;
	 // end else begin
	  // wreg_o <= wreg_i;
	  // // ovassert <= 1'b0;
	 // end
	 
	 // case ( alusel_i ) 
	 	// `EXE_RES_LOGIC:		begin
	 		// wdata_o <= wdata_o;
	 	// end
	 	// `EXE_RES_SHIFT:		begin
	 		// wdata_o <= wdata_o;
	 	// end	 	
	 	// `EXE_RES_MOVE:		begin
	 		// wdata_o <= moveres;
	 	// end	 	
	 	// `EXE_RES_ARITHMETIC:	begin
	 		// wdata_o <= wdata_o;
	 	// end
	 	// `EXE_RES_MUL:		begin
	 		// wdata_o <= mulres[31:0];
	 	// end	 	
		// `EXE_RES_JUMP_BRANCH:	begin
	 		// wdata_o <= link_address_i;
	 	// end	 	
	 	// default:					begin
	 		// wdata_o <= `ZeroWord;
	 	// end
	 // endcase
 // end	

	// always @ (*) begin
		// if(rst == `RstEnable) begin
			// whilo_o <= `WriteDisable;
			// hi_o <= `ZeroWord;
			// lo_o <= `ZeroWord;		
		// end else if((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MULTU_OP)) begin
			// whilo_o <= `WriteEnable;
			// hi_o <= mulres[63:32];
			// lo_o <= mulres[31:0];	
		// end else if((aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MADDU_OP)) begin
			// whilo_o <= `WriteEnable;
			// hi_o <= hilo_temp1[63:32];
			// lo_o <= hilo_temp1[31:0];
		// end else if((aluop_i == `EXE_MSUB_OP) || (aluop_i == `EXE_MSUBU_OP)) begin
			// whilo_o <= `WriteEnable;
			// hi_o <= hilo_temp1[63:32];
			// lo_o <= hilo_temp1[31:0];	
		// end else if((aluop_i == `EXE_DIV_OP) || (aluop_i == `EXE_DIVU_OP)) begin
			// whilo_o <= `WriteEnable;
			// hi_o <= div_result_i[63:32];
			// lo_o <= div_result_i[31:0];				
		// end else if(aluop_i == `EXE_MTHI_OP) begin
			// whilo_o <= `WriteEnable;
			// hi_o <= reg1_i;
			// lo_o <= LO;
		// end else if(aluop_i == `EXE_MTLO_OP) begin
			// whilo_o <= `WriteEnable;
			// hi_o <= HI;
			// lo_o <= reg1_i;
		// end else begin
			// whilo_o <= `WriteDisable;
			// hi_o <= `ZeroWord;
			// lo_o <= `ZeroWord;
		// end				
	// end			
	
	// always @ (*) begin
		// if(rst == `RstEnable) begin
			// cp0_reg_write_addr_o <= 5'b00000;
			// cp0_reg_we_o <= `WriteDisable;
			// cp0_reg_data_o <= `ZeroWord;
		// end else if(aluop_i == `EXE_MTC0_OP) begin
			// cp0_reg_write_addr_o <= inst_i[15:11];
			// cp0_reg_we_o <= `WriteEnable;
			// cp0_reg_data_o <= reg1_i;
	  // end else begin
			// cp0_reg_write_addr_o <= 5'b00000;
			// cp0_reg_we_o <= `WriteDisable;
			// cp0_reg_data_o <= `ZeroWord;
		// end				
	// end		
	

	
	
	