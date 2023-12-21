
/*
    | 虚地�?区间            | 说明           |
    | 0x80000000-0x800FFFFF | 监控程序代码   |
    | 0x80100000-0x803FFFFF | 用户代码空间   |
    | 0x80400000-0x807EFFFF | 用户数据空间   |
    | 0x807F0000-0x807FFFFF | 监控程序数据   |
    | 0xBFD003F8-0xBFD003FD | 串口数据及状�? |

    | 地址       | �?    | 说明                                               |
    | 0xBFD003F8 | [7:0] | 串口数据，读、写地址分别表示串口接收、发送一个字�? |
    | 0xBFD003FC | [0]   | 只读，为1时表示串口空闲，可发送数�?                |
    | 0xBFD003FC | [1]   | 只读，为1时表示串口收到数�?                        |
*/

`include "defines.v"

`define SerialState 32'hBFD003FC    //串口状�?�地�?
`define SerialData  32'hBFD003F8    //串口数据地址
module sram_ctrl_double_try (
    input wire clk,
    input wire rst,

    //if阶段输入的信息和获得的指�?
    input    wire[31:0]  rom_addr_i,        //读取指令的地�?
    input    wire        rom_ce_i,          //指令存储器使能信�?
    output   reg [31:0]  inst_o,            //获取到的指令
	
	input wire pre_stall,

    //mem阶段传�?�的信息和取得的数据
    (*mark_debug = "true"*)output   reg[31:0]   ram_data_o,        //读取的数�?
    (*mark_debug = "true"*)input    wire[31:0]  mem_addr_i,        //读（写）地址
    (*mark_debug = "true"*)input    wire[31:0]  mem_data_i,        //写入的数�?
    (*mark_debug = "true"*)input    wire        mem_we_n,          //写使能，低有�?
    (*mark_debug = "true"*)input    wire[3:0]   mem_sel_n,         //字节选择信号
    (*mark_debug = "true"*)input    wire        mem_ce_i,          //片�?�信�?

    //BaseRAM信号
    (*mark_debug = "true"*)inout    wire[31:0]  base_ram_data,     //BaseRAM数据
    (*mark_debug = "true"*)output   reg [19:0]  base_ram_addr,     //BaseRAM地址
    (*mark_debug = "true"*)output   reg [3:0]   base_ram_be_n,     //BaseRAM字节使能，低有效�?
    (*mark_debug = "true"*)output   reg         base_ram_ce_n,     //BaseRAM片�?�，低有�?
    (*mark_debug = "true"*)output   reg         base_ram_oe_n,     //BaseRAM读使能，低有�?
    (*mark_debug = "true"*)output   reg         base_ram_we_n,     //BaseRAM写使能，低有�?

    //ExtRAM信号
    (*mark_debug = "true"*)inout    wire[31:0]  ext_ram_data,      //ExtRAM数据
    (*mark_debug = "true"*)output   reg [19:0]  ext_ram_addr,      //ExtRAM地址
    (*mark_debug = "true"*)output   reg [3:0]   ext_ram_be_n,      //ExtRAM字节使能，低有效�?
    (*mark_debug = "true"*)output   reg         ext_ram_ce_n,      //ExtRAM片�?�，低有�?
    (*mark_debug = "true"*)output   reg         ext_ram_oe_n,      //ExtRAM读使能，低有�?
    (*mark_debug = "true"*)output   reg         ext_ram_we_n,      //ExtRAM写使能，低有�?
	input wire is_base_ram,
	input wire is_ext_ram,
	input wire will_be_baseram,
	output reg baseram_finish,
	input  wire stallreq,
	input  wire this_inst_is_load,
	input  wire [31:0] load_addr,
	input  wire load_we,
	input  wire [31:0]load_data,
	input  wire load_ce,
	input  wire [3:0] load_sel,
	output wire load_baseram,
	input wire branch_flag_i,
	input wire[`RegBus] branch_target_address_i,
	input wire store_baseram,
    //直连串口信号
    (*mark_debug = "true"*)output   wire        txd,                //直连串口发�?�端
    (*mark_debug = "true"*)input    wire        rxd                 //直连串口接收�?

);
// //直连串口接收发�?�演示，从直连串口收到的数据再发送出�?
(*mark_debug = "true"*)wire [7:0] ext_uart_rx;//接收的数�?
(*mark_debug = "true"*)reg  [7:0] ext_uart_buffer;//缓冲�?
(*mark_debug = "true"*)wire  [7:0] ext_uart_tx;//发�?�的数据
					   wire [7:0] trance_tx;
