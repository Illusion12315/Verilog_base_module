`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/29 13:48:10
// Design Name: 
// Module Name: wr
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


module wr(
    );
    reg   		   sys_clk;
	reg			   rst;
	reg			       start_flag;
	reg [7:0]	      control_data;
	reg [7:0]		      reg_data;	
initial begin
    rst = 0;
    sys_clk = 0;
    control_data = 8'hf1;
    reg_data = 8'h43;
    start_flag = 0;
    #1000
    rst = 1;
    #2000
    start_flag = 1;
    #3000
    start_flag = 0;
end

spi_wr wr_sim(
	.sys_clk(sys_clk)			,		//1MHz
	.wr_start_flag(start_flag)		,		
	.control_data(control_data)	,
	.reg_data(reg_data)		,
	.rst	(rst)			
	
);


always #500 sys_clk = ~sys_clk;
    
endmodule
