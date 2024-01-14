`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: chenxiongzhi
// 
// Create Date: 2023/08/24 16:22:08
// Design Name: 
// Module Name: RST
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


//上电自动产生复位
module start_rst_module
#(
	parameter	RST_TIME_CNT = 'd1_000
)
(
	input	i_sys_clk		,
	input	i_rst_in		,
	
	output	o_rst_out
);
	reg		[15:0]		cnt='d0;
	reg				auto_rst_n;

assign	o_rst_out = auto_rst_n & i_rst_in;

always@(posedge i_sys_clk)begin
	if(cnt<RST_TIME_CNT-'d1)begin
		cnt<=cnt+'d1;
		auto_rst_n<='d0;
	end
	else begin
		cnt<=cnt;
		auto_rst_n<=1'd1;
	end
end

endmodule
