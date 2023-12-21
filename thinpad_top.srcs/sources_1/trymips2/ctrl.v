`include "defines.v"

module ctrl(
	input wire					 rst,

    //来自id阶段的暂停请求
	input wire                   stallreq_from_id,

	//来自baseram的暂停请求
	input wire 					 stallreq_from_baseram,

	output reg              	 stall
);

	always @(*) begin
        if(stallreq_from_id )begin//| stall_from_mem | stallreq_from_baseram
			stall = 1'b1;
		end else begin
			stall = 1'b0;
		end
    end

	// always @(negedge stallreq_from_baseram) begin
        // // 尝试延长延迟信号
        // stall = 1'b1;
	// end

endmodule
		
		