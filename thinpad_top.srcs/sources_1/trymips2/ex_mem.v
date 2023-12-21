`include "defines.v"

module ex_mem(
	
	input wire clk,
	input wire rst,
	input wire stall,	
	// input wire[5:0]							 stall,	
	// input wire                   flush,
	//ex传
	input    wire[31:0]   ex_pc,
	input wire[`RegAddrBus] ex_wd,
	input wire ex_wreg,
	input wire[`RegBus] ex_wdata,
	// input wire[`RegBus]           ex_hi,
	// input wire[`RegBus]           ex_lo,
	// input wire                    ex_whilo, 
	
	// input    wire[3:0]    ex_aluop,
    // input    wire[31:0]   ex_mem_addr,
    // input    wire[31:0]   ex_mem_data,
	//送到mem阶段的信息
    // output   reg [31:0]   mem_pc,
    // output   reg [3:0]    mem_mem_op,
    // output   reg [31:0]   mem_mem_addr,
    // output   reg [31:0]   mem_mem_data,
	// //为实现加载、访存指令而添加
	input wire[`AluOpBus]        ex_aluop,
	input wire[`RegBus]          ex_mem_addr,
	input wire[`RegBus]          ex_mem_data,
	
	// input wire[`DoubleRegBus]     hilo_i,	
	// input wire[1:0]               cnt_i,	

	// input wire                   ex_cp0_reg_we,
	// input wire[4:0]              ex_cp0_reg_write_addr,
	// input wire[`RegBus]          ex_cp0_reg_data,

	// input wire[31:0]             ex_excepttype,
	// input wire                   ex_is_in_delayslot,
	// input wire[`RegBus]          ex_current_inst_address,	
	
	//传往mem的信号
	output reg[`RegAddrBus] mem_wd,
	output reg mem_wreg,
	output reg[`RegBus] mem_wdata,
	// output reg[`RegBus]          mem_hi,
	// output reg[`RegBus]          mem_lo,
	// output reg                   mem_whilo,

	//为实现加载、访存指令而添加
	output reg[`AluOpBus]        mem_aluop,
	output reg[`RegBus]          mem_mem_addr,
	output reg[`RegBus]          mem_mem_data
	
	// output reg                   mem_cp0_reg_we,
	// output reg[4:0]              mem_cp0_reg_write_addr,
	// output reg[`RegBus]          mem_cp0_reg_data,
	
	// output reg[31:0]            mem_excepttype,
	// output reg                  mem_is_in_delayslot,
	// output reg[`RegBus]         mem_current_inst_address,
	// output  reg [31:0]   last_store_data,
    // output  reg [31:0]   last_store_addr
	
	// output reg[`DoubleRegBus]    hilo_o,
	// output reg[1:0]              cnt_o	
);

	always @ (posedge clk )begin
		if(rst == `RstEnable) begin
			// mem_pc <= `ZeroWord;
            // mem_mem_op   <= `MEM_NOP_OP;
            // mem_mem_addr <= `ZeroWord;
            // mem_mem_data <= `ZeroWord;
			
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
			mem_wdata <= `ZeroWord;
			
			// last_store_addr <= `ZeroWord;
            // last_store_data <= `ZeroWord;
			// mem_hi <= `ZeroWord;
			// mem_lo <= `ZeroWord;
			// mem_whilo <= `WriteDisable;
			// hilo_o <= {`ZeroWord, `ZeroWord};
			// cnt_o <= 2'b00;		
			mem_aluop <= `EXE_NOP_OP;
			mem_mem_addr <= `ZeroWord;
			mem_mem_data <= `ZeroWord;		
			// mem_cp0_reg_we <= `WriteDisable;
			// mem_cp0_reg_write_addr <= 5'b00000;
			// mem_cp0_reg_data <= `ZeroWord;	
			// mem_excepttype <= `ZeroWord;
			// mem_is_in_delayslot <= `NotInDelaySlot;
			// mem_current_inst_address <= `ZeroWord;
		// end else if(flush == 1'b1 ) begin
			// mem_wd <= `NOPRegAddr;
			// mem_wreg <= `WriteDisable;
			// mem_wdata <= `ZeroWord;
			// mem_hi <= `ZeroWord;
			// mem_lo <= `ZeroWord;
			// mem_whilo <= `WriteDisable;
			// mem_aluop <= `EXE_NOP_OP;
			// mem_mem_addr <= `ZeroWord;
			// mem_mem_data <= `ZeroWord;
			// mem_cp0_reg_we <= `WriteDisable;
			// mem_cp0_reg_write_addr <= 5'b00000;
			// mem_cp0_reg_data <= `ZeroWord;
			// mem_excepttype <= `ZeroWord;
			// mem_is_in_delayslot <= `NotInDelaySlot;
			// mem_current_inst_address <= `ZeroWord;
			// hilo_o <= {`ZeroWord, `ZeroWord};
			// cnt_o <= 2'b00;				
		// end else if(stall[3] == `Stop && stall[4] == `NoStop) begin//执行停访存不停
			
			// mem_wd <= `NOPRegAddr;
			// mem_wreg <= `WriteDisable;
			// mem_wdata <= `ZeroWord;
			// mem_hi <= `ZeroWord;
			// mem_lo <= `ZeroWord;
			// mem_whilo <= `WriteDisable;
			// hilo_o <= hilo_i;
			// cnt_o <= cnt_i;	
			// mem_aluop <= `EXE_NOP_OP;
			// mem_mem_addr <= `ZeroWord;
			// mem_mem_data <= `ZeroWord;	
			// mem_cp0_reg_we <= `WriteDisable;
			// mem_cp0_reg_write_addr <= 5'b00000;
			// mem_cp0_reg_data <= `ZeroWord;
			// mem_excepttype <= `ZeroWord;
			// mem_is_in_delayslot <= `NotInDelaySlot;
			// mem_current_inst_address <= `ZeroWord;			
		end else  begin//执行不停  if(stall[3] == `NoStop)
			// mem_pc <= ex_pc;
            // mem_mem_op <= ex_aluop;
            // mem_mem_addr <= ex_mem_addr;
            // mem_mem_data <= ex_mem_data;	
			
			mem_wd <= ex_wd;
			mem_wreg <= ex_wreg;
			mem_wdata <= ex_wdata;	
			// mem_hi <= ex_hi;
			// mem_lo <= ex_lo;
			// mem_whilo <= ex_whilo;	
			// hilo_o <= {`ZeroWord, `ZeroWord};
			// cnt_o <= 2'b00;	
			mem_aluop <= ex_aluop;
			mem_mem_addr <= ex_mem_addr;
			mem_mem_data <= ex_mem_data;
			// mem_cp0_reg_we <= ex_cp0_reg_we;
			// mem_cp0_reg_write_addr <= ex_cp0_reg_write_addr;
			// mem_cp0_reg_data <= ex_cp0_reg_data;
			// mem_excepttype <= ex_excepttype;
			// mem_is_in_delayslot <= ex_is_in_delayslot;
			// mem_current_inst_address <= ex_current_inst_address;	
		// end else begin
			// hilo_o <= hilo_i;
			// cnt_o <= cnt_i;		
			 // case(ex_aluop)
                // `MEM_SB_OP: begin
                    // last_store_addr <= ex_mem_addr;
                    // case(ex_mem_addr[1:0])
                    // 2'b00: begin
                        // last_store_data <= {24'h000000,ex_mem_data[7:0]};
                    // end 
                    // 2'b01: begin
                        // last_store_data <= {16'h0000,ex_mem_data[7:0],8'h00};
                    // end
                    // 2'b10: begin
                        // last_store_data <= {8'h00,ex_mem_data[7:0],16'h0000};
                    // end
                    // 2'b11: begin
                        // last_store_data <= {ex_mem_data[7:0],12'h000000};
                    // end
                    // default : begin
                        // last_store_data <= last_store_data;
                    // end
                // endcase
                // end
                // `MEM_SW_OP: begin
                    // last_store_addr <= ex_mem_addr;
                    // last_store_data <= ex_mem_data;
                // end
                // default: begin
                    // last_store_addr <= last_store_addr;
                    // last_store_data <= last_store_data;
                // end
            // endcase
		end
	end
	
endmodule