`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             aurora_wrapper.v
// Create Date:           2024/09/19 13:59:29
// Version:               V1.0
// PATH:                  2018\aurora_8b10b_sfp_ex\imports\aurora_wrapper\aurora_wrapper.v
// Descriptions:          
// 
// ********************************************************************************** // 
`default_nettype none


module aurora_wrapper #(
    parameter                           SFP_CHANNEL               = 2     
) (
    input  wire                         clk_100m_i                 ,
    input  wire                         rst_n_i                    ,
    
    input  wire                         gt_refclk1_p               ,
    input  wire                         gt_refclk1_n               ,

    output wire        [SFP_CHANNEL-1: 0]user_clk_out              ,
    output wire        [SFP_CHANNEL-1: 0]sys_reset_out             ,
    output wire        [SFP_CHANNEL-1: 0]channel_up                ,
    output wire        [SFP_CHANNEL-1: 0]lane_up                   ,

    input  wire        [3*SFP_CHANNEL-1: 0]loopback                ,

    input  wire        [32*SFP_CHANNEL-1: 0]s_axi_tx_tdata         ,
    input  wire        [4*SFP_CHANNEL-1: 0]s_axi_tx_tkeep          ,
    input  wire        [SFP_CHANNEL-1: 0]s_axi_tx_tlast            ,
    input  wire        [SFP_CHANNEL-1: 0]s_axi_tx_tvalid           ,
    output wire        [SFP_CHANNEL-1: 0]s_axi_tx_tready           ,

    output wire        [32*SFP_CHANNEL-1: 0]m_axi_rx_tdata         ,
    output wire        [4*SFP_CHANNEL-1: 0]m_axi_rx_tkeep          ,
    output wire        [SFP_CHANNEL-1: 0]m_axi_rx_tlast            ,
    output wire        [SFP_CHANNEL-1: 0]m_axi_rx_tvalid           ,
    
    output wire        [SFP_CHANNEL-1: 0]SFP_TXP                   ,
    output wire        [SFP_CHANNEL-1: 0]SFP_TXN                   ,
    input  wire        [SFP_CHANNEL-1: 0]SFP_RXP                   ,
    input  wire        [SFP_CHANNEL-1: 0]SFP_RXN                    
);

// ********************************************************************************** // 
//---------------------------------------------------------------------
// declarations
//---------------------------------------------------------------------
    wire                                gt_refclk1                 ;
    wire                                init_clk_i                 ;
    wire                                drpclk_i                   ;

    wire                                reset                      ;
    wire                                gt_reset                   ;
    //    ------------------------- Common Block - QPLL Ports ------------------------
    wire                                gt0_qplllock_i             ;
    wire                                gt0_qpllrefclklost_i       ;
    wire               [SFP_CHANNEL-1: 0]gt0_qpllreset_o           ;
    wire                                gt_qpllclk_quad1_i         ;
    wire                                gt_qpllrefclk_quad1_i      ;
(*ASYNC_REG = "TRUE"*)
    reg                                 rst_n_r1,rst_n_r2          ;
    // reg                [3*SFP_CHANNEL-1: 0]loopback_r1,loopback_r2  ;

    genvar i;

    assign                              init_clk_i                = clk_100m_i;
    assign                              drpclk_i                  = clk_100m_i;

    assign                              reset                     = 'd0;
    assign                              gt_reset                  = ~rst_n_r2;

// ********************************************************************************** // 
//---------------------------------------------------------------------
// main code
//---------------------------------------------------------------------
always@(posedge init_clk_i)begin
    rst_n_r1 <= rst_n_i;
    rst_n_r2 <= rst_n_r1;
end

//--- Instance of GT differential buffer ---------//
IBUFDS_GTE2 IBUFDS_GTE2_CLK1
(
    .I                                  (gt_refclk1_p              ),
    .IB                                 (gt_refclk1_n              ),
    .CEB                                (1'b0                      ),
    .O                                  (gt_refclk1                ),
    .ODIV2                              (                          ) 
);

//------ instance of _gt_common_wrapper ---{
aurora_8b10b_sfp_gt_common_wrapper gt_common_support
(
//____________________________COMMON PORTS ,_______________________________{
    .gt_qpllclk_quad1_i                 (gt_qpllclk_quad1_i        ),
    .gt_qpllrefclk_quad1_i              (gt_qpllrefclk_quad1_i     ),
   //-------------------- Common Block  - Ref Clock Ports ---------------------
    .gt0_gtrefclk0_common_in            (gt_refclk1                ),

   //----------------------- Common Block - QPLL Ports ------------------------
    .gt0_qplllock_out                   (gt0_qplllock_i            ),
    .gt0_qplllockdetclk_in              (init_clk_i                ),
    .gt0_qpllrefclklost_out             (gt0_qpllrefclklost_i      ),
    .gt0_qpllreset_in                   (| gt0_qpllreset_o         ) 
//____________________________COMMON PORTS ,_______________________________}
);

generate
    for (i = 0; i<SFP_CHANNEL; i=i+1) begin : lane
    
aurora_ip_cfg u_aurora_ip_cfg(
    .dclk_in_i                          (drpclk_i                  ),
    .gt_refclk1                         (gt_refclk1                ),
    .init_clk_i                         (init_clk_i                ),
    .reset                              (reset                     ),// #1000
    .gt_reset                           (gt_reset                  ),// #5000
    //    ------------------------- Common Block - QPLL Ports ------------------------
    .gt0_qplllock_i                     (gt0_qplllock_i            ),
    .gt0_qpllrefclklost_i               (gt0_qpllrefclklost_i      ),
    .gt0_qpllreset_o                    (gt0_qpllreset_o[i]        ),
    .gt_qpllclk_quad1_i                 (gt_qpllclk_quad1_i        ),
    .gt_qpllrefclk_quad1_i              (gt_qpllrefclk_quad1_i     ),
    // status
    .channel_up                         (channel_up[i]             ),
    .lane_up                            (lane_up[i]                ),
    .loopback                           (loopback[3*i +: 3]        ),
    // .tx_resetdone_o                     (tx_resetdone_o            ),
    // .rx_resetdone_o                     (rx_resetdone_o            ),
    // .link_reset_o                       (link_reset_o              ),
    // axi interface
    .user_clk_out                       (user_clk_out[i]           ),
    .sys_reset_out                      (sys_reset_out[i]          ),
    // TX AXI PDU I/F wires
    .s_axi_tx_tdata                     (s_axi_tx_tdata[i*32 +: 32]),
    .s_axi_tx_tkeep                     (s_axi_tx_tkeep[i*4 +: 4]  ),
    .s_axi_tx_tlast                     (s_axi_tx_tlast[i]         ),
    .s_axi_tx_tvalid                    (s_axi_tx_tvalid[i]        ),
    .s_axi_tx_tready                    (s_axi_tx_tready[i]        ),
    // RX AXI PDU I/F wires
    .m_axi_rx_tdata                     (m_axi_rx_tdata[i*32 +: 32]),
    .m_axi_rx_tkeep                     (m_axi_rx_tkeep[i*4 +: 4]  ),
    .m_axi_rx_tlast                     (m_axi_rx_tlast[i]         ),
    .m_axi_rx_tvalid                    (m_axi_rx_tvalid[i]        ),
    // lanes
    .txp                                (SFP_TXP[i]                ),
    .txn                                (SFP_TXN[i]                ),
    .rxp                                (SFP_RXP[i]                ),
    .rxn                                (SFP_RXN[i]                ) 
);

    end
endgenerate


endmodule


`default_nettype wire
