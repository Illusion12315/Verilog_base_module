`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             ftdi601q_245_warpper
// Create Date:           2024/06/11 09:41:45
// Version:               V1.0
// PATH:                  C:\Users\Administrator\Desktop\project\module base\FTDI245FIFO\my_ftdi\ftdi601q_245_warpper.v
// Descriptions:          
// 
// ********************************************************************************** // 

module ftdi601q_245_warpper (
    input  wire                         sys_clk_i                  ,
    input  wire                         rst_n_i                    ,

    input  wire                         tx_clk                     ,
    input  wire                         tx_en                      ,
    input  wire        [  31: 0]        tx_din                     ,
    output wire                         tx_prog_full               ,

    input  wire                         rx_clk                     ,
    input  wire                         rx_en                      ,
    output wire        [  31: 0]        rx_dout                    ,
    output wire                         rx_empty                   ,

    input  wire                         USB3_DCLK                  ,// 设为100MHz时，时序要求很高。设为66MHz可正常使用（已在项目上验证）。
    inout  wire        [  31: 0]        USB3_DATA                  ,
    inout  wire        [   3: 0]        USB3_BE_N                  ,
    input  wire                         USB3_TXE_N                 ,// FIFO可写信号, 拉低非满
    input  wire                         USB3_RXF_N                 ,// FIFO可读信号, 拉低非空
    output reg                          USB3_WR_N                  ,// 写使能
    output reg                          USB3_RD_N                  ,// 读使能
    output reg                          USB3_OE_N                  ,// 输出使能
    inout  wire                         USB3_WAKEUPB               ,
    output wire                         USB3_SIWU_N                 // 拉高
    );
// ********************************************************************************** // 
//---------------------------------------------------------------------
// declarations
//---------------------------------------------------------------------
    localparam                          TX_IDLE                   = 6'h13 ;
    localparam                          TX_EN                     = 6'h23 ;
    localparam                          RX_IDLE                   = 6'h03 ;
    localparam                          RX_OE                     = 6'h02 ;
    localparam                          RX_EN                     = 6'h00 ;
    localparam                          RX_WAIT                   = 6'h07 ;
    localparam                          RX_END                    = 6'h0B ;

    reg                [   5: 0]        state                      ;
    reg                                 ftdi_master_oe             ;// 1:master (FPGA) drives DATA/BE    0:master (FPGA) release DATA/BE to High-Z

    wire                                wr_fifo_rd_en              ;
    wire               [  31: 0]        wr_fifo_dout               ;
    wire                                wr_fifo_empty              ;

    wire                                rd_fifo_wr_en              ;
    wire               [  31: 0]        rd_fifo_din                ;
    wire                                rd_fifo_prog_full          ;

    reg                [  31: 0]        ftdi_data_out              ;
    reg                [   3: 0]        ftdi_be_out                ;
    wire               [  31: 0]        ftdi_data_in               ;
    wire               [   3: 0]        ftdi_be_in                 ;

    reg                [   2: 0]        srst_n_shift               ;
    wire                                srst_n                     ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// reset
//---------------------------------------------------------------------
always@(posedge USB3_DCLK or negedge rst_n_i)begin
    if (!rst_n_i)
        srst_n_shift <= 'd0;
    else
        srst_n_shift <= {1'd1,srst_n_shift[2:1]};
end

    assign                              srst_n                    = srst_n_shift[0];
// ********************************************************************************** // 
//---------------------------------------------------------------------
// assigns
//---------------------------------------------------------------------
    assign                              USB3_SIWU_N               = 'd1;

    assign                              ftdi_data_in              = USB3_DATA;
    assign                              ftdi_be_in                = USB3_BE_N;
    assign                              USB3_DATA                 = (ftdi_master_oe) ? ftdi_data_out : 'hz;
    assign                              USB3_BE_N                 = (ftdi_master_oe) ? ftdi_be_out : 'hz;

    assign                              rd_fifo_wr_en             = (state == RX_EN) && ~USB3_RXF_N && (ftdi_be_in == 4'b1111) && ~rd_fifo_prog_full;
    assign                              rd_fifo_din               = (~(state == RX_EN)) ? 'd0 : ftdi_data_in;

    assign                              wr_fifo_rd_en             = (state == TX_EN) && ~USB3_TXE_N && ~wr_fifo_empty;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// main code
//---------------------------------------------------------------------
always@(posedge USB3_DCLK or negedge srst_n)begin
    if (!srst_n)
        state <= RX_IDLE;
    else case (state)
        RX_IDLE:
            if(~USB3_RXF_N && ~rd_fifo_prog_full)
                state <= RX_OE;
            else
                state <= TX_IDLE;
        RX_OE: state <= RX_EN;
        RX_EN:
            if(USB3_RXF_N | rd_fifo_prog_full)
                state <= RX_WAIT;
        RX_WAIT: state <= RX_END;
        RX_END: state <= TX_IDLE;

        TX_IDLE:
            if(~USB3_TXE_N && ~wr_fifo_empty)
                state <= TX_EN;
            else
                state <= RX_IDLE;
        TX_EN:
            if(USB3_TXE_N || wr_fifo_empty)
                state <= RX_IDLE;
        default:
            if(~USB3_TXE_N && ~wr_fifo_empty)
                state <= TX_EN;
            else
                state <= RX_IDLE;
    endcase
end

always@(*)begin
    USB3_OE_N = ~(state == RX_OE || state == RX_EN);
    USB3_RD_N = (rd_fifo_prog_full) ? 1'd1 : ~(state == RX_EN);     // & ~rd_fifo_prog_full
    USB3_WR_N = (state == TX_EN) ? ~wr_fifo_rd_en : 1'b1;
    ftdi_master_oe = (state == TX_EN);                              // 1:master (FPGA) drives DATA/BE    0:master (FPGA) release DATA/BE to High-Z
    ftdi_data_out = wr_fifo_dout;
    ftdi_be_out = 4'b1111;
end

// ********************************************************************************** // 
//---------------------------------------------------------------------
// fifo
//---------------------------------------------------------------------
fifo_usb usb3_rd_fifo_inst (
    .rst                                (~srst_n                   ),// input wire rst

    .wr_clk                             (USB3_DCLK                 ),// input wire wr_clk
    .wr_en                              (rd_fifo_wr_en             ),// input wire wr_en
    .din                                (rd_fifo_din               ),// input wire [31 : 0] din
    .rd_data_count                      (                          ),// output wire [9 : 0] rd_data_count
    .full                               (                          ),// output wire full
    .prog_full                          (rd_fifo_prog_full         ),// output wire prog_full

    .rd_clk                             (rx_clk                    ),// input wire rd_clk
    .rd_en                              (rx_en                     ),// input wire rd_en
    .dout                               (rx_dout                   ),// output wire [31 : 0] dout
    .wr_data_count                      (                          ),// output wire [9 : 0] wr_data_count
    .empty                              (rx_empty                  ) // output wire empty
);

fifo_usb usb3_wr_fifo_inst (
    .rst                                (~srst_n                   ),// input wire rst

    .wr_clk                             (tx_clk                    ),// input wire wr_clk
    .wr_en                              (tx_en                     ),// input wire wr_en
    .din                                (tx_din                    ),// input wire [31 : 0] din
    .rd_data_count                      (                          ),// output wire [9 : 0] rd_data_count
    .full                               (                          ),// output wire full
    .prog_full                          (tx_prog_full              ),// output wire prog_full

    .rd_clk                             (USB3_DCLK                 ),// input wire rd_clk
    .rd_en                              (wr_fifo_rd_en             ),// input wire rd_en
    .dout                               (wr_fifo_dout              ),// output wire [31 : 0] dout
    .wr_data_count                      (                          ),// output wire [9 : 0] wr_data_count
    .empty                              (wr_fifo_empty             ) // output wire empty
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// debug
//---------------------------------------------------------------------



endmodule