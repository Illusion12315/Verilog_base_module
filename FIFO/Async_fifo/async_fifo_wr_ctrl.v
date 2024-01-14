module async_fifo_wr_ctrl #(
    parameter                           integer RAM_ADDR_WIDTH = 8  
) (
    input                               wr_clk                     ,
    input                               wr_en                      ,
    input                               wr_rst                     ,//写复位，高有效
    output reg         [RAM_ADDR_WIDTH-1:0]wraddr                     ,
    input              [RAM_ADDR_WIDTH-1:0]rdaddr                     ,
    output                              full                       ,
    output                              prog_full                  

);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// wire定义
//---------------------------------------------------------------------
wire                   [RAM_ADDR_WIDTH-1:0]rdaddr2gray                ;
wire                   [RAM_ADDR_WIDTH-1:0]sync_rdaddr2gray           ;
wire                   [RAM_ADDR_WIDTH-1:0]sync_rdaddr                ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// 时序逻辑
//---------------------------------------------------------------------
assign full = ((wraddr[RAM_ADDR_WIDTH-1] != rdaddr[RAM_ADDR_WIDTH-1]) && (wraddr[RAM_ADDR_WIDTH-2:0] == rdaddr[RAM_ADDR_WIDTH-2:0]))? 1'b1 : 1'b0;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// 读地址时钟同步到写时钟域
//---------------------------------------------------------------------
bin2gray #(
    .DATA_WIDTH                        (RAM_ADDR_WIDTH            ) 
)rdaddr_2_gray(
    .bin_i                             (rdaddr                    ),
    .gray_o                            (rdaddr2gray               ) 
);

//单bit慢时钟同步到快时钟
slow2fast_sync_module #(
    .DATA_WIDTH                        (RAM_ADDR_WIDTH            ) 
)sync_rd2wr(
    .i_signal                          (rdaddr2gray               ),
    .i_clk_fast                        (wr_clk                    ),
    .o_signal                          (sync_rdaddr2gray          ) 
);

gray2bin #(
    .DATA_WIDTH                        (RAM_ADDR_WIDTH            ) 
)rdaddr_2_bin(
    .gray_i                            (sync_rdaddr2gray          ),
    .bin_o                             (sync_rdaddr               ) 
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// 配置地址
//---------------------------------------------------------------------
always@(posedge wr_clk)begin
    if (wr_rst) begin
        wraddr<='d0;
    end
    else if(wr_en)
        wraddr<=wraddr+'d1;
    else
        wraddr<=wraddr;
end
endmodule