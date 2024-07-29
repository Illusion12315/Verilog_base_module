`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             ad7656_rd_driver
// Create Date:           2024/05/30 23:12:59
// Version:               V1.0
// PATH:                  E:\FPGA\module_base\AD7656\ad7656_rd_driver.v
// Descriptions:          
// 
// ********************************************************************************** // 
`timescale 1ns / 1ps

module ad7656_rd_driver (
    input                               sys_clk_i                  ,// clk100m
    input                               rst_n_i                    ,
    // 开始标志
    input                               start_flag_i               ,// 单周期信号
    // 
    output reg                          convst_A_o                 ,
    output reg                          convst_B_o                 ,
    output reg                          convst_C_o                 ,

    input                               BUSY_i                     ,

    output reg                          cs_n_o                     ,
    output reg                          rd_n_o                     ,
    output                              adc_reset                  ,

    input              [  15: 0]        DB_i                       ,

    output reg         [  15: 0]        ch1_data_o                 ,
    output reg         [  15: 0]        ch2_data_o                 ,
    output reg         [  15: 0]        ch3_data_o                 ,
    output reg         [  15: 0]        ch4_data_o                 ,
    output reg         [  15: 0]        ch5_data_o                 ,
    output reg         [  15: 0]        ch6_data_o                 ,

    output                              convst_done_o               // 完成信号, 拉高一周期
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// declaration
//---------------------------------------------------------------------
    localparam                          IDLE                      = 0     ;
    localparam                          CONVST                    = 1     ;
    localparam                          CS_N                      = 2     ;
    localparam                          READ                      = 3     ;
    localparam                          WAIT                      = 4     ;
    localparam                          DONE                      = 5     ;
    localparam                          time_4us                  = 400   ;

    reg                [   2: 0]        cur_state                  ;
    reg                                 busy_r1,busy_r2            ;
    reg                [   3: 0]        period_cnt                 ;
    reg                [   2: 0]        data_cnt                   ;
    reg                [  19: 0]        clk_cnt                    ;

    assign                              adc_reset                 = ~rst_n_i;

    assign                              convst_done_o             = (cur_state == DONE) && (period_cnt == 'd7);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// main code
//---------------------------------------------------------------------
// 状态机
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cur_state <= IDLE;
    else case(cur_state)
        IDLE:
            if(start_flag_i)
                cur_state <= CONVST;
            else
                cur_state <= IDLE;
        CONVST:
            if(clk_cnt >= time_4us - 1)
                cur_state <= IDLE;
            else if(~busy_r1 && busy_r2)
                cur_state <= CS_N;
            else
                cur_state <= CONVST;
        CS_N:
            if(period_cnt == 'd5)
                cur_state <= READ;
            else
                cur_state <= CS_N;
        READ:
            if(data_cnt == 'd6 && period_cnt == 'd0)
                cur_state <= WAIT;
            else
                cur_state <= READ;
        WAIT:
            if(data_cnt == 'd2 && period_cnt == 'd4)
                cur_state <= DONE;
            else
                cur_state <= WAIT;
        DONE:
            if(period_cnt == 'd7)
                cur_state <= IDLE;
            else
                cur_state <= DONE;
        default: cur_state <= IDLE;
    endcase
end
always@(posedge sys_clk_i)begin
    case (cur_state)
        CONVST: clk_cnt <= clk_cnt + 'd1;
        default: clk_cnt <= 'd0;
    endcase
end
// 打个拍
always@(posedge sys_clk_i)begin
    busy_r1 <= BUSY_i;
    busy_r2 <= busy_r1;
end
// 转换
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i) begin
        convst_A_o <= 'd1;
        convst_B_o <= 'd1;
        convst_C_o <= 'd1;
    end
    else case (cur_state)
        IDLE,DONE,READ,WAIT: begin
            convst_A_o <= 'd0;
            convst_B_o <= 'd0;
            convst_C_o <= 'd0;
        end
        default: begin
            convst_A_o <= 'd1;
            convst_B_o <= 'd1;
            convst_C_o <= 'd1;
        end
    endcase
end
// 读状态时钟计数器
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        period_cnt <= 'd0;
    else case (cur_state)
        CS_N:
            if(period_cnt == 'd5)
                period_cnt <= 'd0;
            else
                period_cnt <= period_cnt + 'd1;
        READ,WAIT,DONE:
            if(period_cnt == 'd11)
                period_cnt <= 'd0;
            else
                period_cnt <= period_cnt + 'd1;
        default: period_cnt <= 'd0;
    endcase
end
// 读状态数据计数器
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        data_cnt <= 'd0;
    else case (cur_state)
        READ:
            if(data_cnt == 'd6 && period_cnt == 'd10)
                data_cnt <= 'd0;
            else if(period_cnt == 'd10)
                data_cnt <= data_cnt + 'd1;
            else
                data_cnt <= data_cnt;
        WAIT:
            if(period_cnt == 'd2)
                data_cnt <= data_cnt + 'd1;
            else
                data_cnt <= data_cnt;
        default: data_cnt <= 'd0;
    endcase
end
// cs_n
always@(posedge sys_clk_i)begin
    case (cur_state)
        CS_N,READ: cs_n_o <= 'd0;
        default: cs_n_o <= 'd1;
    endcase
end
// rd_n
always@(posedge sys_clk_i)begin
    case (cur_state)
        READ:
            case (period_cnt)
                2,3,4,5,6,7,8,9,10: rd_n_o <= 'd0;
                default: rd_n_o <= 'd1;
            endcase
        default: rd_n_o <= 'd1;
    endcase
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)begin
        ch1_data_o <= 'd0;
        ch2_data_o <= 'd0;
        ch3_data_o <= 'd0;
        ch4_data_o <= 'd0;
        ch5_data_o <= 'd0;
        ch6_data_o <= 'd0;
    end
    else case (cur_state)
        READ: if (period_cnt == 'd10) begin
            case (data_cnt)
                0: ch1_data_o <= DB_i;
                1: ch2_data_o <= DB_i;
                2: ch3_data_o <= DB_i;
                3: ch4_data_o <= DB_i;
                4: ch5_data_o <= DB_i;
                5: ch6_data_o <= DB_i;
                default: begin
                    ch1_data_o <= ch1_data_o;
                    ch2_data_o <= ch2_data_o;
                    ch3_data_o <= ch3_data_o;
                    ch4_data_o <= ch4_data_o;
                    ch5_data_o <= ch5_data_o;
                    ch6_data_o <= ch6_data_o;
                end
            endcase
        end
        else begin
            ch1_data_o <= ch1_data_o;
            ch2_data_o <= ch2_data_o;
            ch3_data_o <= ch3_data_o;
            ch4_data_o <= ch4_data_o;
            ch5_data_o <= ch5_data_o;
            ch6_data_o <= ch6_data_o;
        end
        default: begin
            ch1_data_o <= ch1_data_o;
            ch2_data_o <= ch2_data_o;
            ch3_data_o <= ch3_data_o;
            ch4_data_o <= ch4_data_o;
            ch5_data_o <= ch5_data_o;
            ch6_data_o <= ch6_data_o;
        end
    endcase
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// debug
//---------------------------------------------------------------------
ila_ad7656_rd_driver ila_ad7656_rd_driver_inst (
    .clk                                (sys_clk_i                 ),// input wire clk

    .probe0                             (start_flag_i              ),// input wire [0:0]  probe0  
    .probe1                             (cur_state                 ),// input wire [2:0]  probe1 
    .probe2                             (busy_r2                   ),// input wire [0:0]  probe2 
    .probe3                             (period_cnt                ),// input wire [3:0]  probe3 
    .probe4                             (data_cnt                  ),// input wire [2:0]  probe4 
    .probe5                             (convst_A_o                ),// input wire [0:0]  probe5 
    .probe6                             (cs_n_o                    ),// input wire [0:0]  probe6 
    .probe7                             (rd_n_o                    ),// input wire [0:0]  probe7 
    .probe8                             (DB_i                      ),// input wire [15:0]  probe8 
    .probe9                             (ch1_data_o                ),// input wire [15:0]  probe9 
    .probe10                            (ch2_data_o                ),// input wire [15:0]  probe10 
    .probe11                            (ch3_data_o                ),// input wire [15:0]  probe11 
    .probe12                            (ch4_data_o                ),// input wire [15:0]  probe12 
    .probe13                            (ch5_data_o                ),// input wire [15:0]  probe13 
    .probe14                            (ch6_data_o                ),// input wire [15:0]  probe14 
    .probe15                            (convst_done_o             ) // input wire [0:0]  probe15
);

endmodule