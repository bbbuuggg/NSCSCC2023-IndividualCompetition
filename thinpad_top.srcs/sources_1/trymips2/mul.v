`include "defines.v"
module mul(
    input wire [31:0] mul1, //数1
    input wire [31:0] mul2, //数2
    output wire [31:0] mulans//结果
);
	// //验证部分
    // wire [63:0]  cmpans;
    // wire [63:0]  A_cmp;
    // wire [63:0]  B_cmp;
    // assign A_cmp = {{32{mul1[31]}},mul1};
    // assign B_cmp = {{32{mul2[31]}},mul2};

    // assign cmpans = A_cmp*B_cmp;
    // assign cmpans = ans;
	wire [63:0]ans;
    wire [31: 0] A;  
    wire [31: 0] A_w;   
    wire [31: 0] A_2; 
    wire [31: 0] revA;
    wire [31: 0] rev2A;
    wire [31: 0] B;
    wire [31: 0] B_w;
    wire [63: 0] Nsum [15: 0];//booth中的 16个x添加数
    wire [64: 0] Csum [16: 0];
    wire [63: 0] Ssum [16: 0];
    wire [ 2: 0] y[31: 0];//booth算法三位符号位组合
    assign A = mul1; //乘数1
    assign revA = ~A; //A的反码
    assign A_2  = ~(A<<1); //A *2 取反
    assign rev2A= A_2; 
    assign B = mul2; //乘数2
	
	//循环例化
    genvar i;
    genvar j;
    generate 
        assign y[1] = {B[1],B[0],1'b0};//迭代初值
        for(i=3;i<=31;i=i+2)begin//16组使用的y[ , ,]
            assign y[i]= {B[i],B[i-1],B[i-2]};//y3 y2 y1
        end
    endgenerate
    generate 
        for(i=1;i<=16;i=i+1)begin
            assign  Nsum[i-1] = {64{y[2*i-1]==3'b000}} & 64'b0 | //000 + 0 //含进位
								{64{y[2*i-1]==3'b001}} & {{34-2*i{A[31]}},A,{2*i-2{1'b0}}} | // 001 + [x]补
                                {64{y[2*i-1]==3'b010}} & {{34-2*i{A[31]}},A,{2*i-2{1'b0}}} | // 010 + [x]补
                                {64{y[2*i-1]==3'b011}} & {{33-2*i{A[31]}},A,{2*i-1{1'b0}}} | // 011 + 2[x]补
                                {64{y[2*i-1]==3'b100}} & {{34-2*i{rev2A[31]}},rev2A,{2*i-2{1'b1}}} | // 100 + -2[x]补
                                {64{y[2*i-1]==3'b101}} & {{34-2*i{revA[31]}}, revA,{2*i-2{1'b1}}} | // 101 + -[x]补
                                {64{y[2*i-1]==3'b110}} & {{34-2*i{revA[31]}}, revA,{2*i-2{1'b1}}} | // 110 + -[x]补
                                {64{y[2*i-1]==3'b111}} & 64'b0;		// 111 + 0
            assign  Csum[i-1][0] = { 1{y[2*i-1]==3'b100}} & 1'b1 |		//减法标志 ？						
                                   { 1{y[2*i-1]==3'b101}} & 1'b1 |
                                   { 1{y[2*i-1]==3'b110}} & 1'b1;                  
        end
    endgenerate
    assign Csum[16][0] = 1'b0; //？
    generate 
        for(i=1;i<=64;i=i+1)begin
			//前八项
            csa  csa0(.a(Nsum[  0][i-1]),.b(Nsum[  1][i-1]),.cin(Nsum[  2][i-1]),.s(Ssum[ 0][i-1]),.cout(Csum[ 0][i]));
            csa  csa1(.a(Nsum[  3][i-1]),.b(Nsum[  4][i-1]),.cin(Nsum[  5][i-1]),.s(Ssum[ 1][i-1]),.cout(Csum[ 1][i]));
            csa  csa2(.a(Nsum[  6][i-1]),.b(Nsum[  7][i-1]),.cin(Nsum[  8][i-1]),.s(Ssum[ 2][i-1]),.cout(Csum[ 2][i]));
			//后八项
            csa  csa3(.a(Nsum[  9][i-1]),.b(Nsum[ 10][i-1]),.cin(Nsum[ 11][i-1]),.s(Ssum[ 3][i-1]),.cout(Csum[ 3][i]));
            csa  csa4(.a(Nsum[ 12][i-1]),.b(Nsum[ 13][i-1]),.cin(Nsum[ 14][i-1]),.s(Ssum[ 4][i-1]),.cout(Csum[ 4][i]));
            csa  csa5(.a(Nsum[ 15][i-1]),.b(1'b0          ),.cin(1'b0          ),.s(Ssum[ 5][i-1]),.cout(Csum[ 5][i]));//首层十六项 16/3 = 6
			
            csa  csa6(.a(Ssum[  0][i-1]),.b(Ssum[  1][i-1]),.cin(Ssum[  2][i-1]),.s(Ssum[ 6][i-1]),.cout(Csum[ 6][i]));
            csa  csa7(.a(Ssum[  3][i-1]),.b(Ssum[  4][i-1]),.cin(Ssum[  5][i-1]),.s(Ssum[ 7][i-1]),.cout(Csum[ 7][i]));//二层六项
			
            csa  csa8(.a(Csum[  0][i-1]),.b(Csum[  1][i-1]),.cin(Csum[  2][i-1]),.s(Ssum[ 8][i-1]),.cout(Csum[ 8][i]));//前八项进位和 S8
            csa  csa9(.a(Csum[  3][i-1]),.b(Csum[  4][i-1]),.cin(Csum[  5][i-1]),.s(Ssum[ 9][i-1]),.cout(Csum[ 9][i]));//后八项进位和 S9 *
			
            csa csa10(.a(Ssum[  6][i-1]),.b(Ssum[  7][i-1]),.cin(Ssum[  8][i-1]),.s(Ssum[10][i-1]),.cout(Csum[10][i]));
            csa csa11(.a(Ssum[  9][i-1]),.b(Csum[  6][i-1]),.cin(Csum[  7][i-1]),.s(Ssum[11][i-1]),.cout(Csum[11][i]));//所有二层
			
            csa csa12(.a(Csum[  8][i-1]),.b(Csum[  9][i-1]),.cin(1'b0),.s(Ssum[12][i-1]),.cout(Csum[12][i]));//** 到*
            csa csa13(.a(Ssum[ 10][i-1]),.b(Ssum[ 11][i-1]),.cin(Ssum[ 12][i-1]),.s(Ssum[13][i-1]),.cout(Csum[13][i]));
            csa csa14(.a(Csum[ 10][i-1]),.b(Csum[ 11][i-1]),.cin(Csum[ 12][i-1]),.s(Ssum[14][i-1]),.cout(Csum[14][i]));//到*
			
            csa csa15(.a(Ssum[ 13][i-1]),.b(Ssum[ 14][i-1]),.cin(Csum[ 13][i-1]),.s(Ssum[15][i-1]),.cout(Csum[15][i]));
            csa csa16(.a(Ssum[ 15][i-1]),.b(Csum[ 14][i-1]),.cin(Csum[ 15][i-1]),.s(Ssum[16][i-1]),.cout(Csum[16][i]));
        end
    endgenerate
    assign ans = (Ssum[16] + Csum[16]);
	assign mulans = ans[31:0] ;
endmodule

module csa( //全加器
    input wire a,
    input wire b,
    input wire cin,
    output wire s,
    output wire cout
);
    assign {cout,s} = a+b+cin;
endmodule
