`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             aurora_ip_cfg.v
// Create Date:           2024/09/19 14:36:28
// Version:               V1.0
// PATH:                  2018\aurora_8b10b_sfp_ex\imports\aurora_wrapper\aurora_ip_cfg.v
// Descriptions:          
// 
// ********************************************************************************** // 
`default_nettype none


module aurora_ip_cfg (

    input  wire                         dclk_in_i                  ,
    input  wire                         gt_refclk1                 ,
    input  wire                         init_clk_i                 ,

    input  wire                         reset                      ,// #1000
    input  wire                         gt_reset                   ,// #5000


//    ------------------------- Common Block - QPLL Ports ------------------------
    input  wire                         gt0_qplllock_i             ,
    input  wire                         gt0_qpllrefclklost_i       ,
    output wire                         gt0_qpllreset_o            ,
    input  wire                         gt_qpllclk_quad1_i         ,
    input  wire                         gt_qpllrefclk_quad1_i      ,

    // status
    output wire                         channel_up                 ,
    output wire                         lane_up                    ,
    input  wire        [   2: 0]        loopback                   ,

    output wire                         tx_resetdone_o             ,
    output wire                         rx_resetdone_o             ,
    output wire                         link_reset_o               ,

    // axi interface
    output wire                         user_clk_out               ,
    output wire                         sys_reset_out              ,
    // TX AXI PDU I/F wires
    input  wire        [  31: 0]        s_axi_tx_tdata             ,
    input  wire        [   3: 0]        s_axi_tx_tkeep             ,
    input  wire                         s_axi_tx_tlast             ,
    input  wire                         s_axi_tx_tvalid            ,
    output wire                         s_axi_tx_tready            ,
    // RX AXI PDU I/F wires
    output wire        [  31: 0]        m_axi_rx_tdata             ,
    output wire        [   3: 0]        m_axi_rx_tkeep             ,
    output wire                         m_axi_rx_tlast             ,
    output wire                         m_axi_rx_tvalid            ,
    // lanes
    output wire                         txp                        ,
    output wire                         txn                        ,
    input  wire                         rxp                        ,
    input  wire                         rxn                         
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// declarations
//---------------------------------------------------------------------
    wire                                tx_out_clk_i               ;
    wire                                user_clk_i                 ;
    wire                                tx_lock_i                  ;

    wire                                sync_clk_i                 ;

    wire                                pll_not_locked_i           ;

    wire                                system_reset_i             ;
    wire                                gt_reset_i                 ;

    wire                                power_down                 ;

    wire               [   8: 0]        daddr_in_i                 ;
    wire                                den_in_i                   ;
    wire               [  15: 0]        di_in_i                    ;
    wire                                drdy_out_unused_o          ;
    wire               [  15: 0]        drpdo_out_unused_o         ;
    wire                                dwe_in_i                   ;


// ********************************************************************************** // 
//---------------------------------------------------------------------
// assigns
//---------------------------------------------------------------------
    assign                              user_clk_out              = user_clk_i;

    assign                              power_down                = 'd0;

    assign                              sync_clk_i                = user_clk_i;
    assign                              pll_not_locked_i          = !tx_lock_i;

    assign                              daddr_in_i                = 9'h0;
    assign                              den_in_i                  = 1'b0;
    assign                              di_in_i                   = 16'h0;
    assign                              dwe_in_i                  = 1'b0;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// main code
//---------------------------------------------------------------------
    // Instantiate a clock module for clock division.
    // Input buffering
    //------------------------------------
BUFG user_clk_buf_i(
    .I                                  (tx_out_clk_i              ),
    .O                                  (user_clk_i                ) 
);

aurora_8b10b_sfp_SUPPORT_RESET_LOGIC support_reset_logic_i
(
    .RESET                              (reset                     ),
    .USER_CLK                           (user_clk_i                ),
    .INIT_CLK_IN                        (init_clk_i                ),
    .GT_RESET_IN                        (gt_reset                  ),
    .SYSTEM_RESET                       (system_reset_i            ),// output
    .GT_RESET_OUT                       (gt_reset_i                ) // output
);
//------ instance of _gt_common_wrapper ---}

//----- Instance of _xci -----[
aurora_8b10b_sfp aurora_8b10b_sfp_i
    (
       // AXI TX Interface
    .s_axi_tx_tdata                     (s_axi_tx_tdata            ),
    .s_axi_tx_tkeep                     (s_axi_tx_tkeep            ),
    .s_axi_tx_tvalid                    (s_axi_tx_tvalid           ),
    .s_axi_tx_tlast                     (s_axi_tx_tlast            ),
    .s_axi_tx_tready                    (s_axi_tx_tready           ),

       // AXI RX Interface
    .m_axi_rx_tdata                     (m_axi_rx_tdata            ),
    .m_axi_rx_tkeep                     (m_axi_rx_tkeep            ),
    .m_axi_rx_tvalid                    (m_axi_rx_tvalid           ),
    .m_axi_rx_tlast                     (m_axi_rx_tlast            ),

       // GT Serial I/O
    .rxp                                (rxp                       ),
    .rxn                                (rxn                       ),
    .txp                                (txp                       ),
    .txn                                (txn                       ),

       // GT Reference Clock Interface
    .gt_refclk1                         (gt_refclk1                ),
       // Error Detection Interface
    // .frame_err                          (frame_err                 ),

       // Error Detection Interface
    // .hard_err                           (hard_err                  ),
    // .soft_err                           (soft_err                  ),

       // Status
    .channel_up                         (channel_up                ),
    .lane_up                            (lane_up                   ),

       // System Interface
    .user_clk                           (user_clk_i                ),
    .sync_clk                           (sync_clk_i                ),
    .reset                              (system_reset_i            ),
    .power_down                         (power_down                ),
    .loopback                           (loopback                  ),
    .gt_reset                           (gt_reset_i                ),
    .tx_lock                            (tx_lock_i                 ),
    .init_clk_in                        (init_clk_i                ),
    .pll_not_locked                     (pll_not_locked_i          ),
    .tx_resetdone_out                   (tx_resetdone_o            ),
    .rx_resetdone_out                   (rx_resetdone_o            ),
    .link_reset_out                     (link_reset_o              ),

    .drpclk_in                          (dclk_in_i                 ),
    .drpaddr_in                         (daddr_in_i                ),
    .drpen_in                           (den_in_i                  ),
    .drpdi_in                           (di_in_i                   ),
    .drprdy_out                         (drdy_out_unused_o         ),
    .drpdo_out                          (drpdo_out_unused_o        ),
    .drpwe_in                           (dwe_in_i                  ),
//------------------{
//_________________COMMON PORTS _______________________________{
//    ------------------------- Common Block - QPLL Ports ------------------------
    .gt0_qplllock_in                    (gt0_qplllock_i            ),
    .gt0_qpllrefclklost_in              (gt0_qpllrefclklost_i      ),
    .gt0_qpllreset_out                  (gt0_qpllreset_o           ),
    .gt_qpllclk_quad1_in                (gt_qpllclk_quad1_i        ),
    .gt_qpllrefclk_quad1_in             (gt_qpllrefclk_quad1_i     ),
//____________________________COMMON PORTS ,_______________________________}
//------------------}
    .sys_reset_out                      (sys_reset_out             ),
    .tx_out_clk                         (tx_out_clk_i              ) 

    );
//----- Instance of _xci -----]

endmodule


`default_nettype wire
