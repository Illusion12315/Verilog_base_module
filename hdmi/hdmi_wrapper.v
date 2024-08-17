`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             hdmi_wrapper
// Create Date:           2024/08/11 22:12:02
// Version:               V1.0
// PATH:                  E:\FPGA\module_base\hdmi\hdmi_wrapper.v
// Descriptions:          
// 
// ********************************************************************************** // 
`default_nettype none


module hdmi_wrapper (
    input  wire                         sys_clk_i                  ,// vga 时钟
    input  wire                         rst_n_i                    ,// vga 复位

    output wire                         HDMI_CLK_P                 ,
    output wire                         HDMI_CLK_N                 ,
    output wire                         HDMI_D2_P                  ,
    output wire                         HDMI_D2_N                  ,
    output wire                         HDMI_D1_P                  ,
    output wire                         HDMI_D1_N                  ,
    output wire                         HDMI_D0_P                  ,
    output wire                         HDMI_D0_N                  ,
    output wire                         HDMI_CEC                   ,
    output wire                         HDMI_HPD                   ,
    output wire                         HDMI_OUT_EN                ,
    output wire                         HDMI_SCL                   ,
    inout  wire                         HDMI_SDA                    
);
    wire               [  15: 0]        pix_data                   ;
    wire               [  11: 0]        pix_x                      ;
    wire               [  11: 0]        pix_y                      ;
    wire                                hsync_o                    ;
    wire                                vsync_o                    ;
    wire               [  15: 0]        rgb_o                      ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// instances
//---------------------------------------------------------------------
hdmi_driver#(
    .DISPLAY_MODE                       (1                         ) 
)
u_hdmi_driver(
    .sys_clk_i                          (sys_clk_i                 ),// vga 时钟
    .rst_n_i                            (rst_n_i                   ),// vga 复位

    .pix_data_i                         (pix_data                  ),
    .pix_x_o                            (pix_x                     ),// 像素点x坐标
    .pix_y_o                            (pix_y                     ),// 像素点y坐标

    .hsync_o                            (hsync_o                   ),
    .vsync_o                            (vsync_o                   ),
    .rgb_o                              (rgb_o                     ) 
);

vga_picture#(
    .DISPLAY_MODE                       (1                         ) 
)
u_vga_picture(
    .sys_clk_i                          (sys_clk_i                 ),// vga 时钟
    .rst_n_i                            (rst_n_i                   ),// vga 复位

    .pix_data_o                         (pix_data                  ),
    .pix_x_i                            (pix_x                     ),// 像素点x坐标
    .pix_y_i                            (pix_y                     ) // 像素点y坐标
);



endmodule


`default_nettype wire