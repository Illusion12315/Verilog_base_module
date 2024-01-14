//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: chenxiongzhi
// 
// Create Date: 2023/08/29 17:06:41
// Design Name: 
// Module Name: speed_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module test_speed
#(	parameter		CLK_FRE = 'd200_000_000,
	parameter		DATA_WIDTH = 64
)
(
	input				i_data_valid_flag		,
	input				i_sys_clk				,		//频率x
	input				i_rst_n					,
	
	output	reg [15:0]	o_speed_out_MB
);

	reg		[31:0]	speed		=	'd0;
	reg		[31:0]	clk_cnt		=	'd0;
	reg		[31:0]	speed_out	=	'd0;

always@(posedge i_sys_clk or negedge i_rst_n)begin
	if(!i_rst_n)
		o_speed_out_MB<='d0;
	else case(DATA_WIDTH)
		32	:o_speed_out_MB<=speed_out>>18;
		64	:o_speed_out_MB<=speed_out>>17;
		128	:o_speed_out_MB<=speed_out>>16;
		256	:o_speed_out_MB<=speed_out>>15;
		512	:o_speed_out_MB<=speed_out>>14;
		default:o_speed_out_MB<=speed_out;
		endcase
end

always@(posedge i_sys_clk or negedge i_rst_n)begin
	if(!i_rst_n)begin
		clk_cnt<='d0;
		speed<='d0;
		speed_out<='d0;
	end 
	else if(clk_cnt==CLK_FRE-1)begin
			clk_cnt<='d0;
			speed<='d0;
			speed_out<=speed;
		end 
	else begin
		if(i_data_valid_flag)
			speed<=speed+1'b1;
		else
			speed<=speed;
		clk_cnt<=clk_cnt+1'b1;
	end
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// DEBUG
//--------------------------------------------------------------------- 


endmodule
/*
//调用速度测试模块
test_speed
#(	.CLK_FRE				(),
	.DATA_WIDTH				()
)
test_xx
(
	.i_data_valid_flag		(),		//输入使能
	.i_sys_clk				(),		//输入频率
	.i_rst_n				(),	//系统复位
	
	.o_speed_out_MB			()		//16位宽
);
*/