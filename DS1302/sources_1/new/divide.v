//·ÖÆµ
module divide(
	input						clk_in,
	input						rst,
	
	output	reg				clk_out
);

reg	[31:0]		cnt;

localparam			N_DIVIDE = 200;

always@(posedge clk_in)begin
	if(!rst)begin
		clk_out<=0;
		cnt<=32'd0;
	end else
	if(cnt==32'd99)begin
		clk_out<=~clk_out;
		cnt<=0;
	end else
		cnt<=cnt+1'b1;
end
endmodule