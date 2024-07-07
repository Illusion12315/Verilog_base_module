`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             uart_wrapper
// Create Date:           2024/05/31 10:32:25
// Version:               V1.0
// PATH:                  C:\Users\Administrator\Desktop\project\module base\uart\uart_wrapper\uart_wrapper.v
// Descriptions:          
// 
// ********************************************************************************** // 

/*

//例化串口模块
uart_wrapper # (
    .UART_NUM                           (UART_NUM                  ) 
  )
  uart_wrapper_inst (
    .sys_clk_i                          (sys_clk_i                 ),
    .rst_n_i                            (rst_n_i                   ),

    .uart_data_bit_i                    (uart_data_bit_i           ),//数据位:5,6,7,8分别代表5,6,7,8位,若为非8, 输入{3'bxxx,[4:0]},输出{[7:3],3'bxxx}在例如:输入{3'hx,5'h01},输出{5'h01,3'hx}
    .uart_bps_baud_cnt_max_i            (uart_bps_baud_cnt_max_i   ),//时钟频率除以波特率:例如设置Uart时钟50Mhz,想要设置波特率115200,需设置该值为50_000_000 / 115200
    .uart_parity_bit_i                  (uart_parity_bit_i         ),//校验位:0, 1, 2, 3分别代表无校验, 奇校验, 偶校验, 无校验
    .uart_stop_bit_i                    (uart_stop_bit_i           ),//停止位:0, 1, 2, 3分别代表1, 1.5, 2, 1的停止位

    .fifo_uart_ds_clk_i                 (fifo_uart_ds_clk_i        ),//下行,上位机发数据给其他设备
    .fifo_uart_ds_wr_en_i               (fifo_uart_ds_wr_en_i      ),//下行,上位机发数据给其他设备
    .fifo_uart_ds_din_i                 (fifo_uart_ds_din_i        ),//下行,上位机发数据给其他设备
    .fifo_uart_ds_prog_full_o           (fifo_uart_ds_prog_full_o  ),//下行,上位机发数据给其他设备

    .fifo_uart_us_clk_i                 (fifo_uart_us_clk_i        ),//上行,上位机接收其他设备的数据
    .fifo_uart_us_rd_en_i               (fifo_uart_us_rd_en_i      ),//上行,上位机接收其他设备的数据
    .fifo_uart_us_dout_o                (fifo_uart_us_dout_o       ),//上行,上位机接收其他设备的数据
    .fifo_uart_us_empty_o               (fifo_uart_us_empty_o      ),//上行,上位机接收其他设备的数据
    .rx_parity_error_cnt_o              (rx_parity_error_cnt_o     ),

    .tx_o                               (tx_o                      ),
    .rx_i                               (rx_i                      ) 
  );

*/

module uart_wrapper #(
    parameter                           UART_NUM                  = 1     
) (
    input  wire                         sys_clk_i                  ,//Uart驱动时钟,一般为50MHz
    input  wire        [UART_NUM-1: 0]  rst_n_i                    ,

    input  wire        [UART_NUM*4-1: 0]uart_data_bit_i            ,//数据位:5,6,7,8分别代表5,6,7,8位,若为非8, 输入{3'bxxx,[4:0]},输出{[7:3],3'bxxx}在例如:输入{3'hx,5'h01},输出{5'h01,3'hx}
    input  wire        [UART_NUM*16-1: 0]uart_bps_baud_cnt_max_i   ,//时钟频率除以波特率:例如设置Uart时钟50Mhz,想要设置波特率115200,需设置该值为50_000_000 / 115200
    input  wire        [UART_NUM*2-1: 0]uart_parity_bit_i          ,//校验位:0, 1, 2, 3分别代表无校验, 奇校验, 偶校验, 无校验
    input  wire        [UART_NUM*2-1: 0]uart_stop_bit_i            ,//停止位:0, 1, 2, 3分别代表1, 1.5, 2, 1的停止位

    input  wire        [UART_NUM-1: 0]  fifo_uart_ds_clk_i         ,//下行,上位机发数据给其他设备
    input  wire        [UART_NUM-1: 0]  fifo_uart_ds_wr_en_i       ,//下行,上位机发数据给其他设备
    input  wire        [UART_NUM*8-1: 0]fifo_uart_ds_din_i         ,//下行,上位机发数据给其他设备
    output wire        [UART_NUM-1: 0]  fifo_uart_ds_prog_full_o   ,//下行,上位机发数据给其他设备

    input  wire        [UART_NUM-1: 0]  fifo_uart_us_clk_i         ,//上行,上位机接收其他设备的数据
    input  wire        [UART_NUM-1: 0]  fifo_uart_us_rd_en_i       ,//上行,上位机接收其他设备的数据
    output wire        [UART_NUM*8-1: 0]fifo_uart_us_dout_o        ,//上行,上位机接收其他设备的数据
    output wire        [UART_NUM-1: 0]  fifo_uart_us_empty_o       ,//上行,上位机接收其他设备的数据

    output wire        [UART_NUM*4-1: 0]rx_parity_error_cnt_o      ,// output [3:0]

    output wire        [UART_NUM-1: 0]  tx_o                       ,//引至顶层
    input  wire        [UART_NUM-1: 0]  rx_i                        //引至顶层
);
    wire               [UART_NUM-1: 0]  fifo_uart_tx_rd_clk        ;
    wire               [UART_NUM-1: 0]  fifo_uart_tx_rd_en         ;
    wire               [UART_NUM*8-1: 0]fifo_uart_tx_dout          ;
    wire               [UART_NUM-1: 0]  fifo_uart_tx_empty         ;

    wire               [UART_NUM-1: 0]  fifo_uart_rx_wr_clk        ;
    wire               [UART_NUM-1: 0]  fifo_uart_rx_wr_en         ;
    wire               [UART_NUM*8-1: 0]fifo_uart_rx_din           ;
    wire               [UART_NUM-1: 0]  fifo_uart_rx_prog_full     ;

    integer                             i                          ;

generate
    begin
        genvar i;
        for (i = 0; i < UART_NUM; i = i + 1) begin:uart
            uart_engine_wrapper  uart_engine_wrapper_inst (
                .sys_clk_i                          (sys_clk_i                 ),
                .rst_n_i                            (rst_n_i[i]                ),

                .uart_data_bit                      (uart_data_bit_i[4*i+3:4*i]  ),
                .uart_bps_baud_cnt_max              (uart_bps_baud_cnt_max_i[16*i+15:16*i]),//数据位
                .uart_parity_bit                    (uart_parity_bit_i[2*i+1:2*i]),//停止位:0, 1, 2, 3分别代表1, 1.5, 2, 1的停止位
                .uart_stop_bit                      (uart_stop_bit_i[2*i+1:2*i]  ),//校验位:0, 1, 2, 3分别代表无校验, 奇校验, 偶校验, 无校验

                .fifo_uart_tx_rd_clk_o              (fifo_uart_tx_rd_clk[i]    ),
                .fifo_uart_tx_rd_en_o               (fifo_uart_tx_rd_en[i]     ),
                .fifo_uart_tx_dout_valid_i          (fifo_uart_tx_rd_en[i]     ),//如果选用FWFT FIFO, valid等于rd en, 若选Stardand FIFO, 需接Valid信号
                .fifo_uart_tx_dout_i                (fifo_uart_tx_dout[8*i+7:8*i]),
                .fifo_uart_tx_empty_i               (fifo_uart_tx_empty[i]     ),

                .fifo_uart_rx_wr_clk_o              (fifo_uart_rx_wr_clk[i]    ),
                .fifo_uart_rx_wr_en_o               (fifo_uart_rx_wr_en[i]     ),
                .fifo_uart_rx_din_o                 (fifo_uart_rx_din[8*i+7:8*i]),
                .fifo_uart_rx_prog_full_i           (fifo_uart_rx_prog_full[i] ),
                .rx_parity_error_cnt                (rx_parity_error_cnt_o[4*i+3:4*i]),

                .tx_o                               (tx_o[i]                   ),
                .rx_i                               (rx_i[i]                   ) 
              );
            
            fifo_uart_tx fifo_uart_tx_inst (
                .rst                                (!rst_n_i[i]               ),// input wire rst
                .wr_clk                             (fifo_uart_ds_clk_i[i]     ),// input wire wr_clk
                .wr_en                              (fifo_uart_ds_wr_en_i[i]   ),// input wire wr_en
                .din                                (fifo_uart_ds_din_i[8*i+7:8*i]),// input wire [7 : 0] din
                .prog_full                          (fifo_uart_ds_prog_full_o[i]),// output wire prog_full
                .full                               (                          ),// output wire full
            
                .rd_clk                             (fifo_uart_tx_rd_clk[i]    ),// input wire rd_clk
                .rd_en                              (fifo_uart_tx_rd_en[i]     ),// input wire rd_en
                .dout                               (fifo_uart_tx_dout[8*i+7:8*i]),// output wire [7 : 0] dout
                .empty                              (fifo_uart_tx_empty[i]     ) // output wire empty
            );
            
            fifo_uart_rx fifo_uart_rx_inst (
                .rst                                (!rst_n_i[i]               ),// input wire rst
                .wr_clk                             (fifo_uart_rx_wr_clk[i]    ),// input wire wr_clk
                .wr_en                              (fifo_uart_rx_wr_en[i]     ),// input wire wr_en
                .din                                (fifo_uart_rx_din[8*i+7:8*i]),// input wire [7 : 0] din
                .prog_full                          (fifo_uart_rx_prog_full[i] ),// output wire prog_full
                .full                               (                          ),// output wire full
            
                .rd_clk                             (fifo_uart_us_clk_i[i]      ),// input wire rd_clk
                .rd_en                              (fifo_uart_us_rd_en_i[i]    ),// input wire rd_en
                .dout                               (fifo_uart_us_dout_o[8*i+7:8*i]),// output wire [7 : 0] dout
                .empty                              (fifo_uart_us_empty_o[i]    ) // output wire empty
            );
        end
    end
endgenerate

endmodule