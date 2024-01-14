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
module async_fifo
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
    output                              prog_full                  ,
    
    input                               rd_clk                     ,
    input                               rd_en                      ,
    output             [RD_DATA_WIDTH-1:0]dout                       ,
    output                              empty                      ,
    output                              prog_empty                  
);
//-----------------------------------------
//--��������
//-----------------------------------------
//�������������λ��,��log��2Ϊ�׵Ķ���
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
localparam                              integer RAM_ADDR_WIDTH = clogb2(WR_DEPTH) + 1;//ram�ĵ�ַλ������FIFO���ֻ֧��16��32��64��128��256��512��1024�����λ��ֻ��Ϊ4��5��6��7��8��9��10
//---------------------------------------------------------------------
// wire����
//---------------------------------------------------------------------
wire                   [RAM_ADDR_WIDTH-1:0]elements_wr                ;
wire                   [RAM_ADDR_WIDTH-1:0]elements_rd                ;

wire                   [RAM_ADDR_WIDTH-1:0]wraddr                     ;
wire                   [RAM_ADDR_WIDTH-1:0]rdaddr                     ;

wire                                    wr_rst                     ;//дʱ����λ������Ч
wire                                    rd_rst                     ;//��ʱ����λ������Ч
//---------------------------------------------------------------------
// д����ģ��
//---------------------------------------------------------------------
async_fifo_wr_ctrl # (
    .RAM_ADDR_WIDTH                    (RAM_ADDR_WIDTH            ) 
) async_fifo_wr_ctrl_inst (
    .wr_clk                            (wr_clk                    ),
    .wr_en                             (wr_en                     ),
    .wr_rst                            (wr_rst                    ),
    .wraddr                            (wraddr                    ),
    .rdaddr                            (rdaddr                    ),
    .full                              (full                      ),
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
    .rd_rst                            (rd_rst                    ),
    .rdaddr                            (rdaddr                    ),
    .wraddr                            (wraddr                    ),
    .empty                             (empty                     ),
    .elements_rd                       (elements_rd               ),
    .prog_empty                        (prog_empty                ) 
);
//---------------------------------------------------------------------
// ��λͬ��
//---------------------------------------------------------------------
//д��λͬ��
slow2fast_sync_module wr_rst_sync(
    .i_signal                          (global_rst                ),
    .i_clk_fast                        (wr_clk                    ),
    .o_signal                          (wr_rst                    ) 
);
//����λͬ��
slow2fast_sync_module rd_rst_sync(
    .i_signal                          (global_rst                ),
    .i_clk_fast                        (rd_clk                    ),
    .o_signal                          (rd_rst                    ) 
);
//---------------------------------------------------------------------
// ����˫�˿�ram
//---------------------------------------------------------------------
double_port_ram #(
    .DATA_WIDTH                        (RAM_DATA_WIDTH            ),
    .ADDR_WIDTH                        (RAM_ADDR_WIDTH            ) 
)double_port_ram0
(
    .wr_clk_i                          (wr_clk                    ),//				
    .wr_en_i                           (wr_en                     ),//				
    .wr_addr_i                         (wraddr                    ),//[ADDR_WIDTH-1:0]
    .wr_data_i                         (din                       ),//[DATA_WIDTH-1:0]
	
    .rd_clk_i                          (rd_clk                    ),//				
    .rd_en_i                           (rd_en                     ),//				
    .rd_addr_i                         (rdaddr                    ),//[ADDR_WIDTH-1:0]
    .rd_data_o                         (dout                      ) //[DATA_WIDTH-1:0]
);
endmodule


