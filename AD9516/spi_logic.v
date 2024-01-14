//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: chenxiongzhi
// 
// Create Date: 2023/09/02 20:43:35
// Design Name: 
// Module Name: spi_logic
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module spi_logic
(
    //系统接口
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,
	//spi接口
    output reg                          SCLK_O                     ,//SPI时钟
    output reg                          CS_O                       ,//SPI片选
    output reg                          MOSI_O                     ,//SPI主发送，从接收
    input                               MISO_I                     ,//SPI从发送，主接收
	//控制接口
    input                               start_flag_i               ,//开始信号
    input              [  15:0]         control_data_i             ,//控制位寄存器值，16位
    input              [   7:0]         write_data_i               ,//寄存器值，8位
    output reg         [   7:0]         read_data_o                ,//读出的寄存器值，8位
    output                              spi_busy_o                  //系统繁忙信号    
);
wire                   [   2:0]         total_byte                 ;
	
reg                    [   7:0]         read_data_cache            ;
reg                                     cnt_clk                    ;
reg                    [   3:0]         cnt_bit                    ;
reg                    [   2:0]         cnt_byte                   ;
reg                    [   2:0]         state                      ;
	
localparam                              IDLE = 'd0                 ;
localparam                              START = 'd1                ;
localparam                              WRITE_COMMAND = 'd2        ;
localparam                              WRITE_DATA = 'd3           ;
localparam                              STOP = 'd4                 ;
localparam                              READ_DATA =	'd5            ;

assign spi_busy_o = ~CS_O;
assign total_byte = control_data_i[14:13]+'d1;
//时钟计数器
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cnt_clk<='d0;
    else case(state)
        START,WRITE_COMMAND,WRITE_DATA,STOP,READ_DATA:
            cnt_clk<=cnt_clk+'d1;
        default:
            cnt_clk<='d0;
    endcase
end
//比特计数器
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cnt_bit<='d0;
    else case(state)
        WRITE_COMMAND:
            if(cnt_clk=='d1)
                cnt_bit<=cnt_bit+'d1;
            else
                cnt_bit<=cnt_bit;
        WRITE_DATA,READ_DATA:
            if(cnt_clk=='d1&&cnt_bit=='d7)
                cnt_bit<='d0;
            else if(cnt_clk=='d1)
                cnt_bit<=cnt_bit+'d1;
            else
                cnt_bit<=cnt_bit;
        default:cnt_bit<='d0;
    endcase
end
//字节计数器
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cnt_byte<='d0;
    else if((state==WRITE_DATA||state==READ_DATA)&&cnt_clk=='d1&&cnt_bit=='d7&&cnt_byte==total_byte)
        cnt_byte<='d0;
    else if(state==WRITE_COMMAND&&cnt_clk=='d1&&cnt_bit=='d15)
        cnt_byte<=cnt_byte+'d1;
    else if((state==WRITE_DATA||state==READ_DATA)&&cnt_clk=='d1&&cnt_bit=='d7)
        cnt_byte<=cnt_byte+'d1;
    else
        cnt_byte<=cnt_byte;
end
//状态机
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        state<=IDLE;
    else case(state)
        IDLE:
            if(start_flag_i)
                state<=START;
            else
                state<=state;
        START:
            if(cnt_clk=='d1)
                state<=WRITE_COMMAND;
            else
                state<=state;
        WRITE_COMMAND:
            if(cnt_clk=='d1&&cnt_bit=='d15&&control_data_i[15]=='d0)
                state<=WRITE_DATA;
            else if(cnt_clk=='d1&&cnt_bit=='d15&&control_data_i[15]=='d1)
                state<=READ_DATA;
            else
                state<=state;
        WRITE_DATA:
            if(cnt_clk=='d1&&cnt_bit=='d7&&cnt_byte==total_byte)
                state<=STOP;
            else
                state<=state;
        STOP:
            if(cnt_clk=='d1)
                state<=IDLE;
            else
                state<=state;
        READ_DATA:
            if(cnt_clk=='d1&&cnt_bit=='d7&&cnt_byte==total_byte)
                state<=STOP;
            else
                state<=state;
    endcase
end
//配置片选
always@(*)begin
    case(state)
        IDLE:CS_O='d1;
        default:CS_O='d0;
    endcase
end
//配置SPI时钟，频率为系统时钟的1/2
always@(*)begin
    case(state)
        WRITE_COMMAND,WRITE_DATA,READ_DATA:
            if(cnt_clk=='d0)
                SCLK_O='d0;
            else
                SCLK_O='d1;
        default:SCLK_O='d0;
    endcase
end
//配置MOSI
always@(*)begin
    case(state)
        WRITE_COMMAND:
            MOSI_O=control_data_i[15-cnt_bit];
        WRITE_DATA:
            MOSI_O=write_data_i[7-cnt_bit];
        default:MOSI_O='d0;
    endcase
end
//读缓存
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        read_data_cache <= 'd0;
    else case(state)
        READ_DATA:
            read_data_cache[7-cnt_bit] <= MISO_I;
        default:read_data_cache <= read_data_cache;
    endcase
end
//读数据输出
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        read_data_o<='d0;
    else if(state==STOP)
        read_data_o<=read_data_cache;
    else
        read_data_o<=read_data_o;
end

endmodule
