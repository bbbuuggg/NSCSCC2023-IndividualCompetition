`include "defines.v"

module sram_check(
	input wire rst,
	input wire clk,
	input wire [31:0] inst_check,
	output reg  pre_stall
);
	wire [5:0] op;
	reg [2:0] cnt;
	assign op = inst_check[31:26];
	always @(*) begin
		if(rst == `RstEnable)begin
			pre_stall = 1'b0;
		end else if((op == 6'b100000 || op ==6'b100011)) begin
			pre_stall = 1'b1;
		end else begin
			pre_stall = 1'b0;
		end
    end
	
	always@(posedge clk or negedge rst)begin
		if(rst == `RstEnable)begin
			cnt<=3'b000;
		end
		else if(cnt==3'd1)begin
			cnt<=3'b000;
		end
		else if(op == 6'b100000 || op ==6'b100011) begin
			cnt<=cnt+1'b1;
		end
		else begin
			cnt<=cnt;
		end
	end
endmodule
		
		