// ********************************************************************************** // 
//---------------------------------------------------------------------
// д����ģ��
//---------------------------------------------------------------------
module async_fifo_wr_ctrl #(
    parameter                           integer RAM_ADDR_WIDTH = 8  
) (
    input                               wr_clk                     ,
    input                               wr_en                      ,
    input                               wr_rst                     ,//д��λ������Ч
    output reg         [RAM_ADDR_WIDTH-1:0]wraddr                     ,
    input              [RAM_ADDR_WIDTH-1:0]rdaddr                     ,
    output                              full                       ,
    output             [RAM_ADDR_WIDTH-1:0]elements_wr                ,
    output                              prog_full                   

);
localparam                              integer N = 1              ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// wire����
//---------------------------------------------------------------------
wire                   [RAM_ADDR_WIDTH-1:0]rdaddr2gray                ;
wire                   [RAM_ADDR_WIDTH-1:0]sync_rdaddr2gray           ;
wire                   [RAM_ADDR_WIDTH-1:0]sync_rdaddr                ;
wire                   [RAM_ADDR_WIDTH-1:0]wr_addr                    ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// ����߼�
//---------------------------------------------------------------------
assign wr_addr = wraddr + N;
assign full = ((wraddr[RAM_ADDR_WIDTH-1] != rdaddr[RAM_ADDR_WIDTH-1]) && (wraddr[RAM_ADDR_WIDTH-2:0] == rdaddr[RAM_ADDR_WIDTH-2:0]))? 1'b1 : 1'b0;
assign prog_full = ((wr_addr[RAM_ADDR_WIDTH-1] != rdaddr[RAM_ADDR_WIDTH-1]) && (wr_addr[RAM_ADDR_WIDTH-2:0] == rdaddr[RAM_ADDR_WIDTH-2:0]))? 1'b1 : 1'b0;
assign elements_wr = wraddr - sync_rdaddr;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// ����ַʱ��ͬ����дʱ����
//---------------------------------------------------------------------
bin2gray #(
    .DATA_WIDTH                        (RAM_ADDR_WIDTH            ) 
)rdaddr_2_gray(
    .bin_i                             (rdaddr                    ),
    .gray_o                            (rdaddr2gray               ) 
);

//��bit��ʱ��ͬ������ʱ��
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
// ���õ�ַ
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
// ********************************************************************************** // 
//---------------------------------------------------------------------
// ������ģ��
//---------------------------------------------------------------------
module async_fifo_rd_ctrl #(
    parameter                           integer RAM_ADDR_WIDTH = 8  
) (
    input                               rd_clk                     ,
    input                               rd_en                      ,
    input                               rd_rst                     ,//д��λ������Ч
    output reg         [RAM_ADDR_WIDTH-1:0]rdaddr                     ,
    input              [RAM_ADDR_WIDTH-1:0]wraddr                     ,
    output                              empty                      ,
    output             [RAM_ADDR_WIDTH-1:0]elements_rd                ,
    output                              prog_empty                  

);
localparam                              integer N = 1              ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// wire����
//---------------------------------------------------------------------
wire                   [RAM_ADDR_WIDTH-1:0]wraddr2gray                ;
wire                   [RAM_ADDR_WIDTH-1:0]sync_wraddr2gray           ;
wire                   [RAM_ADDR_WIDTH-1:0]sync_wraddr                ;
wire                   [RAM_ADDR_WIDTH-1:0]rd_addr                    ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// ʱ���߼�
//---------------------------------------------------------------------
assign rd_addr = rdaddr + N;
assign empty = ((wraddr[RAM_ADDR_WIDTH-1] == rdaddr[RAM_ADDR_WIDTH-1]) && (wraddr[RAM_ADDR_WIDTH-2:0] == rdaddr[RAM_ADDR_WIDTH-2:0]))? 1'b1 : 1'b0;
assign prog_empty = ((wraddr[RAM_ADDR_WIDTH-1] == rd_addr[RAM_ADDR_WIDTH-1]) && (wraddr[RAM_ADDR_WIDTH-2:0] == rd_addr[RAM_ADDR_WIDTH-2:0]))? 1'b1 : 1'b0;
assign elements_rd = sync_wraddr - rdaddr;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// д��ַʱ��ͬ������ʱ����
//---------------------------------------------------------------------
bin2gray #(
    .DATA_WIDTH                        (RAM_ADDR_WIDTH            ) 
)wraddr_2_gray(
    .bin_i                             (wraddr                    ),
    .gray_o                            (wraddr2gray               ) 
);

