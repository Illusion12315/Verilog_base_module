module iic_1byte_wr_or_rd #(
    parameter                           SOLID_ADDR	=	4'b1010        
  ) (
    input                               sys_clk_i                  ,// i2c 时钟的二倍
    input                               rst_n_i                    ,// 复位，地有效

    input              [   2:0]         device_addr_i              ,// 器件地址 
    input              [   7:0]         word_addr_i                ,

    input                               wr_start_flag_i            ,
    input              [   7:0]         wr_data_i                  ,

    input                               rd_start_flag_i            ,
    output reg         [   7:0]         rd_data_o                  ,

    output                              i2c_busy_o                 ,

    output reg                          scl_o                      ,
    input                               sda_i                      ,
    output reg                          sda_out_o                  ,
    output reg                          sda_en_o                    
  );
wire                   [   6:0]         device_addr                ;

reg                    [   1:0]         cnt_clk                    ;
reg                    [   2:0]         cnt_bit                    ;
reg                    [   3:0]         state                      ;
reg                                     wr_en                      ;
reg                                     rd_en                      ;
reg                    [   7:0]         r_rd_data                  ;
reg                                     ack_valid                  ;

localparam                              IDLE = 4'd0                ;//空闲
localparam                              START_1 = 4'd1             ;//开始1
localparam                              SEND_WR_D_ADDR = 4'd2      ;//写器件地址
localparam                              ACK_1 = 4'd3               ;//应答1
localparam                              SEND_WR_ADDR = 4'd4        ;//发写地址
localparam                              ACK_2 = 4'd5               ;//应答2
localparam                              WRITE_DATA = 4'd6          ;//写数据
localparam                              ACK_3 = 4'd7               ;//应答3
localparam                              STOP = 4'd8                ;//停止
localparam                              START_2 = 4'd9             ;//开始2
localparam                              SEND_RD_D_ADDR = 4'd10     ;//发读地址
localparam                              ACK_4 = 4'd11              ;//应答4
localparam                              RD_DATA = 4'd12            ;//读数据
localparam                              NO_ACK = 4'd13             ;//应答5

assign    i2c_busy_o    =    wr_en||rd_en;
assign    device_addr    =    {SOLID_ADDR,device_addr_i};
//如果是写标志，拉高写使能
always@(posedge sys_clk_i or negedge rst_n_i)
begin
  if(!rst_n_i)
    wr_en<='d0;
  else if(wr_start_flag_i)
    wr_en<='d1;
  else if(state==STOP&&cnt_clk=='d3&&cnt_bit=='d1)
    wr_en<='d0;
end
//如果是读标志，拉高读使能
always@(posedge sys_clk_i or negedge rst_n_i)
begin
  if(!rst_n_i)
    rd_en<='d0;
  else if(rd_start_flag_i)
    rd_en<='d1;
  else if(state==STOP&&cnt_clk=='d3&&cnt_bit=='d1)
    rd_en<='d0;
end
//计数器
always@(posedge sys_clk_i or negedge rst_n_i)
begin
  if(!rst_n_i)
    cnt_clk<='d0;
  else if(wr_start_flag_i||rd_start_flag_i)
    cnt_clk<=cnt_clk+'d1;
  else if(wr_en||rd_en)
    cnt_clk<=cnt_clk+'d1;
  else if(state==STOP&&cnt_clk=='d3&&cnt_bit=='d1)
    cnt_clk<='d0;
  else
    cnt_clk<=cnt_clk;
