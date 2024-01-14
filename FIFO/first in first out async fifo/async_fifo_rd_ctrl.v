`include "fifo_defines.v"

module async_fifo_rd_ctrl #(
    parameter                           integer RAM_ADDR_WIDTH = 8  
) (
    input                               rd_clk                     ,
    input                               rd_en                      ,
    input                               rd_rst                     ,//写复位，高有效
    output reg         [RAM_ADDR_WIDTH-1:0]rdaddr                     ,
    input              [RAM_ADDR_WIDTH-1:0]wraddr                     ,
    output                              empty                      ,
    output reg         [RAM_ADDR_WIDTH-1:0]elements_rd                ,
    output reg                          prog_empty                  
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

`ifdef RD_ALMOST_EMPTY
always@(*)begin
    if ((wraddr[RAM_ADDR_WIDTH-1] == rdaddr[RAM_ADDR_WIDTH-1])) begin
        if (wraddr[RAM_ADDR_WIDTH-2:0] - rdaddr[RAM_ADDR_WIDTH-2:0] <= 'd1)
            prog_empty <= 'd1;
        else
            prog_empty <= 'd0;
    end
    else begin
        if (rdaddr[RAM_ADDR_WIDTH-2:0] - wraddr[RAM_ADDR_WIDTH-2:0] >= {1'b1,{(RAM_ADDR_WIDTH-1){1'b0}}} - 'd1)
            prog_empty <= 'd1;
        else
            prog_empty <= 'd0;
    end
end
`endif

`ifdef RD_ELEMENTS
always@(*)begin
    if ((wraddr[RAM_ADDR_WIDTH-1] == rdaddr[RAM_ADDR_WIDTH-1]))
        elements_rd <= wraddr[RAM_ADDR_WIDTH-2:0] - rdaddr[RAM_ADDR_WIDTH-2:0];
    else if (rdaddr[RAM_ADDR_WIDTH-2:0] == wraddr[RAM_ADDR_WIDTH-2:0])
        elements_rd <= {1'b1,{(RAM_ADDR_WIDTH-1){1'b0}}};
    else
        elements_rd <= rdaddr[RAM_ADDR_WIDTH-2:0] - wraddr[RAM_ADDR_WIDTH-2:0] + {1'b1,{(RAM_ADDR_WIDTH-2){1'b0}}};
end
`endif
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

//写地址时钟同步到读时钟域
beat_it_twice # (
    .DATA_WIDTH                        (RAM_ADDR_WIDTH            ) 
  )
  beat_it_twice_inst (
    .signal_i                          (wraddr2gray               ),
    .sys_clk_i                         (rd_clk                    ),
    .signal_o                          (sync_wraddr2gray          ) 
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
initial begin
    rdaddr = 'd0;
end

always@(posedge rd_clk)begin
    if (rd_rst)
        rdaddr<='d0;
    else if(rd_en && ~empty)
        rdaddr<=rdaddr+'d1;
    else
        rdaddr<=rdaddr;
end
endmodule