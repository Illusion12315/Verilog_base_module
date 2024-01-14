//时间：2023/09/03/08：36
//作者：陈雄志

module simple_double_port_ram
#(
    parameter                           DATA_WIDTH=8               ,
    parameter                           RAM_LENGTH=65536            
)
(
    input                               wr_clk_i                   ,
    input                               wr_rst_i                   ,
    input                               wr_en_i                    ,
    input              [clogb2(RAM_LENGTH)-1:0]wr_addr_i                  ,
    input              [DATA_WIDTH-1:0] wr_data_i                  ,
	
    input                               rd_clk_i                   ,
    input                               rd_rst_i                   ,
    input                               rd_en_i                    ,
    input              [clogb2(RAM_LENGTH)-1:0]rd_addr_i                  ,
    output reg         [DATA_WIDTH-1:0] rd_data_o                  ,

    input              [clogb2(RAM_LENGTH)-1:0]rd_pre_addr_i              ,
    output reg         [DATA_WIDTH-1:0] rd_pre_data_o               
);
//-----------------------------------------
//--函数定义
//-----------------------------------------
//函数计算二进制位宽,求log以2为底的对数
function integer clogb2;
    input                               integer number             ;
    begin
        for (clogb2 = 0; number>1; clogb2=clogb2+1) begin
            number = number >> 1;
        end
    end
endfunction
// ********************************************************************************** // 
//---------------------------------------------------------------------
// 
//---------------------------------------------------------------------
reg                    [DATA_WIDTH-1:0]	ram[0:RAM_LENGTH-1]                           ;

integer i;

initial begin
    rd_data_o <= 'd0;
    for (i = 0; i<RAM_LENGTH; i=i+1) begin
        ram[i]<= 8'd0;
    end
end

always@(posedge wr_clk_i)begin
    if(wr_en_i && ~wr_rst_i)
        ram[wr_addr_i]=wr_data_i;
    else
        ram[wr_addr_i]<=ram[wr_addr_i];
end

always@(posedge rd_clk_i)begin
    if (rd_rst_i)
        rd_data_o<='d0;
    else
        rd_data_o<=ram[rd_addr_i];
end

always@(posedge rd_clk_i)begin
    if (rd_rst_i)
        rd_pre_data_o<='d0;
    else
        rd_pre_data_o<=ram[rd_pre_addr_i];
end
endmodule