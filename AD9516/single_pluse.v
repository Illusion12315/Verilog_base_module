//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: chen xiongzhi
// 
// Create Date: 2023/10/08
// Design Name: 
// Module Name: 			
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


//单低变高输入，单脉冲输出

module signle_pluse(
    input                               clk                        ,
    input                               signal_in                  ,
    output                              pluse_out                   
);
reg                                     delay_reg1                 ;
reg                                     delay_reg2                 ;
	
always@(posedge clk)begin
    delay_reg1<=signal_in;
    delay_reg2<=delay_reg1;
end

assign pluse_out = delay_reg1&(~delay_reg2)&signal_in;

endmodule