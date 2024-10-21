`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               JingNeng
// Engineer:              Chen Xiong Zhi
// 
// File name:             axi_stream_data_test.v
// Create Date:           2024/10/18 16:00:38
// Version:               V1.0
// PATH:                  2018\2018_for_sim\2018_for_sim.srcs\sources_1\new\axi_stream_data_test.v
// Descriptions:          
// 
// ********************************************************************************** // 
`default_nettype none


module axi_stream_data_test #(
    parameter                           CHANNEL                   = 3     ,
    parameter                           DATA_WIDTH                = 32    
) (
    input  wire        [CHANNEL-1: 0]   sys_clk_i                  ,
    input  wire        [CHANNEL-1: 0]   rst_n_i                    ,
    
    input  wire        [CHANNEL-1: 0]   start_en_i                 ,

    input  wire        [CHANNEL-1: 0]   channel_up                 ,
    input  wire        [CHANNEL-1: 0]   lane_up                    ,

    output reg         [CHANNEL*DATA_WIDTH-1: 0]s_axi_tx_tdata     ,
    output reg         [CHANNEL*DATA_WIDTH/8-1: 0]s_axi_tx_tkeep   ,
    output wire        [CHANNEL-1: 0]   s_axi_tx_tlast             ,
    output reg         [CHANNEL-1: 0]   s_axi_tx_tvalid            ,
    input  wire        [CHANNEL-1: 0]   s_axi_tx_tready            ,

    input  wire        [CHANNEL*DATA_WIDTH-1: 0]m_axi_rx_tdata     ,
    input  wire        [CHANNEL*DATA_WIDTH/8-1: 0]m_axi_rx_tkeep   ,
    input  wire        [CHANNEL-1: 0]   m_axi_rx_tlast             ,
    input  wire        [CHANNEL-1: 0]   m_axi_rx_tvalid             
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// declarations
//---------------------------------------------------------------------
    genvar i;

    localparam                          BRUST_LEN                 = 8     ;

    reg                [   7: 0]        send_cnt[0:CHANNEL-1]      ;

// ********************************************************************************** // 
//---------------------------------------------------------------------
// generates
//---------------------------------------------------------------------
generate
    for (i = 0; i<CHANNEL; i=i+1) begin

always@(posedge sys_clk_i[i])begin
    if (!rst_n_i[i]) begin
        send_cnt[i] <= 'd0;
    end
    else if (s_axi_tx_tlast[i]) begin
        send_cnt[i] <= 'd0;
    end
    else if (s_axi_tx_tvalid[i] && s_axi_tx_tready[i]) begin
        send_cnt[i] <= send_cnt[i] + 'd1;
    end
end

always@(posedge sys_clk_i[i])begin
    if (!rst_n_i[i]) begin
        s_axi_tx_tvalid[i] <= 'd0;
    end
    else if (channel_up[i] && start_en_i[i]) begin
        s_axi_tx_tvalid[i] <= 'd1;
    end
    else begin
        s_axi_tx_tvalid[i] <= 'd0;
    end
end

    assign                              s_axi_tx_tlast[i]         = (s_axi_tx_tvalid[i] && s_axi_tx_tready[i]) && (send_cnt[i] == BRUST_LEN - 1);

always@(posedge sys_clk_i[i])begin
    if (!rst_n_i[i]) begin
        s_axi_tx_tdata[i*DATA_WIDTH + DATA_WIDTH - 8 +: 8] <= 'd0;
        s_axi_tx_tdata[i*DATA_WIDTH +: DATA_WIDTH - 8] <= 'd0;

        s_axi_tx_tkeep[i*DATA_WIDTH/8 +: DATA_WIDTH/8] <= 'd0;
    end
    else if (s_axi_tx_tvalid[i] && s_axi_tx_tready[i]) begin
        s_axi_tx_tdata[i*DATA_WIDTH + DATA_WIDTH - 8 +: 8] <= i;
        s_axi_tx_tdata[i*DATA_WIDTH +: DATA_WIDTH - 8] <= s_axi_tx_tdata[i*DATA_WIDTH +: DATA_WIDTH - 8] + 'd1;
        
        s_axi_tx_tkeep[i*DATA_WIDTH/8 +: DATA_WIDTH/8] <= -1;
    end
end




    end
endgenerate




endmodule


`default_nettype wire
