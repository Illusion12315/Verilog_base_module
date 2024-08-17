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
    input  wire                         sys_clk_i                  ,// vga ʱ��
    input  wire                         rst_n_i                    ,// vga ��λ

    input  wire        [  15: 0]        pix_data_i                 ,

    output wire        [  11: 0]        pix_x_o                    ,// ���ص�x����
    output wire        [  11: 0]        pix_y_o                    ,// ���ص�y����

    output wire                         hsync_o                    ,
    output wire                         vsync_o                    ,
    output wire        [  15: 0]        rgb_o                       
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// declaration
//---------------------------------------------------------------------
    localparam                          H_Sync_Time               = 44    ;// ��ͬ��
    localparam                          H_Back_Porch              = 148   ;// ��ʱ�����
    localparam                          H_Left_Border             = 0     ;// ��ʱ����߿�
    localparam                          H_Addr_Time               = 1920  ;// ����Ч����
    localparam                          H_Right_Border            = 0     ;// ��ʱ���ұ߿�  
    localparam                          H_Front_Porch             = 88    ;// ��ʱ��ǰ��
    localparam                          H_Total_Time              = 2200  ;// ��ɨ������

    localparam                          V_Sync_Time               = 5     ;// ��ͬ��
    localparam                          V_Back_Porch              = 36    ;// ��ʱ�����
    localparam                          V_Top_Border              = 0     ;// ��ʱ���ϱ߿�
    localparam                          V_Addr_Time               = 1080  ;// ����Ч����
    localparam                          V_Bottom_Border           = 0     ;// ��ʱ���±߿�
    localparam                          V_Front_Porch             = 4     ;// ��ʱ��ǰ��
    localparam                          V_Total_Time              = 1125  ;// ��ɨ������

    wire                                rgb_valid                  ;
    wire                                rgb_req                    ;

    reg                [  11: 0]        cnt_h                      ;
    reg                [  11: 0]        cnt_v                      ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// main code
//---------------------------------------------------------------------
// cnt_h:��ͬ���źż�����
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
// hsync:��ͬ���ź�
    assign                              hsync_o                   = (cnt_h <= H_Sync_Time - 'd1) ? 'd1 : 'd0;
// cnt_v:��ͬ���źż�����
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
// vsync:��ͬ���ź�
    assign                              vsync_o                   = (cnt_v <= V_Sync_Time - 'd1) ? 'd1 : 'd0;
// rgb_valid:VGA ��Ч��ʾ����
    assign rgb_valid = (cnt_h >= H_Sync_Time + H_Back_Porch + H_Left_Border)
                    && (cnt_h < H_Sync_Time + H_Back_Porch + H_Left_Border + H_Addr_Time)
                    && (cnt_v >= V_Sync_Time + V_Back_Porch + V_Top_Border)
                    && (cnt_v < V_Sync_Time + V_Back_Porch + V_Top_Border + V_Addr_Time);

// rgb_req:���ص�ɫ����Ϣ�����ź�,��ǰ rgb_valid �ź�һ��ʱ������
    assign rgb_req = (cnt_h >= H_Sync_Time + H_Back_Porch + H_Left_Border - 1)
                    && (cnt_h < H_Sync_Time + H_Back_Porch + H_Left_Border + H_Addr_Time - 1)
                    && (cnt_v >= V_Sync_Time + V_Back_Porch + V_Top_Border)
                    && (cnt_v < V_Sync_Time + V_Back_Porch + V_Top_Border + V_Addr_Time);
// pix_x,pix_y:VGA ��Ч��ʾ�������ص�����
    assign                              pix_x_o                   = (rgb_req) ? cnt_h - H_Sync_Time - H_Back_Porch - H_Left_Border + 1 : 12'hfff;
 
    assign                              pix_y_o                   = (rgb_req) ? cnt_v - V_Sync_Time - V_Back_Porch - V_Top_Border : 12'hfff;
// rgb:������ص�ɫ����Ϣ
    assign                              rgb_o                     = (rgb_valid) ? pix_data_i : 'd0;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// debug
//---------------------------------------------------------------------



endmodule

`default_nettype wire