//��bit��ʱ��ͬ������ʱ��
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
// ���õ�ַ
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
// ********************************************************************************** // 
//---------------------------------------------------------------------
// ������ת������ģ��
//---------------------------------------------------------------------
module bin2gray
#(
    parameter                           integer DATA_WIDTH = 256    
)
(
    input              [DATA_WIDTH-1:0] bin_i                      ,
    output             [DATA_WIDTH-1:0] gray_o                      
);

assign gray_o = (bin_i >> 1) ^ bin_i ;

endmodule
// ********************************************************************************** // 
//---------------------------------------------------------------------
// ������ת������ģ��
//---------------------------------------------------------------------
module gray2bin
#(
    parameter                           integer DATA_WIDTH = 256    
)
(
    output             [DATA_WIDTH-1:0] bin_o                      ,
    input              [DATA_WIDTH-1:0] gray_i                      
);

assign bin_o[DATA_WIDTH-1] = gray_i[DATA_WIDTH-1];

generate
    genvar i;
    for (i = 0; i<DATA_WIDTH-1; i=i+1) begin
        assign bin_o[i] = gray_i[i]^bin_o[i+1];
    end
endgenerate

endmodule
// ********************************************************************************** // 
//---------------------------------------------------------------------
// ��bit��ʱ��ͬ������ʱ��ģ��
//---------------------------------------------------------------------
//��bit��ʱ��ͬ������ʱ��
module    slow2fast_sync_module #(
    parameter                           integer DATA_WIDTH = 1      
)
(
    input                               i_clk_slow                 ,
    input              [DATA_WIDTH-1:0] i_signal                   ,
    input                               i_clk_fast                 ,
    output             [DATA_WIDTH-1:0] o_signal                    
);

(* ASYNC_REG = "TRUE" *)
reg                    [DATA_WIDTH-1:0] r_s1,r_s2                  ;

assign    o_signal    =    r_s2;

always@(posedge i_clk_fast)begin
    r_s1    <=    i_signal;
    r_s2    <=    r_s1;
end

endmodule
// ********************************************************************************** // 
//---------------------------------------------------------------------
// ˫�˿��첽FIFOģ��
//---------------------------------------------------------------------
module double_port_ram
#(
    parameter                           integer DATA_WIDTH=8       ,
    parameter                           integer ADDR_WIDTH=16      ,
    parameter                           integer RAM_DATA_WIDTH=256  
)
(
    input                               wr_clk_i                   ,
    input                               wr_en_i                    ,
    input              [ADDR_WIDTH-1:0] wr_addr_i                  ,
    input              [DATA_WIDTH-1:0] wr_data_i                  ,
	
    input                               rd_clk_i                   ,
    input                               rd_en_i                    ,
    input              [ADDR_WIDTH-1:0] rd_addr_i                  ,
    output reg         [DATA_WIDTH-1:0] rd_data_o                   
);
localparam                              integer RAM_NUM = 1 << ADDR_WIDTH;

reg                    [RAM_DATA_WIDTH-1:0]	ram[RAM_NUM-1:0]                           ;
always@(posedge wr_clk_i)begin
    if(wr_en_i)
        ram[wr_addr_i][DATA_WIDTH-1:0]=wr_data_i;
    else
        ram[wr_addr_i][DATA_WIDTH-1:0]<=ram[wr_addr_i];
end

always@(negedge rd_clk_i)begin
    if(rd_en_i)
        rd_data_o=ram[rd_addr_i][DATA_WIDTH-1:0];
    else
        rd_data_o='hx;
end

endmodule