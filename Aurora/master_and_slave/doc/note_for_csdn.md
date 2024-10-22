[toc]

---

本文主要记录笔者关于单`bank`多通道`Aurora`的开发记录，基于`xilinx`FPGA平台的`Aurora`相关`IP`核。

---

## 场景需求

&emsp;&emsp;通常我们使用`Aurora`时，将一个`bank`上的多条`lane`通过`Aurora`的`IP`核组合起来使用。例如：使用四条`lane`，对FPGA互联而言，最后就通过`Aurora IP`转化成了一个`M_AXI_STREAM`和一个`S_AXI_STREAM`接口，即只有一个通道。

&emsp;&emsp;但有些时候，我们希望将多条`lane`通过`Aurora`的`IP`核组合起来使用。例如：使用四条`lane`，对FPGA互联而言，最后需要通过`Aurora IP`转化成了四个`M_AXI_STREAM`和四个`S_AXI_STREAM`接口，即四通道。

![alt text](image.png#pic_center)

&emsp;&emsp;那么问题需求出在哪里呢？如果单纯的像使用一条`lane`那样将`Aurora`例化四次，那么编译时将报错不会通过。因为当将`Aurora`的`IP`核的`Shared logic`选项配置成`include Shared logic in core`时，`IP`核将包含了该`bank`的`GT`时钟配置，而由于`GT`收发器的底层原理，一个`bank`只能有一个`GT COMMON`。

![alt text](image-1.png#pic_center)

&emsp;&emsp;因此，我们可以将`Aurora`的`IP`核的`Shared logic`选项配置成`include Shared logic in example design`，并且通过手动配置`GT COMMON`，这样`IP`核实例之间就互不影响了。但手动配置`GT COMMON`，对于不熟悉`serdes`收发器原理的人来说还是有些难度的。下面介绍一种简便的方法，可以跳过手动配置，仅仅使用`xilinx`的`IP`核完成单`bank`多通道`Aurora`的开发。

---

## 整体架构流程

&emsp;&emsp;如下图，通过“一主多从”的方式，可以轻松实现多通道的`Aurora`。其中一主是将`Aurora`的`IP`核的`Shared logic`选项配置成`include Shared logic in core`，这就完成了`GT COMMON`和第一个通道的配置；接着例化1~3个多从，即将`Aurora`的`IP`核的`Shared logic`选项配置成`include Shared logic in example design`，并且进行主从信号的连接即可完成单`bank`多通道`Aurora`的开发。

![alt text](image-2.png#pic_center)

---

## 重要信号解释


* ① pll_not_locked_out: 如果使用PLL为Aurora 8B/10B核心生成时钟信号，则应将pll_not_locked信号连接到PLL锁定信号的反相输出端。如果未使用PLL为Aurora 8B/10B核心生成时钟信号，则将pll_not_locked信号连接到地。即可接地。
* ② gt0_qplllock, gt0_qpllrefclklost: GTX_COMMON出来的QPLL锁和锁丢失信号，如下图；
* ③ gt_qpllclk_quard1, gt_qpllrefclk_quard1: GTX_COMMON出来的QPLL时钟信号，如下图；
* ④ user_clk_out/tx_out_clk, sys_reset_out: 用户时钟和用户端复位，即AXI_STREAM时钟和复位，每个IP核单独为一个时钟域； 
* ⑤ 以上为一主多从的相关信号讲解，其他信号按照Aurora IP核文档说明即可。

![alt text](image-3.png#pic_center)

---

## 代码实现

&emsp;&emsp;如下，可通过参数生成1~4个Aurora通道。

```verilog
`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               JingCe
// Engineer:              Chen Xiong Zhi
// 
// File name:             aurora_8b10b_wrapper.v
// Create Date:           2024/10/18 14:32:23
// Version:               V1.0
// PATH:                  2018\2018_for_sim\2018_for_sim.srcs\sources_1\new\aurora_8b10b_wrapper.v
// Descriptions:          mutiple aurora channel
// 
// ********************************************************************************** // 
`default_nettype none


module aurora_8b10b_wrapper #(
    parameter                           SFP_CHANNEL               = 2     
) (
    input  wire                         init_clk_in                ,
    input  wire                         reset                      ,// #1000
    input  wire                         gt_reset                   ,// #5000
    // user interface
    output wire        [SFP_CHANNEL-1: 0]user_clk_out              ,
    output wire        [SFP_CHANNEL-1: 0]sys_reset_out             ,

    output wire        [SFP_CHANNEL-1: 0]channel_up                ,
    output wire        [SFP_CHANNEL-1: 0]lane_up                   ,

    input  wire        [SFP_CHANNEL*3-1: 0]loopback                ,

    input  wire        [SFP_CHANNEL*32-1: 0]s_axi_tx_tdata         ,
    input  wire        [SFP_CHANNEL*4-1: 0]s_axi_tx_tkeep          ,
    input  wire        [SFP_CHANNEL-1: 0]s_axi_tx_tlast            ,
    input  wire        [SFP_CHANNEL-1: 0]s_axi_tx_tvalid           ,
    output wire        [SFP_CHANNEL-1: 0]s_axi_tx_tready           ,

    output wire        [SFP_CHANNEL*32-1: 0]m_axi_rx_tdata         ,
    output wire        [SFP_CHANNEL*4-1: 0]m_axi_rx_tkeep          ,
    output wire        [SFP_CHANNEL-1: 0]m_axi_rx_tlast            ,
    output wire        [SFP_CHANNEL-1: 0]m_axi_rx_tvalid           ,
    // to the top level
    input  wire                         gt_refclk1_p               ,
    input  wire                         gt_refclk1_n               ,

    output wire        [SFP_CHANNEL-1: 0]SFP_TXP                   ,
    output wire        [SFP_CHANNEL-1: 0]SFP_TXN                   ,
    input  wire        [SFP_CHANNEL-1: 0]SFP_RXP                   ,
    input  wire        [SFP_CHANNEL-1: 0]SFP_RXN                    
);

// ********************************************************************************** // 
//---------------------------------------------------------------------
// declarations
//---------------------------------------------------------------------
    genvar i;

    wire                                gt_refclk1                 ;
    wire                                gt_refclk1_div2            ;
    wire                                drpclk_in                  ;
    wire                                power_down                 ;

    wire               [SFP_CHANNEL-1: 0]tx_lock                   ;
    wire               [SFP_CHANNEL-1: 0]tx_resetdone_out          ;
    wire               [SFP_CHANNEL-1: 0]rx_resetdone_out          ;
    wire               [SFP_CHANNEL-1: 0]link_reset_out            ;

    wire               [SFP_CHANNEL-1: 0]hard_err                  ;
    wire               [SFP_CHANNEL-1: 0]soft_err                  ;
    wire               [SFP_CHANNEL-1: 0]frame_err                 ;
// master aurora ip
    wire                                gt0_qplllock_out           ;
    wire                                gt0_qpllrefclklost_out     ;
    wire                                gt_qpllclk_quad1_out       ;
    wire                                gt_qpllrefclk_quad1_out    ;
    wire                                sync_clk_out               ;
    wire                                gt_reset_out               ;
    wire                                pll_not_locked_out         ;

// ********************************************************************************** // 
//---------------------------------------------------------------------
// logics
//---------------------------------------------------------------------
    assign                              drpclk_in                 = init_clk_in;

    assign                              power_down                = 'd0;
    
// ********************************************************************************** // 
//---------------------------------------------------------------------
// instance
//---------------------------------------------------------------------

//--- Instance of GT differential buffer ---------//
IBUFDS_GTE2 #(
    .CLKCM_CFG                          ("TRUE"                    ),// Refer to Transceiver User Guide
    .CLKRCV_TRST                        ("TRUE"                    ),// Refer to Transceiver User Guide
    .CLKSWING_CFG                       (2'b11                     ) // Refer to Transceiver User Guide
)
u_IBUFDS_GTE2 (
    .I                                  (gt_refclk1_p              ),
    .IB                                 (gt_refclk1_n              ),
    .CEB                                (1'b0                      ),
    .O                                  (gt_refclk1                ),
    .ODIV2                              (gt_refclk1_div2           ) 
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// aurora_8b10b_master
//---------------------------------------------------------------------
aurora_8b10b_master u_aurora_8b10b_master (
    // AXI TX Interface
    .s_axi_tx_tdata                     (s_axi_tx_tdata[0*32 +: 32]),// input wire [31 : 0] s_axi_tx_tdata
    .s_axi_tx_tkeep                     (s_axi_tx_tkeep[0*4 +: 4]  ),// input wire [3 : 0] s_axi_tx_tkeep
    .s_axi_tx_tlast                     (s_axi_tx_tlast[0]         ),// input wire s_axi_tx_tlast
    .s_axi_tx_tvalid                    (s_axi_tx_tvalid[0]        ),// input wire s_axi_tx_tvalid
    .s_axi_tx_tready                    (s_axi_tx_tready[0]        ),// output wire s_axi_tx_tready
    // AXI RX Interface
    .m_axi_rx_tdata                     (m_axi_rx_tdata[0*32 +: 32]),// output wire [31 : 0] m_axi_rx_tdata
    .m_axi_rx_tkeep                     (m_axi_rx_tkeep[0*4 +: 4]  ),// output wire [3 : 0] m_axi_rx_tkeep
    .m_axi_rx_tlast                     (m_axi_rx_tlast[0]         ),// output wire m_axi_rx_tlast
    .m_axi_rx_tvalid                    (m_axi_rx_tvalid[0]        ),// output wire m_axi_rx_tvalid
    // V5 Serial I/O
    .txp                                (SFP_TXP[0]                ),// output wire [0 : 0] txp
    .txn                                (SFP_TXN[0]                ),// output wire [0 : 0] txn
    .rxp                                (SFP_RXP[0]                ),// input wire [0 : 0] rxp
    .rxn                                (SFP_RXN[0]                ),// input wire [0 : 0] rxn
    // GT Reference Clock Interface
    .gt_refclk1                         (gt_refclk1                ),// input wire gt_refclk1
    // Error Detection Interface
    .hard_err                           (hard_err[0]               ),// output wire hard_err
    .soft_err                           (soft_err[0]               ),// output wire soft_err
    .frame_err                          (frame_err[0]              ),// output wire frame_err
    // Status
    .channel_up                         (channel_up[0]             ),// output wire channel_up
    .lane_up                            (lane_up[0]                ),// output wire [0 : 0] lane_up
    // System Interface
    .user_clk_out                       (user_clk_out[0]           ),// output wire user_clk_out
    .sys_reset_out                      (sys_reset_out[0]          ),// output wire sys_reset_out

    .reset                              (reset                     ),// input wire reset
    .gt_reset                           (gt_reset                  ),// input wire gt_reset
    .sync_clk_out                       (sync_clk_out              ),// output wire sync_clk_out
    .gt_reset_out                       (gt_reset_out              ),// output wire gt_reset_out
    .init_clk_in                        (init_clk_in               ),// input wire init_clk_in
    .pll_not_locked_out                 (pll_not_locked_out        ),// output wire pll_not_locked_out

    .drpclk_in                          (drpclk_in                 ),// input wire drpclk_in
    .drpaddr_in                         (9'h0                      ),// input wire [8 : 0] drpaddr_in
    .drpen_in                           (1'b0                      ),// input wire drpen_in
    .drpdi_in                           (16'h0                     ),// input wire [15 : 0] drpdi_in
    .drprdy_out                         (                          ),// output wire drprdy_out
    .drpdo_out                          (                          ),// output wire [15 : 0] drpdo_out
    .drpwe_in                           (1'b0                      ),// input wire drpwe_in

    .loopback                           (loopback[0*3 +: 3]        ),// input wire [2 : 0] loopback
    .power_down                         (power_down                ),// input wire power_down
    .tx_lock                            (tx_lock[0]                ),// output wire tx_lock
    .tx_resetdone_out                   (tx_resetdone_out[0]       ),// output wire tx_resetdone_out
    .rx_resetdone_out                   (rx_resetdone_out[0]       ),// output wire rx_resetdone_out
    .link_reset_out                     (link_reset_out[0]         ),// output wire link_reset_out
//____________________________COMMON PORTS _______________________________
//    ------------------------- Common Block - QPLL Ports ------------------------
    .gt0_qplllock_out                   (gt0_qplllock_out          ),// output wire gt0_qplllock_out
    .gt0_qpllrefclklost_out             (gt0_qpllrefclklost_out    ),// output wire gt0_qpllrefclklost_out
    .gt_qpllclk_quad1_out               (gt_qpllclk_quad1_out      ),// output wire gt_qpllclk_quad1_out
    .gt_qpllrefclk_quad1_out            (gt_qpllrefclk_quad1_out   ) // output wire gt_qpllrefclk_quad1_out
);

// ********************************************************************************** // 
//---------------------------------------------------------------------
// instance slave
//---------------------------------------------------------------------
generate
    for (i = 1; i < SFP_CHANNEL; i = i+1) begin : s

aurora_8b10b_slave u_aurora_8b10b_slave (
    // AXI TX Interface
    .s_axi_tx_tdata                     (s_axi_tx_tdata[i*32 +: 32]),// input wire [31 : 0] s_axi_tx_tdata
    .s_axi_tx_tkeep                     (s_axi_tx_tkeep[i*4 +: 4]  ),// input wire [3 : 0] s_axi_tx_tkeep
    .s_axi_tx_tlast                     (s_axi_tx_tlast[i]         ),// input wire s_axi_tx_tlast
    .s_axi_tx_tvalid                    (s_axi_tx_tvalid[i]        ),// input wire s_axi_tx_tvalid
    .s_axi_tx_tready                    (s_axi_tx_tready[i]        ),// output wire s_axi_tx_tready
    // AXI RX Interface
    .m_axi_rx_tdata                     (m_axi_rx_tdata[i*32 +: 32]),// output wire [31 : 0] m_axi_rx_tdata
    .m_axi_rx_tkeep                     (m_axi_rx_tkeep[i*4 +: 4]  ),// output wire [3 : 0] m_axi_rx_tkeep
    .m_axi_rx_tlast                     (m_axi_rx_tlast[i]         ),// output wire m_axi_rx_tlast
    .m_axi_rx_tvalid                    (m_axi_rx_tvalid[i]        ),// output wire m_axi_rx_tvalid
    // GT Serial I/O
    .txp                                (SFP_TXP[i]                ),// output wire [0 : 0] txp
    .txn                                (SFP_TXN[i]                ),// output wire [0 : 0] txn
    .rxp                                (SFP_RXP[i]                ),// input wire [0 : 0] rxp
    .rxn                                (SFP_RXN[i]                ),// input wire [0 : 0] rxn
    // GT Reference Clock Interface
    .gt_refclk1                         (gt_refclk1                ),// input wire gt_refclk1
    // Error Detection Interface
    .hard_err                           (hard_err[i]               ),// output wire hard_err
    .soft_err                           (soft_err[i]               ),// output wire soft_err
    .frame_err                          (frame_err[i]              ),// output wire frame_err
    // Status
    .channel_up                         (channel_up[i]             ),// output wire channel_up
    .lane_up                            (lane_up[i]                ),// output wire [0 : 0] lane_up
    // System Interface
    .tx_out_clk                         (user_clk_out[i]           ),// output wire tx_out_clk
    .sys_reset_out                      (sys_reset_out[i]          ),// output wire sys_reset_out
    .reset                              (sys_reset_out[0]          ),// input wire reset
    .gt_reset                           (gt_reset_out              ),// input wire gt_reset
    
    .drpclk_in                          (drpclk_in                 ),// input wire drpclk_in
    .drpaddr_in                         (9'h0                      ),// input wire [8 : 0] drpaddr_in
    .drpen_in                           (1'b0                      ),// input wire drpen_in
    .drpdi_in                           (16'h0                     ),// input wire [15 : 0] drpdi_in
    .drprdy_out                         (                          ),// output wire drprdy_out
    .drpdo_out                          (                          ),// output wire [15 : 0] drpdo_out
    .drpwe_in                           (1'b0                      ),// input wire drpwe_in

    .loopback                           (loopback[i*3 +: 3]        ),// input wire [2 : 0] loopback
    .power_down                         (power_down                ),// input wire power_down
    .tx_lock                            (tx_lock[i]                ),// output wire tx_lock
    .tx_resetdone_out                   (tx_resetdone_out[i]       ),// output wire tx_resetdone_out
    .rx_resetdone_out                   (rx_resetdone_out[i]       ),// output wire rx_resetdone_out
    .link_reset_out                     (link_reset_out[i]         ),// output wire link_reset_out
    
    .init_clk_in                        (init_clk_in               ),// input wire init_clk_in
    .pll_not_locked                     (pll_not_locked_out        ),// input wire pll_not_locked
    .sync_clk                           (sync_clk_out              ),// input wire sync_clk
    .user_clk                           (user_clk_out[0]           ),// input wire user_clk
//------------------{
//_________________COMMON PORTS _______________________________{
//    ------------------------- Common Block - QPLL Ports ------------------------
    .gt0_qplllock_in                    (gt0_qplllock_out          ),// input wire gt0_qplllock_in
    .gt0_qpllrefclklost_in              (gt0_qpllrefclklost_out    ),// input wire gt0_qpllrefclklost_in
    .gt0_qpllreset_out                  (                          ),// output wire gt0_qpllreset_out
    .gt_qpllclk_quad1_in                (gt_qpllclk_quad1_out      ),// input wire gt_qpllclk_quad1_in
    .gt_qpllrefclk_quad1_in             (gt_qpllrefclk_quad1_out   ) // input wire gt_qpllrefclk_quad1_in
//____________________________COMMON PORTS ,_______________________________}
//------------------}
);

    end
endgenerate


endmodule


`default_nettype wire
```

---

## 仿真验证

&emsp;&emsp;仿真结果如下，四个通道的`channel up`均能正常拉高，表面链路建立完成：
![alt text](image-4.png#pic_center)

## 小结

&emsp;&emsp;该方案的本质还是单独配置`GT COMMON`，然后使用`Xilinx`的`Aurora IP`核(shared logic配置为in the example)，我们可以通过反复的练习思考，掌握高速收发器的使用方法。

---
