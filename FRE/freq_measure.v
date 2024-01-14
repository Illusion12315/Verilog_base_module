module fre_measure
#(
    parameter                           SYS_CLK_FRE = 'd100_000_000 
)
(
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,
    input                               test_clk_i                 ,
    output reg         [  19:0]         freq_o                      
);
wire                                    calu_flag                  ;
	
reg                    [  28:0]         clk_cnt                    ;
reg                    [  28:0]         fre_cnt                    ;
reg                                     gate                       ;
reg                                     gate1,gate2,gate3          ;

localparam                              GATE_LOW = 'd20            ;

assign    calu_flag = ~gate2&gate3;

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        clk_cnt<='d0;
    else if(clk_cnt<=SYS_CLK_FRE+GATE_LOW-1'b1)
        clk_cnt<=clk_cnt+'d1;
    else
        clk_cnt<='d0;
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        gate<='d0;
    else if(clk_cnt<=SYS_CLK_FRE-1'b1)
        gate<='d1;
    else if(clk_cnt<=SYS_CLK_FRE+GATE_LOW-1'b1)
        gate<='d0;
end

always@(posedge test_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)begin
        gate1<='d0;
        gate2<='d0;
        gate3<='d0;
    end
    else begin
        gate1<=gate;
        gate2<=gate1;
        gate3<=gate2;
    end
end

always@(posedge test_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        fre_cnt<='d0;
    else if(gate2)
        fre_cnt<=fre_cnt+'d1;
    else if(calu_flag)
        fre_cnt<='d0;
    else
        fre_cnt<=fre_cnt;
end

always@(posedge test_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        freq_o<='d0;
    else if(calu_flag)
        freq_o<=fre_cnt/'d1_000;
    else
        freq_o<=freq_o;
end

endmodule

/*

//调用频率测量模块
fre_measure # (
    .SYS_CLK_FRE                       (SYS_CLK_FRE               ) 
  )
  fre_measure_inst (
    .sys_clk_i                         (sys_clk_i                 ),
    .rst_n_i                           (rst_n_i                   ),
    .test_clk_i                        (test_clk_i                ),//待测时钟
    .freq_o                            (freq_o                    ) //输出测量所得频率
  );

*/