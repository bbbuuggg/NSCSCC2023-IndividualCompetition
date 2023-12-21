`include "defines.v"

module trymips(

	input wire clk,
	input wire rst,
	// output wire stallreq_from_id,
	output wire stall,
	
	// input wire[5:0]                int_i,
	input wire[`RegBus] rom_data_i,
	output wire[`RegBus]  rom_addr_o,
	output wire      rom_ce_o,
	
	output  wire is_base_ram,
	output  wire is_ext_ram,
	
	output  wire ex_base_ram,
	output  wire ex_ext_ram,
	
	input  wire baseram_finish,
	//连接数据存储器data_ram
	input wire[`RegBus]           ram_data_i,
	output wire store_baseram,
	input wire load_baseram,
	output wire id_branch_flag_o,
	output wire[`RegBus] branch_target_address,
	
	output wire will_be_baseram,
	output wire [31:0] load_addr,
	output wire load_we,
	output wire [31:0]load_data,
	output wire load_ce,
	output wire [3:0] load_sel,
	
	output	wire   this_inst_is_load,
	output wire[`RegBus]           ram_addr_o,
	output wire[`RegBus]           ram_data_o,
	output wire                    ram_we_o,
	output wire[3:0]               ram_sel_o,
	output wire                    ram_ce_o
	
	// output wire                    timer_int_o
	
);
	wire store_bfd;
	wire pre_load_bfd;
	wire[`RegBus]  rom_addr_o_i;
	wire[`InstAddrBus] pc;
	wire[`InstAddrBus] id_pc_i;
	wire[`InstBus] id_inst_i;
	wire pre_branch;
	wire exe_ls;
	wire pre_pre_inst_is_load;
	wire[31:0]  last_store_addr;
	wire[31:0]  last_store_data;
	wire[31:0]   mem_addr_o;
	wire[31:0]   mem_data_o;
	wire[31:0]  bbb_ex_pc_o;
	wire[`AluOpBus]    mem_op;
	wire[31:0]  ex_mem_pc_o;
	wire[`AluOpBus]   mem_mem_op;
	wire[31:0]  mem_mem_addr_o;
	wire[31:0]  mem_mem_data_o;
	wire stallreq_from_id;
	wire         stallreq_from_baseram;
	//连接译码阶段ID模块的输出与ID/EX模块的输入
	wire[`AluOpBus] id_aluop_o;
	wire[`AluSelBus] id_alusel_o;
	wire[`RegBus] id_reg1_o;
	wire[`RegBus] id_reg2_o;
	wire id_reg1_file;
	wire id_reg2_file;
	wire id_wreg_o;
	wire[`RegAddrBus] id_wd_o;
	wire id_is_in_delayslot_o;
	wire[`RegBus] id_link_address_o;	
	wire[`RegBus] id_inst_o;
	wire[`RegBus] id_imm_o;
	wire[`RegBus] pc_plus_8;//保存第二条地址
	wire[`RegBus] pc_plus_4;//保存下一条地址
	wire[`RegBus] imm_sll2_signedext; //offset左移两位再扩展
	// wire[31:0] id_excepttype_o;
	// wire[`RegBus] id_current_inst_address_o;
	
	//连接ID/EX模块的输出与bbb模块的输入
	wire[`AluOpBus] bbb_aluop_i;
	wire[`AluSelBus] bbb_alusel_i;
	wire[`RegBus] bbb_reg1_i;
	wire[`RegBus] bbb_reg2_i;
	wire bbb_reg1_file;
	wire bbb_reg2_file;
	wire bbb_wreg_i;
	wire[`RegAddrBus] bbb_wd_i;
	wire bbb_is_in_delayslot_i;	
	wire[`RegBus] bbb_link_address_i;
	wire[`RegBus] bbb_inst_i;
	wire[31:0]  id_bbb_pc_o;
	wire bbb_reg1_read_i;
	wire bbb_reg2_read_i;
	wire[`RegAddrBus] bbb_reg1_addr_i;
	wire[`RegAddrBus] bbb_reg2_addr_i;
	wire[`RegBus]bbb_imm_i;
	wire[`RegBus] bbb_pc_plus_8;//保存第二条地址
	wire[`RegBus] bbb_pc_plus_4;//保存下一条地址
	wire[`RegBus] bbb_imm_sll2_signedext; //offset左移两位再扩展
	//连接bbb模块的输出与bbb/EX模块的输入
	wire[`AluOpBus] bbb_aluop_o;
	wire[`AluSelBus] bbb_alusel_o;
	wire[`RegBus] bbb_reg1_o;
	wire[`RegBus] bbb_reg2_o;
	wire bbb_wreg_o;
	wire[`RegAddrBus] bbb_wd_o;
	wire bbb_is_in_delayslot_o;
	wire[`RegBus] bbb_link_address_o;	
	wire[`RegBus] bbb_inst_o;
	wire[31:0]  bbb_pc_o;

	//连接bbb/EX模块的输出与执行阶段EX模块的输入
	wire[`AluOpBus] ex_aluop_i;
	wire[`AluSelBus] ex_alusel_i;
	wire[`RegBus] ex_reg1_i;
	wire[`RegBus] ex_reg2_i;
	wire ex_wreg_i;
	wire[`RegAddrBus] ex_wd_i;
	wire ex_is_in_delayslot_i;	
	wire[`RegBus] ex_link_address_i;
	wire[`RegBus] ex_inst_i;
	// wire[31:0] ex_excepttype_i;	
	// wire[`RegBus] ex_current_inst_address_i;
	
	//连接执行阶段EX模块的输出与EX/MEM模块的输入
	wire ex_wreg_o;
	wire[`RegAddrBus] ex_wd_o;
	wire[`RegBus] ex_wdata_o;
	wire[`RegBus] ex_hi_o;
	wire[`RegBus] ex_lo_o;
	wire ex_whilo_o;
	wire[`AluOpBus] ex_aluop_o;
	wire[`RegBus] ex_mem_addr_o;

	wire[`RegBus] ex_reg1_o;
	wire[`RegBus] ex_reg2_o;
	// wire ex_cp0_reg_we_o;
	// wire[4:0] ex_cp0_reg_write_addr_o;
	// wire[`RegBus] ex_cp0_reg_data_o; 
	// wire[31:0] ex_excepttype_o;
	// wire[`RegBus] ex_current_inst_address_o;
	// wire ex_is_in_delayslot_o;
	
	//连接EX/MEM模块的输出与访存阶段MEM模块的输入
	wire mem_wreg_i;
	wire[`RegAddrBus] mem_wd_i;
	wire[`RegBus] mem_wdata_i;
	wire[`RegBus] mem_hi_i;
	wire[`RegBus] mem_lo_i;
	wire mem_whilo_i;	
	wire[`AluOpBus] mem_aluop_i;
	wire[`RegBus] mem_mem_addr_i;
	wire[`RegBus] mem_reg1_i;
	wire[`RegBus] mem_reg2_i;
	// wire mem_cp0_reg_we_i;
	// wire[4:0] mem_cp0_reg_write_addr_i;
	// wire[`RegBus] mem_cp0_reg_data_i;	
	// wire[31:0] mem_excepttype_i;	
	// wire mem_is_in_delayslot_i;
	// wire[`RegBus] mem_current_inst_address_i;	
	
	//连接访存阶段MEM模块的输出与MEM/WB模块的输入
	wire mem_wreg_o;
	wire[`RegAddrBus] mem_wd_o;
	wire[`RegBus] mem_wdata_o;
	wire[`RegBus] mem_hi_o;
	wire[`RegBus] mem_lo_o;
	wire mem_whilo_o;	
    // wire mem_LLbit_value_o;
	// wire mem_LLbit_we_o;	
	// wire mem_cp0_reg_we_o;
	// wire[4:0] mem_cp0_reg_write_addr_o;
	// wire[`RegBus] mem_cp0_reg_data_o;	
	// wire[31:0] mem_excepttype_o;
	// wire mem_is_in_delayslot_o;
	// wire[`RegBus] mem_current_inst_address_o;
	
	//连接MEM/WB模块的输出与回写阶段的输入	
	wire wb_wreg_i;
	wire[`RegAddrBus] wb_wd_i;
	wire[`RegBus] wb_wdata_i;
	wire[`RegBus] wb_hi_i;
	wire[`RegBus] wb_lo_i;
	wire wb_whilo_i;
    // wire wb_LLbit_value_i;
	// wire wb_LLbit_we_i;
	// wire wb_cp0_reg_we_i;
	// wire[4:0] wb_cp0_reg_write_addr_i;
	// wire[`RegBus] wb_cp0_reg_data_i;
	// wire[31:0] wb_excepttype_i;
	// wire wb_is_in_delayslot_i;
	// wire[`RegBus] wb_current_inst_address_i;
	
	//连接译码阶段ID模块与通用寄存器Regfile模块
  wire reg1_read;
  wire reg2_read;
  wire[`RegBus] reg1_data;
  wire[`RegBus] reg2_data;
  wire[`RegAddrBus] reg1_addr;
  wire[`RegAddrBus] reg2_addr;
  
  	// //连接执行阶段与hilo模块的输出，读取HI、LO寄存器
	// wire[`RegBus] 	hi;
	// wire[`RegBus]   lo;

  // //连接执行阶段与ex_reg模块，用于多周期的MADD、MADDU、MSUB、MSUBU指令
	// wire[`DoubleRegBus] hilo_temp_o;
	// wire[1:0] cnt_o;
	
	// wire[`DoubleRegBus] hilo_temp_i;
	// wire[1:0] cnt_i;

	// wire[`DoubleRegBus] div_result;
	// wire div_ready;
	// wire[`RegBus] div_opdata1;
	// wire[`RegBus] div_opdata2;
	// wire div_start;
	// wire div_annul;
	// wire signed_div;
	
	wire is_in_delayslot_i;
	wire is_in_delayslot_o;
	wire next_inst_in_delayslot_o;
	
	wire op_for_baseram;
	wire pre_load_baseram;
	wire pre_load_extram;
	wire [2:0]cnt_o;
	wire [2:0]cnt_pc_o;
	wire [2:0]cnt_bingo_o;
	wire [2:0]scnt_o;
	wire [2:0]cnt_ext_o;
	wire [2:0]scnt_ext_o;
	wire bingo;
	wire mulce;
	wire [31:0]mulans;
	wire store_extram;
	
	
	// wire stallreq_from_id;	
	wire stallreq_from_ex;
	wire related;
  
    // wire LLbit_o;
	
	// wire[`RegBus] cp0_data_o;
	// wire[4:0] cp0_raddr_i;	
	
	// wire flush;
	// wire[`RegBus] new_pc;

	// wire[`RegBus] cp0_count;
	// wire[`RegBus]	cp0_compare;
	// wire[`RegBus]	cp0_status;
	// wire[`RegBus]	cp0_cause;
	// wire[`RegBus]	cp0_epc;
	// wire[`RegBus]	cp0_config;
	// wire[`RegBus]	cp0_prid; 

	// wire[`RegBus] latest_epc;
	
  //pc_reg例化
	pc_reg pc_reg0(
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.baseram_finish(baseram_finish),
		// .flush(flush),
		// .new_pc(new_pc),
		.ex_base_ram(ex_base_ram),
		.ex_ext_ram(ex_ext_ram),
		.store_baseram(store_baseram),
		.store_extram(store_extram),
		.pre_load_baseram(pre_load_baseram),
		.pre_load_extram(pre_load_extram),
		.store_bfd(store_bfd),
		.pre_load_bfd(pre_load_bfd),
		.cnt_o(cnt_o),
		.cnt_pc_o(cnt_pc_o),
		.cnt_bingo_o(cnt_bingo_o),
		.scnt_o(scnt_o),
		.cnt_ext_o(cnt_ext_o),
		.scnt_ext_o(scnt_ext_o),
		.bingo(bingo),
		.load_baseram(load_baseram),
		.branch_flag_i(id_branch_flag_o),
		.id_pre_branch(pre_branch),
		.branch_target_address_i(branch_target_address),
		.pre_exe_ls(exe_ls),
		
		.pre_pc(rom_addr_o),//给sram的信号
		.pre_ce(rom_ce_o),
		.pc(rom_addr_o_i)//给cpu的pc信号
			
	);
	
  // assign rom_addr_o = pc;

  //IF/ID模块例化
	if_id if_id0(
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.bingo(bingo),
		// .flush(flush),
		.load_baseram(load_baseram),
		.baseram_finish(baseram_finish),
		.ex_base_ram(ex_base_ram),
		.ex_ext_ram(ex_ext_ram),
		.store_baseram(store_baseram),
		.store_extram(store_extram),
		.branch_flag_i(id_branch_flag_o),
		.branch_target_address_i(branch_target_address),
		.exe_ls(exe_ls),
		
		.cnt_pc_o(cnt_pc_o),
		.related(related),
		
		.pre_load_baseram(pre_load_baseram),
		.pre_load_extram(pre_load_extram),
		.store_bfd(store_bfd),
		.pre_load_bfd(pre_load_bfd),
		.cnt_o(cnt_o),
		.cnt_bingo_o(cnt_bingo_o),
		.scnt_o(scnt_o),
		.cnt_ext_o(cnt_ext_o),
		.scnt_ext_o(scnt_ext_o),
		.if_pc(rom_addr_o_i),
		.if_inst(rom_data_i),
		.id_pc(id_pc_i),
		.id_inst(id_inst_i)      	
	);
	
	//译码阶段ID模块
	id id0(
		.clk(clk),
		.rst(rst),
		.pc_i(id_pc_i),
		.inst_i(id_inst_i),
		// .is_base_ram(is_base_ram),
		
		// .ex_aluop_i(ex_aluop_o),
		// .reg1_data_i(reg1_data),
		// .reg2_data_i(reg2_data),
		//处于执行阶段的指令要写入的目的寄存器信息
		.ex_wreg_i(ex_wreg_o),
		.ex_wdata_i(ex_wdata_o),
		.ex_wd_i(ex_wd_o),
		.pre_inst_is_load(this_inst_is_load),
		.pre_pre_inst_is_load(pre_pre_inst_is_load),
		.pre_branch(pre_branch),
		
		.stallreq(stallreq_from_id),
		
		//处于访存阶段的指令要写入的目的寄存器信息
		.mem_wreg_i(mem_wreg_o),
		.mem_wdata_i(mem_wdata_o),
		.mem_wd_i(mem_wd_o),
		
		.bbb_wd_i(bbb_wd_o),
		.bbb_wreg_i(bbb_wreg_o),

		.is_in_delayslot_i(is_in_delayslot_i),
		
		// .last_store_addr(last_store_addr),
		// .last_store_data(last_store_data),
		// .ex_load_addr(mem_addr_o),
		//送到regfile的信息
		.reg1_read_o(reg1_read),
		.reg2_read_o(reg2_read), 	  

		.reg1_addr_o(reg1_addr),
		.reg2_addr_o(reg2_addr), 
	  
		//送到ID/EX模块的信息
		.aluop_o(id_aluop_o),
		.alusel_o(id_alusel_o),
		.reg1_o(id_reg1_o),
		.reg2_o(id_reg2_o),
		.reg1_file(id_reg1_file),
		.reg2_file(id_reg2_file),
		
		.wd_o(id_wd_o),
		.wreg_o(id_wreg_o),
		// .excepttype_o(id_excepttype_o),
		.inst_o(id_inst_o),
		.imm(id_imm_o),
		
		.pc_plus_8(pc_plus_8),//保存第二条地址
		.pc_plus_4(pc_plus_4),//保存下一条地址
		.imm_sll2_signedext(imm_sll2_signedext), //offset左移两位再扩展
		
		.related(related),
		
		.is_in_delayslot_o(id_is_in_delayslot_o)
		// .current_inst_address_o(id_current_inst_address_o),
		
		// .stall(stall)
	);
	
	mult_gen_0 your_instance_name (
	  .CLK(clk),  // input wire CLK
	  .A(ex_reg1_i),      // input wire [31 : 0] A
	  .B(ex_reg2_i),      // input wire [31 : 0] B
	  .SCLR(stall),  // input wire SCLR
	  .CE(mulce),    // input wire CE
	  .P(mulans)      // output wire [31 : 0] P
	);

  //通用寄存器Regfile例化
	regfile regfile1(
		.clk (clk),
		.rst (rst),
		.we	(wb_wreg_i),
		.waddr (wb_wd_i),
		.wdata (wb_wdata_i),
		.pre_waddr(mem_wd_o),
		.pre_we	(mem_wreg_o),
		.pre_wdata (mem_wdata_o),
		.re1 (reg1_read),
		.raddr1 (reg1_addr),
		.rdata1 (reg1_data),
		.re2 (reg2_read),
		.raddr2 (reg2_addr),
		.rdata2 (reg2_data)
	);

	//ID/EX模块
	id_ex id_ex0(
		.clk(clk),
		.rst(rst),
		
		.stall(stall),
		// .flush(flush),
		
		.bingo(bingo),
		
		//从译码阶段ID模块传递的信息
		.id_aluop(id_aluop_o),
		.id_alusel(id_alusel_o),
		.id_reg1(id_reg1_o),
		.id_reg2(id_reg2_o),
		.id_reg1_file(id_reg1_file),
		.id_reg2_file(id_reg2_file),
		.id_wd(id_wd_o),
		.id_wreg(id_wreg_o),
		.id_link_address(id_link_address_o),
		.id_is_in_delayslot(id_is_in_delayslot_o),
		.next_inst_in_delayslot_i(next_inst_in_delayslot_o),	
		.id_inst(id_inst_o),
		.id_pc(id_pc_i),
		.id_imm(id_imm_o),
		.pc_plus_8(pc_plus_8),//保存第二条地址
		.pc_plus_4(pc_plus_4),//保存下一条地址
		.imm_sll2_signedext(imm_sll2_signedext), //offset左移两位再扩展
		.related(related),
		
		.load_baseram(load_baseram),
		.store_baseram(store_baseram),
		.store_extram(store_extram),
		.branch_flag_i(id_branch_flag_o),
		.branch_target_address_i(branch_target_address),
		.pre_load_baseram(pre_load_baseram),
		.pre_load_extram(pre_load_extram),
		// .cnt_o(cnt_o),
		// .scnt_o(scnt_o),
		// .cnt_ext_o(cnt_ext_o),
		// .scnt_ext_o(scnt_ext_o),
		
		.id_reg1_read_o(reg1_read),
		.id_reg2_read_o(reg2_read), 	  
		.id_reg1_addr_o(reg1_addr),
		.id_reg2_addr_o(reg2_addr), 
		// .id_excepttype(id_excepttype_o),
		// .id_current_inst_address(id_current_inst_address_o),
		.mem_op_check(op_for_baseram),
		.will_be_baseram(will_be_baseram),
		//传递到执行阶段EX模块的信息
		.bbb_reg1_read_o(bbb_reg1_read_i),
		.bbb_reg2_read_o(bbb_reg2_read_i), 	  
		.bbb_reg1_addr_o(bbb_reg1_addr_i),
		.bbb_reg2_addr_o(bbb_reg2_addr_i), 
		.bbb_aluop(bbb_aluop_i),
		.bbb_alusel(bbb_alusel_i),
		.bbb_reg1(bbb_reg1_i),
		.bbb_reg2(bbb_reg2_i),
		.bbb_reg1_file(bbb_reg1_file),
		.bbb_reg2_file(bbb_reg2_file),
		.bbb_wd(bbb_wd_i),
		.bbb_wreg(bbb_wreg_i),
		.bbb_link_address(bbb_link_address_i),
		.bbb_pc(id_bbb_pc_o),
		.bbb_imm(bbb_imm_i),
		.bbb_pc_plus_8(bbb_pc_plus_8),//保存第二条地址
		.bbb_pc_plus_4(bbb_pc_plus_4),//保存下一条地址
		.bbb_imm_sll2_signedext(bbb_imm_sll2_signedext), //offset左移两位再扩展
		.bbb_is_in_delayslot(bbb_is_in_delayslot_i),
		.is_in_delayslot_o(is_in_delayslot_i),
		.bbb_inst(bbb_inst_i)
		// .ex_excepttype(ex_excepttype_i),
		// .ex_current_inst_address(ex_current_inst_address_i)		
	);		
	
	//EX模块
	bbb bbb0(
		.rst(rst),
		.clk(clk),
		.pre_inst_is_load(this_inst_is_load),
		.imm(bbb_imm_i),
		.pc_plus_8(bbb_pc_plus_8),//保存第二条地址
		.pc_plus_4(bbb_pc_plus_4),//保存下一条地址
		.imm_sll2_signedext(bbb_imm_sll2_signedext), //offset左移两位再扩展	
		.store_baseram(store_baseram),
		.store_extram(store_extram),
		.pre_load_baseram(pre_load_baseram),
		.pre_load_extram(pre_load_extram),
		.store_bfd(store_bfd),
		.pre_load_bfd(pre_load_bfd),
		.branch_flag_o(id_branch_flag_o),
		.branch_target_address_o(branch_target_address), 
		.id_pre_branch(pre_branch),
		.next_inst_in_delayslot_o(next_inst_in_delayslot_o),	
		//处于执行阶段的指令要写入的目的寄存器信息
		.ex_wreg_i(ex_wreg_o),
		.ex_wdata_i(ex_wdata_o),
		.ex_wd_i(ex_wd_o),

		//处于访存阶段的指令要写入的目的寄存器信息
		.mem_wreg_i(mem_wreg_o),
		.mem_wdata_i(mem_wdata_o),
		.mem_wd_i(mem_wd_o),
		
		//id送到regfile的信息
		// .reg1_read_o(bbb_reg1_read_i),
		// .reg2_read_o(bbb_reg2_read_i), 	  

		// .reg1_addr_o(bbb_reg1_addr_i),
		// .reg2_addr_o(bbb_reg2_addr_i), 
		.reg1_read_o(reg1_read),
		.reg2_read_o(reg2_read), 	  
		.reg1_addr_o(reg1_addr),
		.reg2_addr_o(reg2_addr),
		//送到执行阶段bbb模块的信息
		.aluop_i(bbb_aluop_i),
		.alusel_i(bbb_alusel_i),
		.bbb_reg1(bbb_reg1_i),
		.bbb_reg2(bbb_reg2_i),
		.bbb_reg1_file(bbb_reg1_file),
		.bbb_reg2_file(bbb_reg2_file),
		.reg1_data_i(reg1_data),
		.reg2_data_i(reg2_data),
		.wd_i(bbb_wd_i),
		.wreg_i(bbb_wreg_i),
		.link_address_i(bbb_link_address_i),	
		.bbb_pc(id_bbb_pc_o),
		.is_in_delayslot_i(bbb_is_in_delayslot_i),
		.inst_i(bbb_inst_i),	  
		
		.bbb_inst_is_load(this_inst_is_load),
		
		// .stallreq(stallreq_from_id),
		//送到bbb/EX模块的信息
		.aluop_o(bbb_aluop_o),
		.alusel_o(bbb_alusel_o),
		.reg1_o(bbb_reg1_o),
		.reg2_o(bbb_reg2_o),
		.wd_o(bbb_wd_o),
		.wreg_o(bbb_wreg_o),
		.inst_o(bbb_inst_o),
		.ex_pc(bbb_pc_o),
		.link_address_o(bbb_link_address_o),
		.is_in_delayslot_o(bbb_is_in_delayslot_o)
	);
		//bbb/EX模块
	bbb_ex bbb_ex0(
		.clk(clk),
		.rst(rst),
		
		.stall(stall),
		// .flush(flush),
		
		//从译码阶段ID模块传递的信息
		.bbb_aluop(bbb_aluop_o),
		.bbb_alusel(bbb_alusel_o),
		.bbb_reg1(bbb_reg1_o),
		.bbb_reg2(bbb_reg2_o),
		.bbb_wd(bbb_wd_o),
		.bbb_wreg(bbb_wreg_o),
		.bbb_inst(bbb_inst_o),
		.bbb_pc_i(bbb_pc_o),
		.bbb_link_address(bbb_link_address_o),
		.bbb_is_in_delayslot(bbb_is_in_delayslot_o),
		
		//传递到执行阶段EX模块的信息
		.ex_aluop(ex_aluop_i),
		.ex_alusel(ex_alusel_i),
		.ex_reg1(ex_reg1_i),
		.ex_reg2(ex_reg2_i),
		.ex_wd(ex_wd_i),
		.ex_wreg(ex_wreg_i),
		.ex_link_address(ex_link_address_i),
		.ex_pc(bbb_ex_pc_o),
		.ex_is_in_delayslot(ex_is_in_delayslot_i),
		.ex_inst(ex_inst_i)
		// .ex_excepttype(ex_excepttype_i),
		// .ex_current_inst_address(ex_current_inst_address_i)		
	);		
	
	//EX模块
	ex ex0(
		.rst(rst),
	
		//送到执行阶段EX模块的信息
		.aluop_i(ex_aluop_i),
		.alusel_i(ex_alusel_i),
		.reg1_i(ex_reg1_i),
		.reg2_i(ex_reg2_i),
		.wd_i(ex_wd_i),
		.wreg_i(ex_wreg_i),
		// .hi_i(hi),
		// .lo_i(lo),
		.inst_i(ex_inst_i),
		.ex_pc(bbb_ex_pc_o),
		
		.mulce(mulce),
		// .wb_hi_i(wb_hi_i),
		// .wb_lo_i(wb_lo_i),
		// .wb_whilo_i(wb_whilo_i),
		// .mem_hi_i(mem_hi_o),
		// .mem_lo_i(mem_lo_o),
		// .mem_whilo_i(mem_whilo_o),
		
		.this_inst_is_load(pre_pre_inst_is_load),
		// .hilo_temp_i(hilo_temp_i),
		// .cnt_i(cnt_i),
	  
		// .div_result_i(div_result),
		// .div_ready_i(div_ready), 
	  
		.link_address_i(ex_link_address_i),
		.is_in_delayslot_i(ex_is_in_delayslot_i),
		

		
		// .excepttype_i(ex_excepttype_i),
		// .current_inst_address_i(ex_current_inst_address_i),
		
		// //访存阶段写CP0
		// .mem_cp0_reg_we(mem_cp0_reg_we_o),
		// .mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_o),
		// .mem_cp0_reg_data(mem_cp0_reg_data_o),
	
		// //回写阶段写CP0
		// .wb_cp0_reg_we(wb_cp0_reg_we_i),
		// .wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
		// .wb_cp0_reg_data(wb_cp0_reg_data_i),

		// .cp0_reg_data_i(cp0_data_o),
		// .cp0_reg_read_addr_o(cp0_raddr_i),
		
		// //向下一流水级传递，用于写CP0中的寄存器
		// .cp0_reg_we_o(ex_cp0_reg_we_o),
		// .cp0_reg_write_addr_o(ex_cp0_reg_write_addr_o),
		// .cp0_reg_data_o(ex_cp0_reg_data_o),	  
			  
		//mem
		.aluop_o(mem_op),
		.mem_addr_o(mem_addr_o),
		.mem_data_o(mem_data_o),
		// .this_inst_is_load(this_inst_is_load),
		.load_addr(load_addr),
		.load_we(load_we),
		.load_data(load_data),
		.load_ce(load_ce),
		.load_sel(load_sel),
		
		.ex_base_ram(ex_base_ram),
		.ex_ext_ram(ex_ext_ram),
		
		.will_be_baseram(will_be_baseram),
		//EX模块的输出到EX/MEM模块信息
		.wd_o(ex_wd_o),
		.wreg_o(ex_wreg_o),
		.wdata_o(ex_wdata_o)
		
		// .hi_o(ex_hi_o),
		// .lo_o(ex_lo_o),
		// .whilo_o(ex_whilo_o),

		// .hilo_temp_o(hilo_temp_o),
		// .cnt_o(cnt_o),
		
		// .div_opdata1_o(div_opdata1),
		// .div_opdata2_o(div_opdata2),
		// .div_start_o(div_start),
		// .signed_div_o(signed_div),	
		
		// .aluop_o(ex_aluop_o),
		// .mem_addr_o(ex_mem_addr_o),
		// .reg2_o(ex_reg2_o),
		
		// .excepttype_o(ex_excepttype_o),
		// .is_in_delayslot_o(ex_is_in_delayslot_o),
		// .current_inst_address_o(ex_current_inst_address_o),
		
		// .stallreq(stallreq_from_ex)     	
		
	);

  //EX/MEM模块
  ex_mem ex_mem0(
		.clk(clk),
		.rst(rst),
		
		.stall(stall),
		// .flush(flush),
		
		//来自执行阶段EX模块的信息	
		.ex_pc(bbb_ex_pc_o),
		.ex_wd(ex_wd_o),
		.ex_wreg(ex_wreg_o),
		.ex_wdata(ex_wdata_o),
		// .ex_hi(ex_hi_o),
		// .ex_lo(ex_lo_o),
		// .ex_whilo(ex_whilo_o),
		
		.ex_aluop(mem_op),
		.ex_mem_addr(mem_addr_o),
		.ex_mem_data(mem_data_o),			
		
		.is_base_ram(is_base_ram),
		.is_ext_ram(is_ext_ram),
		
		.ex_base_ram(ex_base_ram),
		.ex_ext_ram(ex_ext_ram),
		// .ex_cp0_reg_we(ex_cp0_reg_we_o),
		// .ex_cp0_reg_write_addr(ex_cp0_reg_write_addr_o),
		// .ex_cp0_reg_data(ex_cp0_reg_data_o),
		
		// .ex_excepttype(ex_excepttype_o),
		// .ex_is_in_delayslot(ex_is_in_delayslot_o),
		// .ex_current_inst_address(ex_current_inst_address_o),
		
		// .hilo_i(hilo_temp_o),
		// .cnt_i(cnt_o),	
		
		// .ex_mem_op(mem_op),
		// .ex_mem_addr(mem_addr_o),
		// .ex_mem_data(mem_data_o),
		
		// .mem_pc(ex_mem_pc_o),
		.mem_aluop(mem_mem_op),
		.mem_mem_addr(mem_mem_addr_o),
		.mem_mem_data(mem_mem_data_o),
		
		//送到访存阶段MEM模块的信息
		.mem_wd(mem_wd_i),
		.mem_wreg(mem_wreg_i),
		.mem_wdata(mem_wdata_i)
		// .mem_hi(mem_hi_i),
		// .mem_lo(mem_lo_i),
		// .mem_whilo(mem_whilo_i),
		
		// .mem_cp0_reg_we(mem_cp0_reg_we_i),
		// .mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_i),
		// .mem_cp0_reg_data(mem_cp0_reg_data_i),
		
		// .mem_aluop(mem_aluop_i),
		// .mem_mem_addr(mem_mem_addr_i),
		// .mem_reg2(mem_reg2_i),
		
		// .mem_excepttype(mem_excepttype_i),
		// .mem_is_in_delayslot(mem_is_in_delayslot_i),
		// .mem_current_inst_address(mem_current_inst_address_i),
		
		// .hilo_o(hilo_temp_i),
		// .cnt_o(cnt_i)		
		// .last_store_data(last_store_data),
		// .last_store_addr(last_store_addr)
	);
	
  //MEM模块例化
	mem mem0(
		.clk(clk),
		.rst(rst),
	
		//来自EX/MEM模块的信息	
//		.mem_pc(ex_mem_pc_o),
		.wd_i(mem_wd_i),
		.wreg_i(mem_wreg_i),
		.wdata_i(mem_wdata_i),
		// .hi_i(mem_hi_i),
		// .lo_i(mem_lo_i),
		// .whilo_i(mem_whilo_i),
		
		.is_base_ram(is_base_ram),
		.is_ext_ram(is_ext_ram),
		// .aluop_i(mem_aluop_i),
		// .mem_addr_i(mem_mem_addr_i),
		// .reg2_i(mem_reg2_i),
		
		//来自memory的信息
		.mem_op(mem_mem_op),
		.mem_addr_i(mem_mem_addr_o),
		.mem_data_i(mem_mem_data_o),
		
		.mulans(mulans),
		// .LLbit_i(LLbit_o),

		// .wb_LLbit_we_i(wb_LLbit_we_i),
		// .wb_LLbit_value_i(wb_LLbit_value_i),
		
		// .cp0_reg_we_i(mem_cp0_reg_we_i),
		// .cp0_reg_write_addr_i(mem_cp0_reg_write_addr_i),
		// .cp0_reg_data_i(mem_cp0_reg_data_i),
		
		// .excepttype_i(mem_excepttype_i),
		// .is_in_delayslot_i(mem_is_in_delayslot_i),
		// .current_inst_address_i(mem_current_inst_address_i),	
		
		// .cp0_status_i(cp0_status),
		// .cp0_cause_i(cp0_cause),
		// .cp0_epc_i(cp0_epc),
		
		// //回写阶段的指令是否要写CP0，用来检测数据相关
		// .wb_cp0_reg_we(wb_cp0_reg_we_i),
		// .wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
		// .wb_cp0_reg_data(wb_cp0_reg_data_i),	  

		// .LLbit_we_o(mem_LLbit_we_o),
		// .LLbit_value_o(mem_LLbit_value_o),
		
		// .cp0_reg_we_o(mem_cp0_reg_we_o),
		// .cp0_reg_write_addr_o(mem_cp0_reg_write_addr_o),
		// .cp0_reg_data_o(mem_cp0_reg_data_o),
		
		//送到MEM/WB模块的信息
		.wd_o(mem_wd_o),
		.wreg_o(mem_wreg_o),
		.wdata_o(mem_wdata_o),
		// .hi_o(mem_hi_o),
		// .lo_o(mem_lo_o),
		// .whilo_o(mem_whilo_o),
		
		//送到memory的信息
		.mem_addr_o(ram_addr_o),
		.mem_we_o(ram_we_o),
		.mem_sel_o(ram_sel_o),
		.mem_data_o(ram_data_o),
		.mem_ce_o(ram_ce_o),
		.op_for_baseram(op_for_baseram),
		
		.ram_data_i(ram_data_i),
		.stallreq(stallreq_from_baseram)

		// .excepttype_o(mem_excepttype_o),
		// .cp0_epc_o(latest_epc),
		// .is_in_delayslot_o(mem_is_in_delayslot_o),
		// .current_inst_address_o(mem_current_inst_address_o)	
		  
	);

  //MEM/WB模块
	mem_wb mem_wb0(
		.clk(clk),
		.rst(rst),

		.stall(stall),
		// .flush(flush),
		
		//来自访存阶段MEM模块的信息	
		.mem_wd(mem_wd_o),
		.mem_wreg(mem_wreg_o),
		.mem_wdata(mem_wdata_o),
		// .mem_hi(mem_hi_o),
		// .mem_lo(mem_lo_o),
		// .mem_whilo(mem_whilo_o),	
	
        // .mem_LLbit_we(mem_LLbit_we_o),
		// .mem_LLbit_value(mem_LLbit_value_o),
		
		// .mem_cp0_reg_we(mem_cp0_reg_we_o),
		// .mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_o),
		// .mem_cp0_reg_data(mem_cp0_reg_data_o),
		
		//送到回写阶段的信息
		.wb_wd(wb_wd_i),
		.wb_wreg(wb_wreg_i),
		.wb_wdata(wb_wdata_i)
		// .wb_hi(wb_hi_i),
		// .wb_lo(wb_lo_i),
		// .wb_whilo(wb_whilo_i)
        // .wb_LLbit_we(wb_LLbit_we_i),
		// .wb_LLbit_value(wb_LLbit_value_i),

		// .wb_cp0_reg_we(wb_cp0_reg_we_i),
		// .wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
		// .wb_cp0_reg_data(wb_cp0_reg_data_i)	
									       	
	);

	// hilo_reg hilo_reg0(
		// .clk(clk),
		// .rst(rst),
	
		// //写端口
		// .we(wb_whilo_i),
		// .hi_i(wb_hi_i),
		// .lo_i(wb_lo_i),
	
		// //读端口1
		// .hi_o(hi),
		// .lo_o(lo)	
	// );

	ctrl ctrl0(
		.rst(rst),
	
		// .excepttype_i(mem_excepttype_o),
		// .cp0_epc_i(latest_epc),
		
		.stallreq_from_id(stallreq_from_id),
	
  	//来自执行阶段的暂停请求
		.stallreq_from_baseram(stallreq_from_baseram),
		
		// .new_pc(new_pc),
		// .flush(flush),
		
		.stall(stall)       	
	);
	
	// div div0(
		// .clk(clk),
		// .rst(rst),
	
		// .signed_div_i(signed_div),
		// .opdata1_i(div_opdata1),
		// .opdata2_i(div_opdata2),
		// .start_i(div_start),
		// // .annul_i(flush),
	
		// .result_o(div_result),
		// .ready_o(div_ready)
	// );

    	// LLbit_reg LLbit_reg0(
		// .clk(clk),
		// .rst(rst),
	  // .flush(flush),
	  
		// //写端口
		// .LLbit_i(wb_LLbit_value_i),
		// .we(wb_LLbit_we_i),
	
		// //读端口1
		// .LLbit_o(LLbit_o)
	
	// );	
	
		// cp0_reg cp0_reg0(
		// .clk(clk),
		// .rst(rst),
		
		// .we_i(wb_cp0_reg_we_i),
		// .waddr_i(wb_cp0_reg_write_addr_i),
		// .raddr_i(cp0_raddr_i),
		// .data_i(wb_cp0_reg_data_i),
		
		// .excepttype_i(mem_excepttype_o),
		// .int_i(int_i),
		// .current_inst_addr_i(mem_current_inst_address_o),
		// .is_in_delayslot_i(mem_is_in_delayslot_o),
		
		// .data_o(cp0_data_o),
		// .count_o(cp0_count),
		// .compare_o(cp0_compare),
		// .status_o(cp0_status),
		// .cause_o(cp0_cause),
		// .epc_o(cp0_epc),
		// .config_o(cp0_config),
		// .prid_o(cp0_prid),
		
		// .timer_int_o(timer_int_o)  			
	// );
endmodule