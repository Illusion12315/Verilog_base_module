//上电复位模块
module rst(
	input wire 			clk					,
	input wire 			rst_in				,
	
	output wire 		rst_n
);
	wire 				buf_rst_n;
	reg   [26:0]     	cnt  	=  	27'd0;
	localparam 			CNT 	=	27'd500_000;
	
always@(posedge clk)begin
	if(	cnt	< 	CNT )
		cnt <= 	cnt +1'b1;
	else
		cnt	<=	cnt;
end

assign buf_rst_n = (cnt ==	CNT - 1'b1)?1'b1:1'b0;
assign rst_n = ~buf_rst_n &&rst_in;

endmodule