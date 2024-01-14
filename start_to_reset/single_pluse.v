//单低变高输入，单脉冲输出
module signle_pluse(
	input			clk				,
	input			rst				,
	input			signal_in		,
	output			pluse_out
);
	reg 			delay_reg1		;
	reg				delay_reg2		;
	
always@(posedge clk or negedge rst)begin
	if(!rst)begin
		delay_reg1<=1'b0;
		delay_reg2<=1'b0;
	end else begin
		delay_reg1<=signal_in;
		delay_reg2<=delay_reg1;
	end
end

assign pluse_out = delay_reg1&(~delay_reg2)&signal_in;

endmodule