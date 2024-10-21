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
// File name:              aurora_8b10b_wrapper_tb.v
// Last modified Date:     2024/10/18 15:49:45
// Last Version:           V1.0
// Descriptions:           
//----------------------------------------------------------------------------------------
// Created by:             Chen Xiong Zhi
// Created date:           2024/10/18 15:49:45
// Version:                V1.0
// Descriptions:           
//                         
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module    aurora_8b10b_wrapper_tb();
    parameter                           SFP_CHANNEL               = 3     ;

    reg                                 init_clk_in                ;
    reg                                 reset                      ;
    reg                                 gt_reset                   ;
    wire               [SFP_CHANNEL-1: 0]user_clk_out              ;
    wire               [SFP_CHANNEL-1: 0]sys_reset_out             ;
    wire               [SFP_CHANNEL-1: 0]channel_up                ;
    wire               [SFP_CHANNEL-1: 0]lane_up                   ;
    reg                [SFP_CHANNEL*3-1: 0]loopback                ;
    wire               [SFP_CHANNEL*32-1: 0]s_axi_tx_tdata         ;
    wire               [SFP_CHANNEL*4-1: 0]s_axi_tx_tkeep          ;
    wire               [SFP_CHANNEL-1: 0]s_axi_tx_tlast            ;
    wire               [SFP_CHANNEL-1: 0]s_axi_tx_tvalid           ;
    wire               [SFP_CHANNEL-1: 0]s_axi_tx_tready           ;
    wire               [SFP_CHANNEL*32-1: 0]m_axi_rx_tdata         ;
    wire               [SFP_CHANNEL*4-1: 0]m_axi_rx_tkeep          ;
    wire               [SFP_CHANNEL-1: 0]m_axi_rx_tlast            ;
    wire               [SFP_CHANNEL-1: 0]m_axi_rx_tvalid           ;
    reg                                 gt_refclk1_p               ;
    reg                                 gt_refclk1_n               ;
    wire               [SFP_CHANNEL-1: 0]SFP_TXP                   ;
    wire               [SFP_CHANNEL-1: 0]SFP_TXN                   ;
    reg                [SFP_CHANNEL-1: 0]SFP_RXP                   ;
    reg                [SFP_CHANNEL-1: 0]SFP_RXN                   ;

    reg                                 start_en_i                 ;

initial
    begin
        #2
        reset = 1;
        gt_reset = 1;
        init_clk_in = 0;
        gt_refclk1_p = 0;
        gt_refclk1_n = 1;
        loopback = 0;
        start_en_i = 0;
        #100
        reset = 0;
        #1000
        gt_reset = 0;
        #1000
        start_en_i = 1;
    end
                                                           
    parameter                           CLK_FREQ                  = 100   ;//Mhz                       
    always # ( 1000/CLK_FREQ/2 ) init_clk_in = ~init_clk_in ;
                                                                     
    always # ( 6.4 ) gt_refclk1_p = ~gt_refclk1_p ;
    always # ( 6.4 ) gt_refclk1_n = ~gt_refclk1_n ;
                                                           
aurora_8b10b_wrapper#(
    .SFP_CHANNEL                        (SFP_CHANNEL               ) 
)
 u_aurora_8b10b_wrapper(
    .init_clk_in                        (init_clk_in               ),
    .reset                              (reset                     ),// #1000
    .gt_reset                           (gt_reset                  ),// #5000
    // user interface
    .user_clk_out                       (user_clk_out              ),
    .sys_reset_out                      (sys_reset_out             ),
    .channel_up                         (channel_up                ),
    .lane_up                            (lane_up                   ),
    .loopback                           (loopback                  ),

    .s_axi_tx_tdata                     (s_axi_tx_tdata            ),
    .s_axi_tx_tkeep                     (s_axi_tx_tkeep            ),
    .s_axi_tx_tlast                     (s_axi_tx_tlast            ),
    .s_axi_tx_tvalid                    (s_axi_tx_tvalid           ),
    .s_axi_tx_tready                    (s_axi_tx_tready           ),

    .m_axi_rx_tdata                     (m_axi_rx_tdata            ),
    .m_axi_rx_tkeep                     (m_axi_rx_tkeep            ),
    .m_axi_rx_tlast                     (m_axi_rx_tlast            ),
    .m_axi_rx_tvalid                    (m_axi_rx_tvalid           ),
    // to the top level
    .gt_refclk1_p                       (gt_refclk1_p              ),
    .gt_refclk1_n                       (gt_refclk1_n              ),
    .SFP_TXP                            (SFP_TXP                   ),
    .SFP_TXN                            (SFP_TXN                   ),
    .SFP_RXP                            (SFP_TXP                   ),
    .SFP_RXN                            (SFP_TXN                   ) 
    // .SFP_RXP                            (SFP_RXP                   ),
    // .SFP_RXN                            (SFP_RXN                   ) 
);

axi_stream_data_test#(
    .CHANNEL                            (SFP_CHANNEL               ),
    .DATA_WIDTH                         (32                        ) 
)
u_axi_stream_data_test(
    .sys_clk_i                          (user_clk_out              ),
    .rst_n_i                            (~sys_reset_out            ),
    .start_en_i                         ({SFP_CHANNEL{start_en_i}} ),
    .channel_up                         (channel_up                ),
    .lane_up                            (lane_up                   ),
    .s_axi_tx_tdata                     (s_axi_tx_tdata            ),
    .s_axi_tx_tkeep                     (s_axi_tx_tkeep            ),
    .s_axi_tx_tlast                     (s_axi_tx_tlast            ),
    .s_axi_tx_tvalid                    (s_axi_tx_tvalid           ),
    .s_axi_tx_tready                    (s_axi_tx_tready           ),
    .m_axi_rx_tdata                     (m_axi_rx_tdata            ),
    .m_axi_rx_tkeep                     (m_axi_rx_tkeep            ),
    .m_axi_rx_tlast                     (m_axi_rx_tlast            ),
    .m_axi_rx_tvalid                    (m_axi_rx_tvalid           ) 
);



endmodule
