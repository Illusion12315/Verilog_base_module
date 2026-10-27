`timescale 1ns / 1ps
//****************************************VSCODE PLUG-IN**********************************//
//----------------------------------------------------------------------------------------
// IDE :                   VSCODE plug-in 
// VSCODE plug-in version: Verilog-Hdl-Format-2.8.20240817
// VSCODE plug-in author : Jiang Percy
//----------------------------------------------------------------------------------------
//****************************************Copyright (c)***********************************//
// Copyright(C)            Xiaoxin2ciyuan
// All rights reserved     
// File name:              axis_arb_rr_tb.v
// Last modified Date:     2026/10/14 09:43:15
// Last Version:           V1.0
// Descriptions:           
//----------------------------------------------------------------------------------------
// Created by:             Chen Ambition
// Created date:           2026/10/14 09:43:15
// Version:                V1.0
// Descriptions:           
//                         
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module    axis_arb_rr_tb();
    parameter integer N             = 4;     // 输入通道数 (>=2)
    parameter integer DATA_W        = 8;     // TDATA 位宽 (bit)
    parameter integer USER_W        = 16;    // TUSER 位宽 (bit)
    parameter integer MAX_PKT_BYTES = 1038;  // 单包最大字节数 (仅用于深度检查/说明)
    parameter integer FIFO_DEPTH    = 2048;  // 每路 packet FIFO 字数, 需为 2 的幂
    parameter integer IN_REG        = 1;     // 1: 每路输入插入 skid buffer (推荐)
    parameter integer MUX_REG       = 1;     // 1: MUX 输出插入 skid buffer (推荐)
    parameter integer OUT_REG       = 1;     // 1: 输出插入 skid buffer (推荐)
    reg                                        clk                        ;
    reg                                        rstn                       ;
    reg                       [N-1:0]          s_axis_tvalid              ;
    wire                      [N-1:0]          s_axis_tready              ;
    reg                       [N*DATA_W-1:0]   s_axis_tdata               ;
    reg                       [N*USER_W-1:0]   s_axis_tuser               ;
    reg                       [N-1:0]          s_axis_tlast               ;
    wire                                       m_axis_tvalid              ;
    reg                                        m_axis_tready              ;
    wire                      [DATA_W-1:0]     m_axis_tdata               ;
    wire                      [USER_W-1:0]     m_axis_tuser               ;
    wire                                       m_axis_tlast               ;

    reg                [  31: 0]    cnt                 ;

    initial
        begin
            #2                                             
                    rstn = 0   ;                          
                    clk = 0     ;                        
                    s_axis_tvalid = 0;
                    s_axis_tdata = 0;
                    s_axis_tuser = 0;
                    s_axis_tlast = 0;
                    m_axis_tready = 1;
            #10                                            
                    rstn = 1   ;
            
        end                                                
                                                           
    parameter   CLK_FREQ = 100;//Mhz                       
    always # ( 1000/CLK_FREQ/2 ) clk = ~clk ;              

always@(posedge clk or negedge rstn)begin
    if (!rstn) begin
        s_axis_tvalid[0] <= 'd0;
    end
    else if (cnt>=1000 && cnt <= 2037) begin
        s_axis_tvalid[0] <= 'd1;
    end
    else if (cnt>=2040 && cnt <= 3077) begin
        s_axis_tvalid[0] <= 'd1;
    end
    else begin
        s_axis_tvalid[0] <= 'd0;
    end
end       

always@(posedge clk or negedge rstn)begin
    if (!rstn) begin
        s_axis_tlast[0] <= 'd0;
    end
    else if (cnt == 2036) begin
        s_axis_tlast[0] <= 'd1;
    end
    else if (cnt == 3076) begin
        s_axis_tlast[0] <= 'd1;
    end
    else begin
        s_axis_tlast[0] <= 'd0;
    end
end

always@(posedge clk or negedge rstn)begin
    if (!rstn) begin
        s_axis_tdata[7:0] <= 'd0;
    end
    else if (s_axis_tvalid[0] && s_axis_tready[0]) begin
        s_axis_tdata[7:0] <= s_axis_tdata[7:0] + 'd1;
    end
end
    
always@(posedge clk or negedge rstn)begin
    if (!rstn) begin
        cnt <= 'd0;
    end
    else if (cnt == 10000 -1) begin
        cnt <= 'd0;
    end
    else begin
        cnt <= cnt + 'd1;
    end
end
                                                           
axis_arb_rr u_axis_arb_rr(
    .clk                                (clk                       ),
    .rstn                               (rstn                      ),
    // ------------------------------------------------------------------
    // 从机侧 : N 路 AXI4-Stream 输入 (数组式)
    //   s_axis_tdata[i*DATA_W +: DATA_W]  对应第 i 路
    //   s_axis_tuser[i*USER_W +: USER_W]  对应第 i 路
    // ------------------------------------------------------------------
    .s_axis_tvalid                      (s_axis_tvalid             ),
    .s_axis_tready                      (s_axis_tready             ),
    .s_axis_tdata                       (s_axis_tdata              ),
    .s_axis_tuser                       (s_axis_tuser              ),
    .s_axis_tlast                       (s_axis_tlast              ),
    // ------------------------------------------------------------------
    // 主机侧 : 1 路 AXI4-Stream 输出
    // ------------------------------------------------------------------
    .m_axis_tvalid                      (m_axis_tvalid             ),
    .m_axis_tready                      (m_axis_tready             ),
    .m_axis_tdata                       (m_axis_tdata              ),
    .m_axis_tuser                       (m_axis_tuser              ),
    .m_axis_tlast                       (m_axis_tlast              )
);




endmodule                                                  