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
// File name:              mean_filtering_tb.v
// Last modified Date:     2025/01/05 08:48:05
// Last Version:           V1.0
// Descriptions:           
//----------------------------------------------------------------------------------------
// Created by:             Chen Xiong Zhi
// Created date:           2025/01/05 08:48:05
// Version:                V1.0
// Descriptions:           
//                         
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module    mean_filtering_tb();
    parameter                           MEAN_FILTER_LENGTH        = 16    ;
    parameter                           S_AXI_DATA_WIDTH          = 16    ;
    reg                                 sys_clk_i                  ;
    reg                                 rst_n_i                    ;
    reg                                 s_axi_data_tvalid_i        ;
    reg                [S_AXI_DATA_WIDTH-1: 0]s_axi_data_tdata_i   ;
    wire                                m_axi_data_tvalid_o        ;
    wire               [S_AXI_DATA_WIDTH-1: 0]m_axi_data_tdata_o   ;



    initial
        begin
            #2
            rst_n_i = 0   ;
            sys_clk_i = 0     ;
            s_axi_data_tvalid_i = 0;
            s_axi_data_tdata_i = 0;
            #10
            rst_n_i = 1   ;
            #100
            set_data(1);
            set_data(15);
            set_data(2);
            set_data(10);
            set_data(14);
            set_data(13);
            set_data(3);
            set_data(8);
            set_data(9);
            set_data(4);
            set_data(11);
            set_data(5);
            set_data(12);
            set_data(6);
            set_data(7);
            set_data(16);
            @(posedge sys_clk_i)begin
                s_axi_data_tvalid_i = 1'b0;
            end
            
            set_data(16);
            set_data(15);
            set_data(1);
            set_data(2);
            set_data(10);
            set_data(14);
            set_data(13);
            set_data(3);
            set_data(8);
            set_data(9);
            set_data(4);
            set_data(11);
            set_data(5);
            set_data(12);
            set_data(6);
            set_data(7);
            @(posedge sys_clk_i)begin
                s_axi_data_tvalid_i = 1'b0;
            end
            
            set_data(1);
            set_data(15);
            set_data(2);
            set_data(10);
            set_data(14);
            set_data(13);
            set_data(3);
            set_data(8);
            set_data(9);
            set_data(4);
            set_data(11);
            set_data(16);
            set_data(5);
            set_data(12);
            set_data(6);
            set_data(7);
            @(posedge sys_clk_i)begin
                s_axi_data_tvalid_i = 1'b0;
            end
        end
                                                           
    parameter                           CLK_FREQ                  = 100   ;//Mhz                       
    always # ( 1000/CLK_FREQ/2 ) sys_clk_i = ~sys_clk_i ;
                                                           
                                                           
mean_filtering#(
    .MEAN_FILTER_LENGTH                 (MEAN_FILTER_LENGTH        ),
    .S_AXI_DATA_WIDTH                   (S_AXI_DATA_WIDTH          ) 
)
 u_mean_filtering(
    .sys_clk_i                          (sys_clk_i                 ),
    .rst_n_i                            (rst_n_i                   ),
    .s_axi_data_tvalid_i                (s_axi_data_tvalid_i       ),
    .s_axi_data_tdata_i                 (s_axi_data_tdata_i        ),
    .m_axi_data_tvalid_o                (m_axi_data_tvalid_o       ),
    .m_axi_data_tdata_o                 (m_axi_data_tdata_o        ) 
);

task set_data;
    input       signed [S_AXI_DATA_WIDTH-1: 0]data                 ;
    begin
        @(posedge sys_clk_i)begin
            s_axi_data_tvalid_i = 1'b1;
            s_axi_data_tdata_i = data;
        end
    end
endtask


endmodule