`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/31 09:04:17
// Design Name: 
// Module Name: top_sim
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


module top_sim(
    );
    reg   		   sys_clk_in_p;
	reg			   sys_clk_in_n;
	reg			       start_flag;
	reg                vio_wr;
	reg                vio_rd;
	reg	       [7:0]				years		;
	reg       [7:0]				months			;
	reg       [7:0]				dates			;
	reg        [7:0]				hours			;
	reg        [7:0]				minutes		;
	reg        [7:0]				seconds			;
	
initial begin
    sys_clk_in_p = 0;
    sys_clk_in_n = 1;
    vio_rd = 0;
    vio_wr = 0;
    #7000000
    vio_rd = 1'b1;
    #4000000
    vio_rd = 0;
    #7000000
    vio_wr = 1;
    #4000
    vio_wr = 0;
end

ds1302_top top_sim(
	.	sys_clk_in_p(sys_clk_in_p),
	.	sys_clk_in_n(sys_clk_in_n),
	
	.	vio_wr(vio_wr),
	.	vio_rd(vio_rd)
    );
always #5 sys_clk_in_p = ~sys_clk_in_p;
always #5 sys_clk_in_n = ~sys_clk_in_n;

endmodule
