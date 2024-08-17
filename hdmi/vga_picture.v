`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             vga_picture
// Create Date:           2024/08/11 22:07:30
// Version:               V1.0
// PATH:                  E:\FPGA\module_base\hdmi\vga_picture.v
// Descriptions:          
// 
// ********************************************************************************** // 
`default_nettype none


module vga_picture #(
    parameter                           DISPLAY_MODE              = 1     
) (
    input  wire                         sys_clk_i                  ,// vga 时钟
    input  wire                         rst_n_i                    ,// vga 复位

    output reg         [  15: 0]        pix_data_o                 ,

    input  wire        [  11: 0]        pix_x_i                    ,// 像素点x坐标
    input  wire        [  11: 0]        pix_y_i                     // 像素点y坐标
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// declarations
//---------------------------------------------------------------------
    localparam                          RED                       = 16'hF800;// 红色
    localparam                          ORANGE                    = 16'hFC00;// 橙色
    localparam                          YELLOW                    = 16'hFFE0;// 黄色
    localparam                          GREEN                     = 16'h07E0;// 绿色
    localparam                          CYAN                      = 16'h07FF;// 青色
    localparam                          BLUE                      = 16'h001F;// 蓝色
    localparam                          PURPPLE                   = 16'hF81F;// 紫色
    localparam                          BLACK                     = 16'h0000;// 黑色
    localparam                          WHITE                     = 16'hFFFF;// 白色
    localparam                          GRAY                      = 16'hD69A;// 灰色

    localparam                          H_VALID                   = 1920  ; // 行有效数据
    localparam                          V_VALID                   = 1080  ; // 场有效数据

// pix_data_o:输出像素点色彩信息,根据当前像素点坐标指定当前像素点颜色数据
always@(posedge sys_clk_i)
    if(!rst_n_i)
        pix_data_o <= 16'd0;
    else if((pix_x_i >= 0) && (pix_x_i < (H_VALID/10)*1))
        pix_data_o <= RED;
    else if((pix_x_i >= (H_VALID/10)*1) && (pix_x_i < (H_VALID/10)*2))
        pix_data_o <= ORANGE;
    else if((pix_x_i >= (H_VALID/10)*2) && (pix_x_i < (H_VALID/10)*3))
        pix_data_o <= YELLOW;
    else if((pix_x_i >= (H_VALID/10)*3) && (pix_x_i < (H_VALID/10)*4))
        pix_data_o <= GREEN;
    else if((pix_x_i >= (H_VALID/10)*4) && (pix_x_i < (H_VALID/10)*5))
        pix_data_o <= CYAN;
    else if((pix_x_i >= (H_VALID/10)*5) && (pix_x_i < (H_VALID/10)*6))
        pix_data_o <= BLUE;
    else if((pix_x_i >= (H_VALID/10)*6) && (pix_x_i < (H_VALID/10)*7))
        pix_data_o <= PURPPLE;
    else if((pix_x_i >= (H_VALID/10)*7) && (pix_x_i < (H_VALID/10)*8))
        pix_data_o <= BLACK;
    else if((pix_x_i >= (H_VALID/10)*8) && (pix_x_i < (H_VALID/10)*9))
        pix_data_o <= WHITE;
    else if((pix_x_i >= (H_VALID/10)*9) && (pix_x_i < H_VALID))
        pix_data_o <= GRAY;
    else
        pix_data_o <= BLACK;








endmodule


`default_nettype wire