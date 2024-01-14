

module ad7606_ctrl_logic (
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,
    //开始标志
    input                               start_flag_i               ,
    //ad7606配置接口
    output                              reset_o                    ,
    output                              convsta_o                  ,
    output                              convstb_o                  ,
    input                               busy_i                     ,

    input                               AD7606_FRSTDATA_1V8        ,
    //spi并行接口
    output                              cs_o                       ,
    output                              rd_o                       ,
    input              [  15:0]         ad_data_i                  ,
    //输出采集的数据
    output                              data_flag_o                ,//输出数据稳定有效信号
    output             [  15:0]         ch1_data                   ,//V1
    output             [  15:0]         ch2_data                   ,//V2
    output             [  15:0]         ch3_data                   ,//V3
    output             [  15:0]         ch4_data                   ,//V4
    output             [  15:0]         ch5_data                   ,//V5
    output             [  15:0]         ch6_data                   ,//V6
    output             [  15:0]         ch7_data                   ,//V7
    output             [  15:0]         ch8_data                    //V8
);

wire                                    spi_start_flag             ;
wire                                    start_flag                 ;
reg                                     start_flag_r1,start_flag_r2,start_flag_r3;
reg                    [   3:0]         cur_state                  ;
reg                    [   3:0]         next_state                 ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// localparam
//---------------------------------------------------------------------
localparam                              IDLE = 0                   ;
localparam                              RST1_N = 1                 ;
localparam                              RST2_N = 2                 ;
localparam                              CONVST_N0 = 3              ;
localparam                              CONVST_N = 4               ;
localparam                              WAIT_BUSY = 5              ;
localparam                              GATHER = 6                 ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// regs
//---------------------------------------------------------------------
always@(posedge sys_clk_i)begin
    start_flag_r1<=start_flag_i;
    start_flag_r2<=start_flag_r1;
    start_flag_r3<=start_flag_r2;
end

assign start_flag = start_flag_r2 & ~start_flag_r3 ;


//第一段,状态跳转,时序逻辑
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cur_state<=IDLE;
    else
        cur_state<=next_state;
end

//第二段,跳转条件,组合逻辑
always@(*)begin
    case(cur_state)
        IDLE:begin
            if (start_flag) begin
                next_state<=RST1_N;
            end
            else begin
                next_state<=IDLE;
            end
        end
        RST1_N:begin
            next_state<=RST2_N;
        end
        RST2_N:begin
            next_state<=CONVST_N0;
        end
        CONVST_N0:begin
            next_state<=CONVST_N;
        end
        CONVST_N:begin
            next_state<=WAIT_BUSY;
        end
        WAIT_BUSY:begin
            if (busy_i) begin
                next_state<=GATHER;
            end
            else
                next_state<=WAIT_BUSY;
        end
        GATHER:begin
            if (~busy_i) begin
                next_state<=IDLE;
            end
            else
                next_state<=GATHER;
        end
        default:next_state<=IDLE;
    endcase
end

//reset_o
 
reg                                     reset_r                    ;
assign reset_o = reset_r;
always@(*)begin
    case (next_state)
        RST1_N,RST2_N: reset_r <= 'd1;
        default: reset_r <= 'd0;
    endcase
end

//convsta_o，convstb_o
 
reg                                     convsta_r,convstb_r        ;
assign convsta_o = convsta_r;
assign convstb_o = convstb_r;
always@(*)begin
    case (next_state)
        CONVST_N: begin
            convsta_r<='d0;
            convstb_r<='d0;
        end
        default: begin
            convsta_r<='d1;
            convstb_r<='d1;
        end
    endcase
end

//SPI_START
reg                                     spi_start_r                ;
always@(*)begin
    case (next_state)
        GATHER: spi_start_r <= 'd0;
        default: spi_start_r <= 'd1;
    endcase
end
signle_pluse  signle_pluse_inst (
    .clk                               (sys_clk_i                 ),
    .signal_in                         (spi_start_r               ),
    .pluse_out                         (spi_start_flag            ) 
);

//spi_logic
ad9606_spi_logic  ad9606_spi_logic_inst (
    .sys_clk_i                         (sys_clk_i                 ),
    .rst_n_i                           (rst_n_i                   ),
    //开始读取信号
    .spi_start_flag_i                  (spi_start_flag            ),
    //spi并行接口
    .cs_o                              (cs_o                      ),
    .rd_o                              (rd_o                      ),
    .ad_data_i                         (ad_data_i                 ),
    //输出
    .data_flag_o                       (data_flag_o               ),
    .ch1_data                          (ch1_data                  ),
    .ch2_data                          (ch2_data                  ),
    .ch3_data                          (ch3_data                  ),
    .ch4_data                          (ch4_data                  ),
    .ch5_data                          (ch5_data                  ),
    .ch6_data                          (ch6_data                  ),
    .ch7_data                          (ch7_data                  ),
    .ch8_data                          (ch8_data                  ) 
  );

// ********************************************************************************** // 
//---------------------------------------------------------------------
// debug
//---------------------------------------------------------------------
ila_ch_data ila_ad_debug (
    .clk                               (sys_clk_i                 ),// input wire clk


    .probe0                            (start_flag                ),// input wire [0:0]  probe0  
    .probe1                            (reset_o                   ),// input wire [0:0]  probe1 
    .probe2                            (convsta_o                 ),// input wire [0:0]  probe2 
    .probe3                            (convstb_o                 ),// input wire [0:0]  probe3 
    .probe4                            (busy_i                    ),// input wire [0:0]  probe4 
    .probe5                            (cs_o                      ),// input wire [0:0]  probe5 
    .probe6                            (rd_o                      ),// input wire [0:0]  probe6 
    .probe7                            (ad_data_i                 ),// input wire [15:0]  probe7 
    .probe8                            (data_flag_o               ),// input wire [0:0]  probe8 
    .probe9                            (ch1_data                  ),// input wire [15:0]  probe9 
    .probe10                           (ch2_data                  ),// input wire [15:0]  probe10 
    .probe11                           (ch3_data                  ),// input wire [15:0]  probe11 
    .probe12                           (ch4_data                  ),// input wire [15:0]  probe12 
    .probe13                           (ch5_data                  ),// input wire [15:0]  probe13 
    .probe14                           (ch6_data                  ),// input wire [15:0]  probe14 
    .probe15                           (ch7_data                  ),// input wire [15:0]  probe15 
    .probe16                           (ch8_data                  ),// input wire [15:0]  probe16 
    .probe17                           (AD7606_FRSTDATA_1V8       ) // input wire [0:0]  probe17
);
endmodule