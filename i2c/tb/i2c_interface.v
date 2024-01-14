`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/20 21:10:46
// Design Name: 
// Module Name: i2c_interface
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


module i2c_interface(
    );
    reg         i_sys_clk;
    reg         i_rst_n;
    reg         i_wr_start_flag;
    reg         i_rd_start_flag;
    reg [2:0]   i_device_addr;
    reg [7:0]   i_word_addr;
    reg [7:0]   i_wr_data;
    
initial begin
    i_sys_clk=0;
    i_rst_n=0;
    i_wr_start_flag=0;
    i_rd_start_flag=0;
    i_device_addr=0;
    i_word_addr=0;
    i_wr_data=0;
    #200
    i_rst_n=1;
    #400
    i_wr_start_flag=1;
    i_device_addr=3'b101;
    i_word_addr=8'h89;
    i_wr_data=8'h98;
    #40
    i_wr_start_flag=0;
    #3000
    i_rd_start_flag=1;
    i_device_addr=3'b101;
    i_word_addr=8'h89;
    i_wr_data=8'h98;
    #40
    i_rd_start_flag=0;
end

iic_1byte_wr_or_rd
i2c_1byte
(
	.i_sys_clk(i_sys_clk)			,
	.i_rst_n(i_rst_n)				,
	
	.i_wr_start_flag(i_wr_start_flag)		,
	.i_rd_start_flag(i_rd_start_flag)		,
	.i_device_addr	(i_device_addr)	,
	.i_word_addr	(i_word_addr)		,
	.i_wr_data	    (i_wr_data)
);
 
always #10 i_sys_clk=~i_sys_clk;
 


endmodule
