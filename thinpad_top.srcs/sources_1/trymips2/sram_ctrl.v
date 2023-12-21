
/*
    | 虚地址区间            | 说明           |
    | 0x80000000-0x800FFFFF | 监控程序代码   |
    | 0x80100000-0x803FFFFF | 用户代码空间   |
    | 0x80400000-0x807EFFFF | 用户数据空间   |
    | 0x807F0000-0x807FFFFF | 监控程序数据   |
    | 0xBFD003F8-0xBFD003FD | 串口数据及状态 |

    | 地址       | 位    | 说明                                               |
    | 0xBFD003F8 | [7:0] | 串口数据，读、写地址分别表示串口接收、发送一个字节 |
    | 0xBFD003FC | [0]   | 只读，为1时表示串口空闲，可发送数据                |
    | 0xBFD003FC | [1]   | 只读，为1时表示串口收到数据                        |
*/

`include "defines.v"

`define SerialState 32'hBFD003FC    //串口状态地址
`define SerialData  32'hBFD003F8    //串口数据地址
module sram_ctrl (
    input wire clk,
    input wire rst,

    //if阶段输入的信息和获得的指令
    input    wire[31:0]  rom_addr_i,        //读取指令的地址
    input    wire        rom_ce_i,          //指令存储器使能信号
    output   reg [31:0]  inst_o,            //获取到的指令

    //mem阶段传递的信息和取得的数据
    (*mark_debug = "true"*)output   reg[31:0]   ram_data_o,        //读取的数据
    (*mark_debug = "true"*)input    wire[31:0]  mem_addr_i,        //读（写）地址
    (*mark_debug = "true"*)input    wire[31:0]  mem_data_i,        //写入的数据
    (*mark_debug = "true"*)input    wire        mem_we_n,          //写使能，低有效
    (*mark_debug = "true"*)input    wire[3:0]   mem_sel_n,         //字节选择信号
    (*mark_debug = "true"*)input    wire        mem_ce_i,          //片选信号

    //BaseRAM信号
    (*mark_debug = "true"*)inout    wire[31:0]  base_ram_data,     //BaseRAM数据
    (*mark_debug = "true"*)output   reg [19:0]  base_ram_addr,     //BaseRAM地址
    (*mark_debug = "true"*)output   reg [3:0]   base_ram_be_n,     //BaseRAM字节使能，低有效。
    (*mark_debug = "true"*)output   reg         base_ram_ce_n,     //BaseRAM片选，低有效
    (*mark_debug = "true"*)output   reg         base_ram_oe_n,     //BaseRAM读使能，低有效
    (*mark_debug = "true"*)output   reg         base_ram_we_n,     //BaseRAM写使能，低有效

    //ExtRAM信号
    (*mark_debug = "true"*)inout    wire[31:0]  ext_ram_data,      //ExtRAM数据
    (*mark_debug = "true"*)output   reg [19:0]  ext_ram_addr,      //ExtRAM地址
    (*mark_debug = "true"*)output   reg [3:0]   ext_ram_be_n,      //ExtRAM字节使能，低有效。
    (*mark_debug = "true"*)output   reg         ext_ram_ce_n,      //ExtRAM片选，低有效
    (*mark_debug = "true"*)output   reg         ext_ram_oe_n,      //ExtRAM读使能，低有效
    (*mark_debug = "true"*)output   reg         ext_ram_we_n,      //ExtRAM写使能，低有效

    //直连串口信号
    (*mark_debug = "true"*)output   wire        txd,                //直连串口发送端
    (*mark_debug = "true"*)input    wire        rxd                 //直连串口接收端

);
// //直连串口接收发送演示，从直连串口收到的数据再发送出去
(*mark_debug = "true"*)wire [7:0] ext_uart_rx;//接收的数据
(*mark_debug = "true"*)reg  [7:0] ext_uart_buffer;//缓冲栈
(*mark_debug = "true"*)wire  [7:0] ext_uart_tx;//发送的数据
					   wire [7:0] trance_tx;
(*mark_debug = "true"*)wire ext_uart_ready;//数据接收标志（高有效）
(*mark_debug = "true"*)reg ext_uart_clear_notyet;//高有效清除
(*mark_debug = "true"*)reg ext_uart_clear;//高有效清除
(*mark_debug = "true"*)wire ext_uart_busy;//高忙
(*mark_debug = "true"*)reg ext_uart_start;//发送标志，高有效
(*mark_debug = "true"*)reg ext_uart_avai;//缓冲区可用信号，高有效
(*mark_debug = "true"*)    wire [7:0]ext_uart_tx;
(*mark_debug = "true"*)	wire read_full;
(*mark_debug = "true"*)	wire read_clear;
(*mark_debug = "true"*)	wire read_rd_en;
(*mark_debug = "true"*)	wire [7:0]read_dout;
(*mark_debug = "true"*)	wire read_empty;
(*mark_debug = "true"*) wire trance_start;
(*mark_debug = "true"*)	reg [7:0]trance_din;
(*mark_debug = "true"*)	wire trance_start;//不忙不空
(*mark_debug = "true"*)	wire trance_wr_en;
(*mark_debug = "true"*)	wire trance_rd_en; 
(*mark_debug = "true"*)	wire trance_empty;
(*mark_debug = "true"*)	wire [7:0]trance_data;
(*mark_debug = "true"*)	wire trance_full;
(*mark_debug = "true"*)	wire read_wr_en;


//assign number = ext_uart_buffer;

//内存映射
wire is_SerialState = (mem_addr_i ==  `SerialState); 
wire is_SerialData  = (mem_addr_i == `SerialData);
wire is_base_ram    = (mem_addr_i >= 32'h80000000) 
                    && (mem_addr_i < 32'h80400000);
wire is_ext_ram     = (mem_addr_i >= 32'h80400000)
                    && (mem_addr_i < 32'h80800000);


(*mark_debug = "true"*)wire[31:0] base_ram_o;      //baseram输出数据
(*mark_debug = "true"*)wire[31:0] ext_ram_o;       //extram输出数据

async_receiver #(.ClkFrequency(50000000),.Baud(9600)) //接收模块，9600无检验位
    ext_uart_r(
        .clk(clk),                       //外部时钟信号
        .RxD(rxd),                           //外部串行信号输入
        .RxD_data_ready(ext_uart_ready),  //数据接收到标志>out
        .RxD_clear(ext_uart_clear),       //清除接收标志
        .RxD_data(ext_uart_rx)             //接收到的一字节数据>out
    );
	
async_transmitter #(.ClkFrequency(50000000),.Baud(9600)) //发送模块，9600无检验位
    ext_uart_t(
        .clk(clk),                  //外部时钟信号
        .TxD(txd),                      //串行信号输出	>out
        .TxD_busy(ext_uart_busy),       //发送器忙状态指示 >out
        .TxD_start(trance_start),    //开始发送信号
        .TxD_data(ext_uart_tx)        //待发送的数据
    );
	
	
	assign read_wr_en = ext_uart_ready;//清空即写入
    //assign read_din = ext_uart_rx;//接收端的数据
    assign read_rd_en = (mem_addr_i == `SerialData)&&(mem_we_n == `WriteDisable_low);
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
	assign 	trance_wr_en = (mem_addr_i == `SerialData)&&(mem_we_n == `WriteEnable_low);
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
				ext_uart_clear <= 1'b1;
			end
			else begin
				ext_uart_clear <= 1'b0;
			end
		end
	end
(*mark_debug = "true"*)reg [31:0] serial_o;        //串口状态、数据读取

	always @(*) begin
		if(rst) begin
			// ext_uart_start <= 1'b0;
			serial_o <= `ZeroWord;
			trance_din <= 8'h00;
			
		end
		else begin
			if(is_SerialState) begin                                     // 获取串口状态
				serial_o <= {{30{1'b0}}, {ext_uart_ready, !ext_uart_busy}};//发送状态
				// ext_uart_start <= 1'b0;//不发送
				trance_din <= 8'h00;
			end
			else if(is_SerialData) begin                   // 获取（或发送）串口数据
				if(mem_we_n) begin                    // 不写即读
					serial_o <= {24'h000000, ext_uart_rx};//拼上串口数据
					// ext_uart_start <= 1'b0;//不发送
					trance_din <= 8'h00;
				end
				else begin            //写
					trance_din <= mem_data_i[7:0];
					// ext_uart_start <= 1'b1;//发送
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

//处理BaseRam（指令存储器）
assign base_ram_data = is_base_ram ? ((mem_we_n == `WriteEnable_n) ? mem_data_i : 32'hzzzzzzzz) : 32'hzzzzzzzz;
assign base_ram_o = base_ram_data;      //读取到的BaseRam数据

//当mem阶段需要向BaseRam的地址写入或读取数据时，发生结构冒险
always @(*) begin
    base_ram_addr = 20'h00000;
    base_ram_be_n = 4'b0000;
    base_ram_ce_n = 1'b0;
    base_ram_oe_n = 1'b1;
    base_ram_we_n = 1'b1;
    inst_o = `ZeroWord;
    if(is_base_ram) begin           //涉及到BaseRam的相关数据操作，需要暂停流水线
        base_ram_addr = mem_addr_i[21:2];   //有对齐要求，低两位舍去
        base_ram_be_n = mem_sel_n;
        base_ram_ce_n = 1'b0;
        base_ram_oe_n = !mem_we_n;
        base_ram_we_n = mem_we_n;
        inst_o = `ZeroWord;
    end else begin                  //不涉及到BaseRam的相关数据操作，继续取指令
        base_ram_addr = rom_addr_i[21:2];   //有对齐要求，低两位舍去
        base_ram_be_n = 4'b0000;
        base_ram_ce_n = 1'b0;
        base_ram_oe_n = 1'b0;
        base_ram_we_n = 1'b1;
        inst_o = base_ram_o;
    end
end


//处理ExtRam（数据存储器）
assign ext_ram_data = is_ext_ram ? ((mem_we_n == `WriteEnable_n) ? mem_data_i : 32'hzzzzzzzz) : 32'hzzzzzzzz;
assign ext_ram_o = ext_ram_data;

always @(*) begin
    ext_ram_addr = 20'h00000;
    ext_ram_be_n = 4'b0000;
    ext_ram_ce_n = 1'b0;
    ext_ram_oe_n = 1'b1;
    ext_ram_we_n = 1'b1;
    if(is_ext_ram) begin           //涉及到extRam的相关数据操作
        ext_ram_addr = mem_addr_i[21:2];    //有对齐要求，低两位舍去
        ext_ram_be_n = mem_sel_n;
        ext_ram_ce_n = 1'b0;
        ext_ram_oe_n = !mem_we_n;
        ext_ram_we_n = mem_we_n;
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

//确认输出的数据
always @(*) begin
    ram_data_o = `ZeroWord;
    if(is_SerialState || is_SerialData ) begin
        ram_data_o = serial_o;
    end else if (is_base_ram) begin
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
    end else begin
        ram_data_o = `ZeroWord;
    end
end


endmodule //ram