(*mark_debug = "true"*)wire ext_uart_ready;//数据接收标志（高有效�?
(*mark_debug = "true"*)reg ext_uart_clear_notyet;//高有效清�?
(*mark_debug = "true"*)reg ext_uart_clear;//高有效清�?
(*mark_debug = "true"*)wire ext_uart_busy;//高忙
(*mark_debug = "true"*)reg ext_uart_start;//发�?�标志，高有�?
(*mark_debug = "true"*)reg ext_uart_avai;//缓冲区可用信号，高有�?
(*mark_debug = "true"*)	wire read_full;
(*mark_debug = "true"*)	wire read_clear;
(*mark_debug = "true"*)	wire read_rd_en;
(*mark_debug = "true"*)	wire [7:0]read_dout;
(*mark_debug = "true"*)	wire read_empty;
(*mark_debug = "true"*)	reg [7:0]trance_din;
(*mark_debug = "true"*)	wire trance_start;//不忙不空
(*mark_debug = "true"*)	wire trance_wr_en;
(*mark_debug = "true"*)	wire trance_rd_en; 
(*mark_debug = "true"*)	wire trance_empty;
(*mark_debug = "true"*)	wire [7:0]trance_data;
(*mark_debug = "true"*)	wire trance_full;
(*mark_debug = "true"*)	wire read_wr_en;
	reg [2:0] cnt;//时钟计数
	reg [1:0]state;
	reg [1:0]next_state;   
	reg [31:0] rom_addr_clk;        //读取指令的地�?
    reg        rom_ce_clk;
	reg load_baseram_delay;
	reg load_extram_delay;
	reg load_extram_delay_use;
	reg load_baseram_delay_use;
	reg [31:0]sbaseram_buffer;
	reg [3:0] mem_sel_n_delay;
	wire load_extram;
	//内存映射
