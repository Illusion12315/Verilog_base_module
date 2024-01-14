
module first_word_fall_through_fifo #(
    parameter                           integer RD_DATA_WIDTH = 64 ,
    parameter                           integer WR_DATA_WIDTH = 64 ,
    parameter                           integer RAM_DATA_WIDTH = 64,
    parameter                           integer WR_DEPTH = 1024     
) (
    input                               global_rst                 ,//全局复位，高有效
    
    input                               wr_clk                     ,
    input                               wr_en                      ,
    input              [WR_DATA_WIDTH-1:0]din                        ,
    output                              full                       ,
    output             [clogb2(WR_DEPTH)-1:0]elements_wr                ,
    output                              prog_full                  ,
        
    input                               rd_clk                     ,
    input                               rd_en                      ,
    output reg         [RD_DATA_WIDTH-1:0]dout                       ,
    output                              empty                      ,
    output             [clogb2(WR_DEPTH)-1:0]elements_rd                ,
    output                              prog_empty                  
    );
//-----------------------------------------
//--函数定义
//-----------------------------------------
//函数计算二进制位宽,求log以2为底的对数 +1 
    function integer clogb2;
    input                               integer number             ;
    begin
        for (clogb2 = 0; number>0; clogb2=clogb2+1) begin
            number = number >> 1;
        end
    end
endfunction                                                         //---------------------------------------------------------------------
// 参数定义
//---------------------------------------------------------------------
localparam                              integer RAM_ADDR_WIDTH = clogb2(WR_DEPTH);//ram的地址位宽，由于FIFO深度只支持16，32，64，128，256，512，1024，则该位宽只能为4，5，6，7，8，9，10
// ********************************************************************************** // 
//---------------------------------------------------------------------
// wires
//---------------------------------------------------------------------
wire                   [RAM_ADDR_WIDTH-1:0]rdaddr                     ;
wire                   [RAM_ADDR_WIDTH-1:0]pre_rdaddr                 ;
wire                   [RD_DATA_WIDTH-1:0]pre_dout                   ;
wire                   [RD_DATA_WIDTH-1:0]standard_dout              ;
wire                                    addr_switch                ;
wire                                    rd_en_posedge_flag         ;
reg                                     rd_en_r1                   ;
reg                                     valid                      ;
reg                                     standard_empty_r1          ;

assign empty = standard_empty | standard_empty_r1;
assign pre_rdaddr = rdaddr + 'd1;
assign rd_en_posedge_flag = rd_en & ~rd_en_r1;

always@(*)begin
    if (empty)begin
        if (standard_empty && ~standard_empty_r1)
            dout <= pre_dout;
        else
            dout <= standard_dout;
    end
    else if (!rd_en_posedge_flag && rd_en)
        dout <= pre_dout;
    else
        dout <= standard_dout;
end

always@(posedge rd_clk)begin
    standard_empty_r1 <= standard_empty;
end

always@(posedge rd_clk)begin
    rd_en_r1 <= rd_en;
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// standard fifo
//---------------------------------------------------------------------
standard_fifo # (
    .RD_DATA_WIDTH                     (RD_DATA_WIDTH             ),
    .WR_DATA_WIDTH                     (WR_DATA_WIDTH             ),
    .RAM_DATA_WIDTH                    (RAM_DATA_WIDTH            ),
    .WR_DEPTH                          (WR_DEPTH                  ) 
  )
  standard_fifo_inst (
    .global_rst                        (global_rst                ),
    .wr_clk                            (wr_clk                    ),
    .wr_en                             (wr_en                     ),
    .din                               (din                       ),
    .full                              (full                      ),
    .elements_wr                       (elements_wr               ),
    .prog_full                         (prog_full                 ),

    .rd_clk                            (rd_clk                    ),
    .rd_en                             (rd_en                     ),
    .dout                              (standard_dout             ),
    .empty                             (standard_empty            ),
    .elements_rd                       (elements_rd               ),
    .prog_empty                        (prog_empty                ),

    .rdaddr                            (rdaddr                    ),
    .pre_rdaddr                        (pre_rdaddr                ),
    .pre_dout                          (pre_dout                  ) 
  );
endmodule