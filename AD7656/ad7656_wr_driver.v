`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             ad7656_wr_driver
// Create Date:           2024/05/30 23:13:32
// Version:               V1.0
// PATH:                  E:\FPGA\module_base\AD7656\ad7656_wr_driver.v
// Descriptions:          
// 
// ********************************************************************************** // 


module ad7656_wr_driver (
    input                               sys_clk_i                  ,// clk100m
    input                               rst_n_i                    ,
    // 开始标志
    input                               wr_flag_i                  ,// 单周期信号
    input              [   7: 0]        wr_data_i                  ,
    output                              bus_busy_o                 ,

    output reg                          wr_n_o                     ,
    output reg                          cs_n_o                     ,

    output             [  15: 0]        DB_o                        
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// declarations
//---------------------------------------------------------------------
    localparam                          IDLE                      = 0     ;
    localparam                          WRITE                     = 1     ;

    reg                [   0: 0]        next_state                 ;
    reg                [   0: 0]        cur_state                  ;
    reg                [   1: 0]        period_cnt                 ;

    reg                [   7: 0]        data_out                   ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// logic
//---------------------------------------------------------------------
// 第一段,状态跳转,时序逻辑
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cur_state <= IDLE;
    else
        cur_state <= next_state;
end

// 第二段,跳转条件,组合逻辑
always@(*)begin
    case(cur_state)
        IDLE:
            if(wr_flag_i)
                next_state <= WRITE;
            else
                next_state <= IDLE;
        WRITE:
            if(period_cnt == 'd3)
                next_state <= IDLE;
            else
                next_state <= WRITE;
        default:next_state <= IDLE;
    endcase
end

always@(posedge sys_clk_i)begin
    case (cur_state)
        WRITE: period_cnt <= period_cnt + 'd1;
        default: period_cnt <= 'd0;
    endcase
end

always@(posedge sys_clk_i)begin
    case (cur_state)
        WRITE: cs_n_o <= 'd0;
        default: cs_n_o <= 'd1;
    endcase
end

always@(posedge sys_clk_i)begin
    case (cur_state)
        WRITE:
            case (period_cnt)
                1,2: wr_n_o <= 'd0;
                default: wr_n_o <= 'd1;
            endcase
        default: wr_n_o <= 'd1;
    endcase
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        data_out <= 'd0;
    else if(wr_flag_i)
        data_out <= wr_data_i;
end

    assign                              DB_o                      = {data_out,8'hff};

    assign                              bus_busy_o                = (cur_state == WRITE);
    
endmodule