wire is_SerialState = (mem_addr_i ==  `SerialState); 
wire is_SerialData  = (mem_addr_i == `SerialData);
// wire is_SerialState = (load_addr ==  `SerialState); 
// wire is_SerialData  = (load_addr == `SerialData);
assign load_baseram    = (load_addr >= 32'h80000000) 
                    && (load_addr < 32'h80400000);
assign load_extram    = (load_addr >= 32'h80400000) 
                    && (load_addr < 32'h80800000);
// wire is_ext_ram     = (mem_addr_i >= 32'h80400000)
                    // && (mem_addr_i < 32'h80800000);
		reg is_base_ram_delay;
		reg is_ext_ram_delay;
		reg is_base_ram_delay2;
	always @(posedge clk or negedge rst)begin
		if(rst == `RstEnable)begin
			is_base_ram_delay <= 1'b0;
			is_ext_ram_delay <= 1'b0;
			mem_sel_n_delay <= 4'b0000;
		end else if(is_base_ram)begin
			is_base_ram_delay <= 1'b1;
			is_ext_ram_delay <= 1'b0;
			mem_sel_n_delay <= mem_sel_n;
		end else if(is_ext_ram)begin
			is_base_ram_delay <= 1'b0;
			is_ext_ram_delay <= 1'b1;
			mem_sel_n_delay <= mem_sel_n;
		end else begin 
			is_base_ram_delay <= 1'b0;
			is_ext_ram_delay <= 1'b0;
			mem_sel_n_delay <= 4'b0000;
		end
	end
	
	always @(posedge clk or negedge rst)begin
		if(rst == `RstEnable)begin
			is_base_ram_delay2 <= 1'b0;
		end else if(is_base_ram_delay)begin
			is_base_ram_delay2 <= 1'b1;
		// end else if(cnt == 3'd1)begin
			// is_base_ram_delay <= is_base_ram_delay;
		end else begin 
			is_base_ram_delay2 <= 1'b0;
		end
	end
	
		// //延时计数�?
	// always@(posedge clk or negedge rst)begin//两个时钟周期以保证读取数据准�?
		// if(rst==`RstEnable)begin
			// cnt<=3'b000;
		// end
		// else if(cnt==3'd1 || load_baseram ||baseram_finish)begin//每次对sram执行操作都先重置计数（实际每次计数是0->0->1->0�?
			// cnt<=3'b000;
		// else begin
			// cnt<=cnt+1'b1;
		// end
	// end

	// //延时计数�?
	// always@(posedge clk or negedge rst)begin//两个时钟周期以保证读取数据准�?
		// if(rst==`RstEnable)begin
			// cnt<=3'b000;
		// end
		// else if(cnt==3'd1 || load_baseram ||baseram_finish)begin//每次对sram执行操作都先重置计数（实际每次计数是0->0->1->0�?
			// cnt<=3'b000;
		// else begin
			// cnt<=cnt+1'b1;
		// end
	// end

	always @(posedge clk ) begin //状�?�机状�?�转�?
        if(rst==`RstEnable) begin 
            state <= 2'b00;//初始//初始
			load_baseram_delay <= 1'b0;
			load_extram_delay <= 1'b0;
			load_baseram_delay_use <= 1'b0;
			load_extram_delay_use <= 1'b0;
			sbaseram_buffer <= `ZeroWord;
        end else begin 
            state<=next_state;
			load_baseram_delay <= load_baseram;
			load_extram_delay <= load_extram;
			load_extram_delay_use <= load_extram_delay;
			load_baseram_delay_use <= load_baseram_delay;
			sbaseram_buffer <= mem_data_i;
        end 
    end
	
	always @ (posedge clk) begin 
        if(rst == `RstEnable) begin 
                next_state<=2'b00;//初始
        end else begin 
                case(next_state)
                2'b00: begin //初始
                    if(load_we==1'b0 && load_ce && load_baseram) begin//sram写入
                         next_state<=2'b10;//
						 baseram_finish <= 1'b1;
                    end
                    else if(load_baseram)begin 
                        next_state<=2'b01;//不写即读
						baseram_finish <= 1'b1;
                    end else begin
						next_state<=2'b00;//不写即读
						baseram_finish <= 1'b0;
					end
                end
				2'b01: begin //
                    // if(cnt==3'd0) begin 
                        // next_state<=2'b00;//初始
						// baseram_finish <= 1'b1;
                    // end
                    // else begin 
                        next_state<=2'b11;//
						baseram_finish <= 1'b0;
                end
                2'b10:begin //�?
                    // if(cnt==3'd0) begin 
                        // next_state<=2'b00;//初始
						// baseram_finish <= 1'b1;
                    // end
                    // else begin 
                        next_state<=2'b11;//
						baseram_finish <= 1'b0;
                    // end
                end
				2'b11:begin //特殊
                        next_state<=2'b00;//初始
						baseram_finish <= 1'b0;
                end
                default: begin
						next_state<=2'b00;//初始
						baseram_finish <= 1'b0;
				end
            endcase
			
            end
            
            
    end

//assign number = ext_uart_buffer;


(*mark_debug = "true"*)wire[31:0] base_ram_o;      //baseram输出数据
(*mark_debug = "true"*)wire[31:0] ext_ram_o;       //extram输出数据

async_receiver #(.ClkFrequency(60000000),.Baud(9600)) //接收模块�?9600无检验位
    ext_uart_r(
        .clk(clk),                       //外部时钟信号
        .RxD(rxd),                           //外部串行信号输入
        .RxD_data_ready(ext_uart_ready),  //数据接收到标�?>out
        .RxD_clear(ext_uart_clear),       //清除接收标志
        .RxD_data(ext_uart_rx)             //接收到的�?字节数据>out
    );
	
async_transmitter #(.ClkFrequency(60000000),.Baud(9600)) //发�?�模块，9600无检验位
    ext_uart_t(
        .clk(clk),                  //外部时钟信号
        .TxD(txd),                      //串行信号输出	>out
        .TxD_busy(ext_uart_busy),       //发�?�器忙状态指�? >out
        .TxD_start(trance_start),    //�?始发送信�?
        .TxD_data(ext_uart_tx)        //待发送的数据
    );
	
	
	assign read_wr_en = ext_uart_ready;//清空即写�?
    //assign read_din = ext_uart_rx;//接收端的数据
	
	// assign read_rd_en = ((mem_addr_i == `SerialData)&&(mem_we_n == `WriteDisable_low)) || ((load_addr == `SerialData)&&(load_we == `WriteDisable_low));
	assign read_rd_en = (mem_addr_i == `SerialData)&&(mem_we_n == `WriteDisable_low);
    // assign read_rd_en = (load_addr == `SerialData)&&(load_we == `WriteDisable_low);
	
	// assign ext_uart_clear = 
fifo_generator_0 read (
  .clk(clk),      // input wire clk
  .rst(rst),      // input wire rst
  .din(ext_uart_rx),      // input wire [7 : 0] din
  .wr_en(read_wr_en),  // input wire wr_en
  .rd_en(read_rd_en),  // input wire rd_en
  .dout(read_dout),    // output wire [7 : 0] dout
  .full(read_full),    // output wire full
  .empty(read_empty)  // output wire empty
);


   	// assign	trance_din   = mem_data_i[7:0];
	assign 	trance_start = (~ext_uart_busy) &&(~trance_empty);//不忙不空
	
	// assign 	trance_wr_en = ((mem_addr_i == `SerialData)&&(mem_we_n == `WriteDisable_low)) || ((load_addr == `SerialData)&&(load_we == `WriteDisable_low));
	assign 	trance_wr_en = (mem_addr_i == `SerialData)&&(mem_we_n == `WriteEnable_low);
		// assign 	trance_wr_en = (load_addr == `SerialData)&&(load_we == `WriteEnable_low);
	assign  trance_rd_en = trance_start;
	assign	ext_uart_tx = trance_data;
	
fifo_generator_0 trance (
  .clk(clk),      // input wire clk
  .rst(rst),      // input wire rst
  .din(trance_din),      // input wire [7 : 0] din
  .wr_en(trance_wr_en),  // input wire wr_en
  .rd_en(trance_rd_en),  // input wire rd_en
  .dout(trance_data),    // output wire [7 : 0] dout
  .full(trance_full),    // output wire full
  .empty(trance_empty)  // output wire empty
);     

	always @(negedge clk) begin
		if(rst) begin
			ext_uart_clear <= 1'b1;
		end
		else begin
			if(ext_uart_ready && (~read_full) && mem_addr_i == `SerialData) begin
		// if(ext_uart_ready && (~read_full) && load_addr == `SerialData) begin
				ext_uart_clear <= 1'b1;
			end
			else begin
				ext_uart_clear <= 1'b0;
			end
		end
	end
(*mark_debug = "true"*)reg [31:0] serial_o;        //串口状�?��?�数据读�?

	always @(*) begin
		if(rst) begin
			// ext_uart_start <= 1'b0;
			serial_o <= `ZeroWord;
			trance_din <= 8'h00;
			
		end
		else begin
			if(is_SerialState) begin                                     // 获取串口状�??
				serial_o <= {{30{1'b0}}, {ext_uart_ready, !ext_uart_busy}};//发�?�状�?
				// ext_uart_start <= 1'b0;//不发�?
				trance_din <= 8'h00;
			end
			else if(is_SerialData) begin                   // 获取（或发�?�）串口数据
				if(mem_we_n) begin                    // 不写即读
				// if(mem_we_n) begin                    
					serial_o <= {24'h000000, ext_uart_rx};//拼上串口数据
					// ext_uart_start <= 1'b0;//不发�?
					trance_din <= 8'h00;
				end
				else begin            //�?
					trance_din <= mem_data_i[7:0];
					// trance_din <= load_data[7:0];
					// ext_uart_start <= 1'b1;//发�??
					serial_o <= `ZeroWord;
				end
			end
			else begin
				// ext_uart_start <= 1'b0;
				serial_o <= 32'h0000_0000;
				trance_din <= 8'h00;
			end
		end
	end

//处理BaseRam（指令存储器�?//load_data
// assign base_ram_data = is_base_ram_delay ? ((state == 2'b10) ? sbaseram_buffer : 32'hzzzzzzzz) : 32'hzzzzzzzz;
assign base_ram_data = is_base_ram ? ((mem_we_n == `WriteEnable_n) ? mem_data_i : 32'hzzzzzzzz) : 32'hzzzzzzzz;
assign base_ram_o = base_ram_data;      //读取到的BaseRam数据




//当mem阶段�?要向BaseRam的地�?写入或读取数据时，发生结构冒�?
always @(posedge clk or negedge rst) begin
    if(rst)begin
        base_ram_addr <= 20'h00000;
        base_ram_be_n <= 4'b0000;
        base_ram_ce_n <= 1'b0;
        base_ram_oe_n <= 1'b1;
        base_ram_we_n <= 1'b1;
    end else if((is_base_ram && stallreq == `NoStop)) begin           //baseram写，mem模块已叫暂停
        // base_ram_addr <= mem_addr_i[21:2];   //有对齐要求，低两位舍�?
        // base_ram_be_n <= mem_sel_n;
		base_ram_addr <= load_addr[21:2];   //有对齐要求，低两位舍�?
        base_ram_be_n <= load_sel;
        base_ram_ce_n <= 1'b0;
        base_ram_oe_n <= !load_we;
        base_ram_we_n <= load_we;
	end else if(load_baseram) begin //baseram写，mem模块已叫暂停 (this_inst_is_load && is_base_ram)&&
        base_ram_addr <= load_addr[21:2];   //有对齐要求，低两位舍�?
        base_ram_be_n <= load_sel;
        base_ram_ce_n <= 1'b0;
        base_ram_oe_n <= !load_we;
        base_ram_we_n <= load_we;
    end else if(stallreq || load_baseram_delay) begin        //不写即读 if(state == 2'b01 ||state == 2'b11)
		base_ram_addr <= base_ram_addr;   //有对齐要求，低两位舍�?
        base_ram_be_n <= base_ram_be_n;
        base_ram_ce_n <= 1'b0;
        base_ram_oe_n <= !load_we;
        base_ram_we_n <= load_we;
	end else if( branch_flag_i && !load_baseram_delay_use)begin 
		base_ram_addr <= branch_target_address_i[21:2];   //有对齐要求，低两位舍�?
        base_ram_be_n <= 4'b0000;
        base_ram_ce_n <= 1'b0;
        base_ram_oe_n <= 1'b0;
        base_ram_we_n <= 1'b1;
    end else begin
		base_ram_addr <= rom_addr_i[21:2];   //有对齐要求，低两位舍�?
        base_ram_be_n <= 4'b0000;
        base_ram_ce_n <= 1'b0;
        base_ram_oe_n <= 1'b0;
        base_ram_we_n <= 1'b1;
	end
end

always @(*) begin
    // inst_o = `ZeroWord;
    // if(is_base_ram ) begin           //baseram写，mem模块已叫暂停
        // inst_o = base_ram_o;
    // end
    // end else begin  
	if(rst == `NoStop)begin//不写即读 if(state == 2'b01 ||state == 2'b11)
        inst_o = base_ram_o;
    end
end


//处理ExtRam（数据存储器�?
assign ext_ram_data = is_ext_ram ? ((mem_we_n == `WriteEnable_n) ? mem_data_i : 32'hzzzzzzzz) : 32'hzzzzzzzz;
assign ext_ram_o = ext_ram_data;

// always @(*) begin
    // ext_ram_addr = 20'h00000;
    // ext_ram_be_n = 4'b0000;
    // ext_ram_ce_n = 1'b0;
    // ext_ram_oe_n = 1'b1;
    // ext_ram_we_n = 1'b1;
    // if(is_ext_ram) begin           //涉及到extRam的相关数据操�?
        // ext_ram_addr = mem_addr_i[21:2];    //有对齐要求，低两位舍�?
        // ext_ram_be_n = mem_sel_n;
        // ext_ram_ce_n = 1'b0;
        // ext_ram_oe_n = !mem_we_n;
        // ext_ram_we_n = mem_we_n;
    // end else begin
        // ext_ram_addr = 20'h00000;
        // ext_ram_be_n = 4'b0000;
        // ext_ram_ce_n = 1'b0;
        // ext_ram_oe_n = 1'b1;
        // ext_ram_we_n = 1'b1;
    // end
// end

always @(posedge clk or negedge rst) begin
    if(rst)begin
        ext_ram_addr <= 20'h00000;
        ext_ram_be_n <= 4'b0000;
        ext_ram_ce_n <= 1'b0;
        ext_ram_oe_n <= 1'b1;
        ext_ram_we_n <= 1'b1;
	end else if(load_extram_delay) begin        //不写即读 if(state == 2'b01 ||state == 2'b11)
		ext_ram_addr <= ext_ram_addr;   //有对齐要求，低两位舍�?
        ext_ram_be_n <= ext_ram_be_n;
        ext_ram_ce_n <= 1'b0;
        ext_ram_oe_n <= !load_we;
        ext_ram_we_n <= load_we;
    end else if((is_ext_ram && stallreq == `NoStop)) begin           //extram写，mem模块已叫暂停
        // ext_ram_addr <= mem_addr_i[21:2];   //有对齐要求，低两位舍�?
        // ext_ram_be_n <= mem_sel_n;
		ext_ram_addr <= load_addr[21:2];   //有对齐要求，低两位舍�?
        ext_ram_be_n <= load_sel;
        ext_ram_ce_n <= 1'b0;
        ext_ram_oe_n <= !load_we;
        ext_ram_we_n <= load_we;
	end else if(load_extram) begin //extram写，mem模块已叫暂停 (this_inst_is_load && is_ext_ram)&&
        ext_ram_addr <= load_addr[21:2];   //有对齐要求，低两位舍�?
        ext_ram_be_n <= load_sel;
        ext_ram_ce_n <= 1'b0;
        ext_ram_oe_n <= !load_we;
        ext_ram_we_n <= load_we;
    end else begin
        ext_ram_addr = 20'h00000;
        ext_ram_be_n = 4'b0000;
        ext_ram_ce_n = 1'b0;
        ext_ram_oe_n = 1'b1;
        ext_ram_we_n = 1'b1;
    end
end

//11011101100010100001
//0000 0000 0010 0001 0011 1101 0000 0101

//确认输出的数�?
always @(*) begin
    ram_data_o = `ZeroWord;
    if(is_SerialState || is_SerialData ) begin
        ram_data_o = serial_o;
    end else if (is_base_ram) begin//|| is_base_ram_delay ||is_base_ram_delay2
        case (mem_sel_n)
            4'b1110: begin
                ram_data_o = {{24{base_ram_o[7]}}, base_ram_o[7:0]};
            end
            4'b1101: begin
                ram_data_o = {{24{base_ram_o[15]}}, base_ram_o[15:8]};
            end
            4'b1011: begin
                ram_data_o = {{24{base_ram_o[23]}}, base_ram_o[23:16]};
            end
            4'b0111: begin
                ram_data_o = {{24{base_ram_o[31]}}, base_ram_o[31:24]};
            end
            4'b0000: begin
                ram_data_o = base_ram_o;
            end
            default: begin
                ram_data_o = base_ram_o;
            end
        endcase
   end else if (is_base_ram_delay ||is_base_ram_delay2) begin
        case (mem_sel_n_delay)
            4'b1110: begin
                ram_data_o = {{24{base_ram_o[7]}}, base_ram_o[7:0]};
            end
            4'b1101: begin
                ram_data_o = {{24{base_ram_o[15]}}, base_ram_o[15:8]};
            end
            4'b1011: begin
                ram_data_o = {{24{base_ram_o[23]}}, base_ram_o[23:16]};
            end
            4'b0111: begin
                ram_data_o = {{24{base_ram_o[31]}}, base_ram_o[31:24]};
            end
            4'b0000: begin
                ram_data_o = base_ram_o;
            end
            default: begin
                ram_data_o = base_ram_o;
            end
        endcase
    end else if (is_ext_ram) begin
        case (mem_sel_n)
            4'b1110: begin
                ram_data_o = {{24{ext_ram_o[7]}}, ext_ram_o[7:0]};
            end
            4'b1101: begin
                ram_data_o = {{24{ext_ram_o[15]}}, ext_ram_o[15:8]};
            end
            4'b1011: begin
                ram_data_o = {{24{ext_ram_o[23]}}, ext_ram_o[23:16]};
            end
            4'b0111: begin
                ram_data_o = {{24{ext_ram_o[31]}}, ext_ram_o[31:24]};
            end
            4'b0000: begin
                ram_data_o = ext_ram_o;
            end
            default: begin
                ram_data_o = ext_ram_o;
            end
        endcase
	end else if (is_ext_ram_delay) begin
        case (mem_sel_n_delay)
            4'b1110: begin
                ram_data_o = {{24{ext_ram_o[7]}}, ext_ram_o[7:0]};
            end
            4'b1101: begin
                ram_data_o = {{24{ext_ram_o[15]}}, ext_ram_o[15:8]};
            end
            4'b1011: begin
                ram_data_o = {{24{ext_ram_o[23]}}, ext_ram_o[23:16]};
            end
            4'b0111: begin
                ram_data_o = {{24{ext_ram_o[31]}}, ext_ram_o[31:24]};
            end
            4'b0000: begin
                ram_data_o = ext_ram_o;
            end
            default: begin
                ram_data_o = ext_ram_o;
            end
        endcase
    end else begin
        ram_data_o = `ZeroWord;
    end
end


endmodule //ram
