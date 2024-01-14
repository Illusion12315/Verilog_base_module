`include "fifo_defines.v"

module async_fifo_wr_ctrl #(
    parameter                           integer RAM_ADDR_WIDTH = 8  
) (
    input                               wr_clk                     ,
    input                               wr_en                      ,
    input                               wr_rst                     ,//写复位，高有效
    output reg         [RAM_ADDR_WIDTH-1:0]wraddr                     ,
    input              [RAM_ADDR_WIDTH-1:0]rdaddr                     ,
    output                              full                       ,
    output reg         [RAM_ADDR_WIDTH-1:0]elements_wr                ,
    output reg                          prog_full                   
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

`ifdef WR_ALMOST_FULL
always@(*)begin
    if ((wraddr[RAM_ADDR_WIDTH-1] != rdaddr[RAM_ADDR_WIDTH-1])) begin
        if (rdaddr[RAM_ADDR_WIDTH-2:0] - wraddr[RAM_ADDR_WIDTH-2:0] <= `PROG_FULL)
            prog_full <= 'd1;
        else
            prog_full <= 'd0;
    end
    else begin
        if (wraddr[RAM_ADDR_WIDTH-2:0] - rdaddr[RAM_ADDR_WIDTH-2:0] >= {1'b1,{(RAM_ADDR_WIDTH-1){1'b0}}} - `PROG_FULL)
            prog_full <= 'd1;
        else
            prog_full <= 'd0;
    end
end
`endif

`ifdef WR_ELEMENTS
always@(*)begin
    if ((wraddr[RAM_ADDR_WIDTH-1] != rdaddr[RAM_ADDR_WIDTH-1]))begin
        if (wraddr[RAM_ADDR_WIDTH-2:0] == rdaddr[RAM_ADDR_WIDTH-2:0])
            elements_wr <= {1'b1,{(RAM_ADDR_WIDTH-1){1'b0}}};
        else
            elements_wr <= rdaddr[RAM_ADDR_WIDTH-2:0] - wraddr[RAM_ADDR_WIDTH-2:0] + {1'b1,{(RAM_ADDR_WIDTH-2){1'b0}}};
    end
    // else if (wraddr[RAM_ADDR_WIDTH-2:0] == rdaddr[RAM_ADDR_WIDTH-2:0])
    //     elements_wr <= {1'b1,{(RAM_ADDR_WIDTH-2){1'b0}}};
    else
        elements_wr <= wraddr[RAM_ADDR_WIDTH-2:0] - rdaddr[RAM_ADDR_WIDTH-2:0];
end
`endif
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

//读地址时钟同步到写时钟域
beat_it_twice # (
    .DATA_WIDTH                        (RAM_ADDR_WIDTH            ) 
  )
  beat_it_twice_inst (
    .signal_i                          (rdaddr2gray               ),
    .sys_clk_i                         (wr_clk                    ),
    .signal_o                          (sync_rdaddr2gray          ) 
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
initial begin
    wraddr = 'd0;
end

always@(posedge wr_clk)begin
    if (wr_rst)
        wraddr<='d0;
    else if(wr_en && ~full)
        wraddr<=wraddr+'d1;
    else
        wraddr<=wraddr;
end
endmodule