end
//bit计数器
always@(posedge sys_clk_i or negedge rst_n_i)
begin
  if(!rst_n_i)
    cnt_bit<='d0;
  else
  case(state)
    SEND_WR_D_ADDR,SEND_WR_ADDR,WRITE_DATA,SEND_RD_D_ADDR,RD_DATA:
      if(cnt_clk=='d3)
        cnt_bit<=cnt_bit+'d1;
      else
        cnt_bit<=cnt_bit;
    STOP:
      if(cnt_clk=='d3&&cnt_bit=='d1)
        cnt_bit<='d0;
      else if(cnt_clk=='d3)
        cnt_bit<=cnt_bit+'d1;
      else
        cnt_bit<=cnt_bit;
    default:
      cnt_bit<=cnt_bit;
  endcase
end
//状态机
always@(posedge sys_clk_i or negedge rst_n_i)
begin
  if(!rst_n_i)
    state<=IDLE;
  else
  case(state)
    IDLE:
      if(wr_start_flag_i||rd_start_flag_i)
        state<=START_1;
      else
        state<=state;
    START_1:
      if(cnt_clk=='d3)
        state<=SEND_WR_D_ADDR;
      else
        state<=state;
    SEND_WR_D_ADDR:
      if(cnt_bit=='d7&&cnt_clk=='d3)
        state<=ACK_1;
      else
        state<=state;
    ACK_1:
      if(cnt_clk=='d3&&ack_valid=='d0)
        state<=SEND_WR_ADDR;
      else
        state<=state;
    SEND_WR_ADDR:
      if(cnt_bit=='d7&&cnt_clk=='d3)
        state<=ACK_2;
      else
        state<=state;
    ACK_2:
      if(cnt_clk=='d3&&ack_valid=='d0&&wr_en)
        state<=WRITE_DATA;
      else if(cnt_clk=='d3&&ack_valid=='d0&&rd_en)
        state<=START_2;
      else
        state<=state;
    //写地址
    WRITE_DATA:
      if(cnt_bit=='d7&&cnt_clk=='d3)
        state<=ACK_3;
      else
        state<=state;
    ACK_3:
      if(cnt_clk=='d3&&ack_valid=='d0)
        state<=STOP;
      else
        state<=state;
    STOP:
      if(cnt_bit=='d1&&cnt_clk=='d3)
        state<=IDLE;
      else
        state<=state;
    //读
    START_2:
      if(cnt_clk=='d3)
        state<=SEND_RD_D_ADDR;
      else
        state<=state;
    SEND_RD_D_ADDR:
      if(cnt_bit=='d7&&cnt_clk=='d3)
        state<=ACK_4;
      else
        state<=state;
    ACK_4:
      if(cnt_clk=='d3&&ack_valid=='d0)
        state<=RD_DATA;
      else
        state<=state;
    RD_DATA:
      if(cnt_bit=='d7&&cnt_clk=='d3)
        state<=NO_ACK;
      else
        state<=state;
    NO_ACK:
      if(cnt_clk=='d3)
        state<=STOP;
      else
        state<=state;
    default:
      state<=IDLE;
  endcase
end
//三态门开关
always@(*)
begin
  case(state)
    ACK_1,ACK_2,ACK_3,ACK_4,RD_DATA,NO_ACK:
      sda_en_o='d0;
    default:
      sda_en_o='d1;
  endcase
end
//ack_valid信号
always@(posedge sys_clk_i or negedge rst_n_i)
begin
  if(!rst_n_i)
    ack_valid<='d0;
  else
  case(state)
    ACK_1,ACK_2,ACK_3,ACK_4,NO_ACK:
      if(sda_i=='d0&&cnt_clk=='d1)
        ack_valid='d0;
      else
        ack_valid=ack_valid;
    default:
      ack_valid='d1;
  endcase
end
//输出SCL时钟
always@(*)
begin
  case(state)
    START_1,SEND_WR_D_ADDR,ACK_1,SEND_WR_ADDR,ACK_2,WRITE_DATA,ACK_3,
    START_2,SEND_RD_D_ADDR,ACK_4,RD_DATA,NO_ACK:
      if(cnt_clk=='d3||cnt_clk=='d0)
        scl_o='d0;
      else
        scl_o='d1;
    IDLE:
      scl_o='d1;
    STOP:
      if(cnt_clk=='d0&&cnt_bit=='d0)
        scl_o='d0;
      else
        scl_o='d1;
    default:
      scl_o='d1;
  endcase
end
//输出SDA数据
always@(*)
begin
  case(state)
    START_1:
      sda_out_o<='d0;
    SEND_WR_D_ADDR:
    begin
      if(cnt_bit<='d6)
        sda_out_o<=device_addr[6-cnt_bit];
      else
        sda_out_o<='d0;
    end
    SEND_WR_ADDR:
      sda_out_o<=word_addr_i[7-cnt_bit];
    WRITE_DATA:
      sda_out_o<=wr_data_i[7-cnt_bit];
    START_2:
    begin
      if(cnt_clk=='d2||cnt_clk=='d3)
        sda_out_o<='d0;
      else
        sda_out_o<='d1;
    end
    SEND_RD_D_ADDR:
    begin
      if(cnt_bit<='d6)
        sda_out_o<=device_addr[6-cnt_bit];
      else
        sda_out_o<='d1;
    end
    ACK_1,ACK_2,ACK_3,ACK_4,NO_ACK:
      sda_out_o<='d0;
    RD_DATA:
      sda_out_o<='d0;
    STOP:
      if(cnt_bit=='d0)
        sda_out_o<='d0;
      else
        sda_out_o<='d1;
    default:
      sda_out_o<='d1;
  endcase
end
//记录读出的数据
always@(posedge sys_clk_i or negedge rst_n_i)
begin
  if(!rst_n_i)
    r_rd_data<='d0;
  else if(state==RD_DATA&&cnt_clk=='d1)
    r_rd_data[7-cnt_bit]<=sda_i;
  else
    r_rd_data<=r_rd_data;
end
//输出读出的数据
always@(posedge sys_clk_i or negedge rst_n_i)
begin
  if(!rst_n_i)
    rd_data_o<='d0;
  else if(state==STOP)
    rd_data_o<=r_rd_data;
  else
    rd_data_o<=rd_data_o;
end
endmodule

/*
iic_1byte_wr_or_rd # (
    .SOLID_ADDR                        (SOLID_ADDR                ) 
  )
  iic_1byte_wr_or_rd_inst (
    .sys_clk_i                         (sys_clk_i                 ),
    .rst_n_i                           (rst_n_i                   ),

    .device_addr_i                     (device_addr_i             ),
    .word_addr_i                       (word_addr_i               ),

    .wr_start_flag_i                   (wr_start_flag_i           ),
    .wr_data_i                         (wr_data_i                 ),

    .rd_start_flag_i                   (rd_start_flag_i           ),
    .rd_data_o                         (rd_data_o                 ),

    .i2c_busy_o                        (i2c_busy_o                ),
    
    .scl_o                             (scl_o                     ),
    .sda_i                             (sda_i                     ),
    .sda_out_o                         (sda_out_o                 ),
    .sda_en_o                          (sda_en_o                  ) 
  );
*/