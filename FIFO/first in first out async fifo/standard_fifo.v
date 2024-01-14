//--------*******----*-----------*----************----*---------*-----------**---------------**------------*******************---------
//------**-----------*-----------*----*---------------**--------*-------------**-----------**------------------------------**----------
//-----**------------*-----------*----*---------------*-*-------*---------------**-------**------------------------------**------------
//----**-------------*-----------*----*---------------*--*------*-----------------**---**------------------------------**--------------
//---**--------------*************----************----*---**----*-------------------***------------------------------**----------------
//---**--------------*-----------*----*---------------*----**---*-------------------***----------------------------**------------------
//----**-------------*-----------*----*---------------*------*--*-----------------**---**------------------------**--------------------
//-----**------------*-----------*----*---------------*-------*-*---------------**-------**--------------------**----------------------
//------**-----------*-----------*----*---------------*--------**-------------**-----------**-----------------**-----------------------
//--------********---*-----------*----************----*---------*-----------**---------------**-------------*******************--------
`include "fifo_defines.v"

module standard_fifo
#(
    parameter                           integer RD_DATA_WIDTH = 64 ,
    parameter                           integer WR_DATA_WIDTH = 64 ,
    parameter                           integer RAM_DATA_WIDTH = 64,
    parameter                           integer WR_DEPTH = 1024     
)
(
    input                               global_rst                 ,//ȫ�ָ�λ������Ч

    input                               wr_clk                     ,
    input                               wr_en                      ,
    input              [WR_DATA_WIDTH-1:0]din                        ,
    output                              full                       ,
    output             [clogb2(WR_DEPTH)-1:0]elements_wr                ,
    output                              prog_full                  ,
    
    input                               rd_clk                     ,
    input                               rd_en                      ,
    output             [RD_DATA_WIDTH-1:0]dout                       ,
    output                              empty                      ,
    output             [clogb2(WR_DEPTH)-1:0]elements_rd                ,
    output                              prog_empty                 
);
//-----------------------------------------
//--��������
//-----------------------------------------
//�������������λ��,��log��2Ϊ�׵Ķ��� +1 
function integer clogb2;
    input                               integer number             ;
    begin
        for (clogb2 = 0; number>0; clogb2=clogb2+1) begin
            number = number >> 1;
        end
    end
endfunction
//---------------------------------------------------------------------
// ��������
//---------------------------------------------------------------------
localparam                              integer RAM_ADDR_WIDTH = clogb2(WR_DEPTH);//ram�ĵ�ַλ������FIFO���ֻ֧��16��32��64��128��256��512��1024�����λ��ֻ��Ϊ4��5��6��7��8��9��10
//---------------------------------------------------------------------
// wire����
//---------------------------------------------------------------------
wire                   [RAM_ADDR_WIDTH-1:0]rdaddr                     ;
wire                   [RAM_ADDR_WIDTH-1:0]wraddr                     ;

wire                                    empty_ctrl                 ;
wire                                    full_ctrl                  ;

assign full = (global_rst)? 1'b1 : full_ctrl;
assign empty = (global_rst)? 1'b1 : empty_ctrl;
//---------------------------------------------------------------------
// д����ģ��
//---------------------------------------------------------------------
async_fifo_wr_ctrl # (
    .RAM_ADDR_WIDTH                    (RAM_ADDR_WIDTH            ) 
) async_fifo_wr_ctrl_inst (
    .wr_clk                            (wr_clk                    ),
    .wr_en                             (wr_en                     ),
    .wr_rst                            (global_rst                ),
    .wraddr                            (wraddr                    ),
    .rdaddr                            (rdaddr                    ),
    .full                              (full_ctrl                 ),
    .elements_wr                       (elements_wr               ),
    .prog_full                         (prog_full                 ) 
);
//---------------------------------------------------------------------
// ������ģ��
//---------------------------------------------------------------------
async_fifo_rd_ctrl # (
    .RAM_ADDR_WIDTH                    (RAM_ADDR_WIDTH            ) 
) async_fifo_rd_ctrl_inst (
    .rd_clk                            (rd_clk                    ),
    .rd_en                             (rd_en                     ),
    .rd_rst                            (global_rst                ),
    .rdaddr                            (rdaddr                    ),
    .wraddr                            (wraddr                    ),
    .empty                             (empty_ctrl                ),
    .elements_rd                       (elements_rd               ),
    .prog_empty                        (prog_empty                ) 
);
//---------------------------------------------------------------------
// ����˫�˿�ram
//---------------------------------------------------------------------
simple_double_port_ram # (
    .DATA_WIDTH                        (RAM_DATA_WIDTH            ),
    .RAM_LENGTH                        (WR_DEPTH                  ) 
  )
  simple_double_port_ram_inst (
    .wr_clk_i                          (wr_clk                    ),//		
    .wr_rst_i                          (global_rst                ),
    .wr_en_i                           (wr_en                     ),//				
    .wr_addr_i                         (wraddr[RAM_ADDR_WIDTH-2:0]),//[ADDR_WIDTH-1:0]
    .wr_data_i                         (din                       ),//[DATA_WIDTH-1:0]

    .rd_clk_i                          (rd_clk                    ),//		
    .rd_rst_i                          (global_rst                ),
    .rd_en_i                           (rd_en                     ),//				
    .rd_addr_i                         (rdaddr[RAM_ADDR_WIDTH-2:0]),//[ADDR_WIDTH-1:0]
    .rd_data_o                         (dout                      ),//[DATA_WIDTH-1:0]
    
    // .rd_pre_addr_i                     (pre_rdaddr[RAM_ADDR_WIDTH-2:0]),//[ADDR_WIDTH-1:0]
    .rd_pre_data_o                     (pre_dout                  ) //[DATA_WIDTH-1:0]
  );
endmodule