`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             hdmi_driver
// Create Date:           2024/08/11 21:45:32
// Version:               V1.0
// PATH:                  E:\FPGA\module_base\hdmi\hdmi_driver.v
// Descriptions:          
// 
// ********************************************************************************** // 
`default_nettype none


module hdmi_driver #(
    parameter                           DISPLAY_MODE              = 1     
) (
    input  wire                         sys_clk_i                  ,// vga 时钟
    input  wire                         rst_n_i                    ,// vga 复位

    input  wire        [  15: 0]        pix_data_i                 ,

    output wire        [  11: 0]        pix_x_o                    ,// 像素点x坐标
    output wire        [  11: 0]        pix_y_o                    ,// 像素点y坐标

    output wire                         hsync_o                    ,
    output wire                         vsync_o                    ,
    output wire        [  15: 0]        rgb_o                       
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// declaration
//---------------------------------------------------------------------
    localparam                          H_Sync_Time               = 44    ;// 行同步
    localparam                          H_Back_Porch              = 148   ;// 行时序后沿
    localparam                          H_Left_Border             = 0     ;// 行时序左边框
    localparam                          H_Addr_Time               = 1920  ;// 行有效数据
    localparam                          H_Right_Border            = 0     ;// 行时序右边框  
    localparam                          H_Front_Porch             = 88    ;// 行时序前沿
    localparam                          H_Total_Time              = 2200  ;// 行扫描周期

    localparam                          V_Sync_Time               = 5     ;// 场同步
    localparam                          V_Back_Porch              = 36    ;// 场时序后沿
    localparam                          V_Top_Border              = 0     ;// 场时序上边框
    localparam                          V_Addr_Time               = 1080  ;// 场有效数据
    localparam                          V_Bottom_Border           = 0     ;// 场时序下边框
    localparam                          V_Front_Porch             = 4     ;// 场时序前沿
    localparam                          V_Total_Time              = 1125  ;// 场扫描周期

    wire                                rgb_valid                  ;
    wire                                rgb_req                    ;

    reg                [  11: 0]        cnt_h                      ;
    reg                [  11: 0]        cnt_v                      ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// main code
//---------------------------------------------------------------------
// cnt_h:行同步信号计数器
always@(posedge sys_clk_i)begin
    if (!rst_n_i) begin
        cnt_h <= 'd0;
    end
    else if (cnt_h == H_Total_Time - 1) begin
        cnt_h <= 'd0;
    end
    else begin
        cnt_h <= cnt_h + 'd1;
    end
end
// hsync:行同步信号
    assign                              hsync_o                   = (cnt_h <= H_Sync_Time - 'd1) ? 'd1 : 'd0;
// cnt_v:场同步信号计数器
always@(posedge sys_clk_i)begin
    if (!rst_n_i) begin
        cnt_v <= 'd0;
    end
    else if ((cnt_v == V_Total_Time - 'd1) && (cnt_h == H_Total_Time - 'd1)) begin
        cnt_v <= 'd0;
    end
    else if (cnt_h == H_Total_Time - 'd1) begin
        cnt_v <= cnt_v + 'd1;
    end
    else begin
        cnt_v <= cnt_v;
    end
end
// vsync:场同步信号
    assign                              vsync_o                   = (cnt_v <= V_Sync_Time - 'd1) ? 'd1 : 'd0;
// rgb_valid:VGA 有效显示区域
    assign rgb_valid = (cnt_h >= H_Sync_Time + H_Back_Porch + H_Left_Border)
                    && (cnt_h < H_Sync_Time + H_Back_Porch + H_Left_Border + H_Addr_Time)
                    && (cnt_v >= V_Sync_Time + V_Back_Porch + V_Top_Border)
                    && (cnt_v < V_Sync_Time + V_Back_Porch + V_Top_Border + V_Addr_Time);

// rgb_req:像素点色彩信息请求信号,超前 rgb_valid 信号一个时钟周期
    assign rgb_req = (cnt_h >= H_Sync_Time + H_Back_Porch + H_Left_Border - 1)
                    && (cnt_h < H_Sync_Time + H_Back_Porch + H_Left_Border + H_Addr_Time - 1)
                    && (cnt_v >= V_Sync_Time + V_Back_Porch + V_Top_Border)
                    && (cnt_v < V_Sync_Time + V_Back_Porch + V_Top_Border + V_Addr_Time);
// pix_x,pix_y:VGA 有效显示区域像素点坐标
    assign                              pix_x_o                   = (rgb_req) ? cnt_h - H_Sync_Time - H_Back_Porch - H_Left_Border + 1 : 12'hfff;
 
    assign                              pix_y_o                   = (rgb_req) ? cnt_v - V_Sync_Time - V_Back_Porch - V_Top_Border : 12'hfff;
// rgb:输出像素点色彩信息
    assign                              rgb_o                     = (rgb_valid) ? pix_data_i : 'd0;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// debug
//---------------------------------------------------------------------



endmodule

`default_nettype wire