`include "defines.v"

module bbb_ex(
	
	input wire clk,
	input wire rst,
	
	// input wire[5:0]							 stall,
	// input wire                   flush,
	input  wire stall,
	//id 传输的信息
	input wire[`AluOpBus] bbb_aluop,
	input wire[`AluSelBus] bbb_alusel,
	input wire[`RegBus] bbb_reg1,
	input wire[`RegBus] bbb_reg2,
	input wire[`RegAddrBus] bbb_wd,
	input wire  bbb_wreg,
	input wire[`RegBus]           bbb_link_address,
	input wire                    bbb_is_in_delayslot,
	// input wire                    next_inst_in_delayslot_i,		
	input wire[`RegBus]           bbb_inst,	
	input    wire[31:0]  bbb_pc_i,
	//传输到EX的信息
	output reg[`AluOpBus] ex_aluop,
	output reg[`AluSelBus] ex_alusel,
	output reg[`RegBus] ex_reg1,
	output reg[`RegBus] ex_reg2,
	output reg[`RegAddrBus] ex_wd,
	output reg  ex_wreg,
	output reg[`RegBus]           ex_link_address,
	output   reg [31:0]  ex_pc,
	output reg                    ex_is_in_delayslot,
	output reg                    is_in_delayslot_o,
	output reg[`RegBus]           ex_inst
	// output reg[31:0]              ex_excepttype,
	// output reg[`RegBus]          ex_current_inst_address
	
);

	always @(posedge clk)begin
		if (rst == `RstEnable)begin
			ex_aluop <= `EXE_NOP_OP;
			ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= `NOPRegAddr;
			ex_wreg <= `WriteDisable;
			ex_link_address <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;
			is_in_delayslot_o <= `NotInDelaySlot;	
			ex_inst <= `ZeroWord;	
			ex_pc <= `ZeroWord;
		// end else if(stall == `Stop ) begin//译码停执行不停stall[2] == `Stop && stall[3] == `NoStop) && !(will_be_baseram && mem_op_check)
			// ex_aluop <= `EXE_NOP_OP;
			// ex_alusel <= `EXE_RES_NOP;
			// ex_reg1 <= `ZeroWord;
			// ex_reg2 <= `ZeroWord;
			// ex_wd <= `NOPRegAddr;
			// ex_wreg <= `WriteDisable;
			// ex_link_address <= `ZeroWord;
			// ex_pc <= `ZeroWord;
			// ex_is_in_delayslot <= `NotInDelaySlot;	
			// ex_inst <= `ZeroWord;				
		end else begin		//stall[2] == `NoStop
			ex_aluop <= bbb_aluop;
			ex_alusel <= bbb_alusel;
			ex_reg1 <= bbb_reg1;
			ex_reg2 <= bbb_reg2;
			ex_wd <= bbb_wd;
			ex_wreg <= bbb_wreg;	
			ex_link_address <= bbb_link_address;
			ex_is_in_delayslot <= bbb_is_in_delayslot;
			ex_inst <= bbb_inst;	
			ex_pc <= bbb_pc_i;
		end
	end

endmodule