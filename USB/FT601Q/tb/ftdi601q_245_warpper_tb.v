`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             ftdi601q_245_warpper_tb
// Create Date:           2024/06/18 11:01:38
// Version:               V1.0
// PATH:                  C:\Users\Administrator\Desktop\project\module base\FTDI245FIFO\my_ftdi\ftdi601q_245_warpper_tb.v
// Descriptions:          
// 
// ********************************************************************************** // 
// `default_nettype none


module ftdi601q_245_warpper_tb;

// Parameters

//Ports
    reg                                 sys_clk_i                  ;
    reg                                 rst_n_i                    ;
    reg                                 tx_clk                     ;
    reg                                 tx_en                      ;
    reg                [  31: 0]        tx_din                     ;
    wire                                tx_prog_full               ;
    reg                                 rx_clk                     ;
    reg                                 rx_en                      ;
    wire               [  31: 0]        rx_dout                    ;
    wire                                rx_empty                   ;
    wire                                USB3_DCLK                  ;
    tri                [  31: 0]        USB3_DATA                  ;
    tri                [   3: 0]        USB3_BE_N                  ;
    wire                                USB3_TXE_N                 ;
    wire                                USB3_RXF_N                 ;
    wire                                USB3_WR_N                  ;
    wire                                USB3_RD_N                  ;
    wire                                USB3_OE_N                  ;
    wire                                USB3_WAKEUPB               ;
    wire                                USB3_SIWU_N                ;

initial begin
    // USB3_DCLK = 'd0;
    rst_n_i = 'd0;
    # 50
    rst_n_i = 'd1;
end

always@(*)begin
    tx_clk = USB3_DCLK;
    rx_clk = USB3_DCLK;
end

always@(*)begin
    rx_en = ~tx_prog_full & ~rx_empty;
    tx_en = ~tx_prog_full & ~rx_empty;
    tx_din = rx_dout;
end

ftdi601q_245_warpper  ftdi601q_245_warpper_inst (
    .sys_clk_i                          (sys_clk_i                 ),
    .rst_n_i                            (rst_n_i                   ),
    .tx_clk                             (tx_clk                    ),
    .tx_en                              (tx_en                     ),
    .tx_din                             (tx_din                    ),
    .tx_prog_full                       (tx_prog_full              ),
    .rx_clk                             (rx_clk                    ),
    .rx_en                              (rx_en                     ),
    .rx_dout                            (rx_dout                   ),
    .rx_empty                           (rx_empty                  ),
    .USB3_DCLK                          (USB3_DCLK                 ),
    .USB3_DATA                          (USB3_DATA                 ),
    .USB3_BE_N                          (USB3_BE_N                 ),
    .USB3_TXE_N                         (USB3_TXE_N                ),
    .USB3_RXF_N                         (USB3_RXF_N                ),
    .USB3_WR_N                          (USB3_WR_N                 ),
    .USB3_RD_N                          (USB3_RD_N                 ),
    .USB3_OE_N                          (USB3_OE_N                 ),
    .USB3_WAKEUPB                       (USB3_WAKEUPB              ),
    .USB3_SIWU_N                        (USB3_SIWU_N               ) 
);

tb_ftdi_chip_model # (
    .CHIP_EW                            (2                         ) 
) u_tb_ftdi_chip_model (
    .ftdi_clk                           (USB3_DCLK                 ),
    .ftdi_rxf_n                         (USB3_RXF_N                ),
    .ftdi_txe_n                         (USB3_TXE_N                ),
    .ftdi_oe_n                          (USB3_OE_N                 ),
    .ftdi_rd_n                          (USB3_RD_N                 ),
    .ftdi_wr_n                          (USB3_WR_N                 ),
    .ftdi_data                          (USB3_DATA                 ),
    .ftdi_be                            (USB3_BE_N                 ) 
);

// always #5  USB3_DCLK = ! USB3_DCLK ;

endmodule