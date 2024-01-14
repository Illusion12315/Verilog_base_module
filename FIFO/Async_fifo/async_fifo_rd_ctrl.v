module async_fifo_rd_ctrl #(
    parameter                           integer RAM_ADDR_WIDTH = 8  
) (
    input                               rd_clk                     ,
    input                               rd_en                      ,
    input                               rd_rst                     ,//写复位，高有效
    output reg         [RAM_ADDR_WIDTH-1:0]rdaddr                     ,
    input              [RAM_ADDR_WIDTH-1:0]wraddr                     ,
    output                              empty                       ,
    output                              prog_empty                  

);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// wire定义
//---------------------------------------------------------------------
wire                   [RAM_ADDR_WIDTH-1:0]wraddr2gray                ;
wire                   [RAM_ADDR_WIDTH-1:0]sync_wraddr2gray           ;
wire                   [RAM_ADDR_WIDTH-1:0]sync_wraddr                ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// 时序逻辑
//---------------------------------------------------------------------
assign empty = ((wraddr[RAM_ADDR_WIDTH-1] == rdaddr[RAM_ADDR_WIDTH-1]) && (wraddr[RAM_ADDR_WIDTH-2:0] == rdaddr[RAM_ADDR_WIDTH-2:0]))? 1'b1 : 1'b0;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// 写地址时钟同步到读时钟域
//---------------------------------------------------------------------
bin2gray #(
    .DATA_WIDTH                        (RAM_ADDR_WIDTH            ) 
)wraddr_2_gray(
    .bin_i                             (wraddr                    ),
    .gray_o                            (wraddr2gray               ) 
);

//单bit慢时钟同步到快时钟
slow2fast_sync_module #(
    .DATA_WIDTH                        (RAM_ADDR_WIDTH            ) 
)sync_wr2rd(
    .i_signal                          (wraddr2gray               ),
    .i_clk_fast                        (rd_clk                    ),
    .o_signal                          (sync_wraddr2gray          ) 
);

gray2bin #(
    .DATA_WIDTH                        (RAM_ADDR_WIDTH            ) 
)wraddr_2_bin(
    .gray_i                            (sync_wraddr2gray          ),
    .bin_o                             (sync_wraddr               ) 
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// 配置地址
//---------------------------------------------------------------------
always@(posedge rd_clk)begin
    if (rd_rst) begin
        rdaddr<='d0;
    end
    else if(rd_en)
        rdaddr<=rdaddr+'d1;
    else
        rdaddr<=rdaddr;
end
endmodule