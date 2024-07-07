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

//��������ģ��
uart_wrapper # (
    .UART_NUM                           (UART_NUM                  ) 
  )
  uart_wrapper_inst (
    .sys_clk_i                          (sys_clk_i                 ),
    .rst_n_i                            (rst_n_i                   ),

    .uart_data_bit_i                    (uart_data_bit_i           ),//����λ:5,6,7,8�ֱ����5,6,7,8λ,��Ϊ��8, ����{3'bxxx,[4:0]},���{[7:3],3'bxxx}������:����{3'hx,5'h01},���{5'h01,3'hx}
    .uart_bps_baud_cnt_max_i            (uart_bps_baud_cnt_max_i   ),//ʱ��Ƶ�ʳ��Բ�����:��������Uartʱ��50Mhz,��Ҫ���ò�����115200,�����ø�ֵΪ50_000_000 / 115200
    .uart_parity_bit_i                  (uart_parity_bit_i         ),//У��λ:0, 1, 2, 3�ֱ������У��, ��У��, żУ��, ��У��
    .uart_stop_bit_i                    (uart_stop_bit_i           ),//ֹͣλ:0, 1, 2, 3�ֱ����1, 1.5, 2, 1��ֹͣλ

    .fifo_uart_ds_clk_i                 (fifo_uart_ds_clk_i        ),//����,��λ�������ݸ������豸
    .fifo_uart_ds_wr_en_i               (fifo_uart_ds_wr_en_i      ),//����,��λ�������ݸ������豸
    .fifo_uart_ds_din_i                 (fifo_uart_ds_din_i        ),//����,��λ�������ݸ������豸
    .fifo_uart_ds_prog_full_o           (fifo_uart_ds_prog_full_o  ),//����,��λ�������ݸ������豸

    .fifo_uart_us_clk_i                 (fifo_uart_us_clk_i        ),//����,��λ�����������豸������
    .fifo_uart_us_rd_en_i               (fifo_uart_us_rd_en_i      ),//����,��λ�����������豸������
    .fifo_uart_us_dout_o                (fifo_uart_us_dout_o       ),//����,��λ�����������豸������
    .fifo_uart_us_empty_o               (fifo_uart_us_empty_o      ),//����,��λ�����������豸������
    .rx_parity_error_cnt_o              (rx_parity_error_cnt_o     ),

    .tx_o                               (tx_o                      ),
    .rx_i                               (rx_i                      ) 
  );

*/

module uart_wrapper #(
    parameter                           UART_NUM                  = 1     
) (
    input  wire                         sys_clk_i                  ,//Uart����ʱ��,һ��Ϊ50MHz
    input  wire        [UART_NUM-1: 0]  rst_n_i                    ,

    input  wire        [UART_NUM*4-1: 0]uart_data_bit_i            ,//����λ:5,6,7,8�ֱ����5,6,7,8λ,��Ϊ��8, ����{3'bxxx,[4:0]},���{[7:3],3'bxxx}������:����{3'hx,5'h01},���{5'h01,3'hx}
    input  wire        [UART_NUM*16-1: 0]uart_bps_baud_cnt_max_i   ,//ʱ��Ƶ�ʳ��Բ�����:��������Uartʱ��50Mhz,��Ҫ���ò�����115200,�����ø�ֵΪ50_000_000 / 115200
    input  wire        [UART_NUM*2-1: 0]uart_parity_bit_i          ,//У��λ:0, 1, 2, 3�ֱ������У��, ��У��, żУ��, ��У��
    input  wire        [UART_NUM*2-1: 0]uart_stop_bit_i            ,//ֹͣλ:0, 1, 2, 3�ֱ����1, 1.5, 2, 1��ֹͣλ

    input  wire        [UART_NUM-1: 0]  fifo_uart_ds_clk_i         ,//����,��λ�������ݸ������豸
    input  wire        [UART_NUM-1: 0]  fifo_uart_ds_wr_en_i       ,//����,��λ�������ݸ������豸
    input  wire        [UART_NUM*8-1: 0]fifo_uart_ds_din_i         ,//����,��λ�������ݸ������豸
    output wire        [UART_NUM-1: 0]  fifo_uart_ds_prog_full_o   ,//����,��λ�������ݸ������豸

    input  wire        [UART_NUM-1: 0]  fifo_uart_us_clk_i         ,//����,��λ�����������豸������
    input  wire        [UART_NUM-1: 0]  fifo_uart_us_rd_en_i       ,//����,��λ�����������豸������
    output wire        [UART_NUM*8-1: 0]fifo_uart_us_dout_o        ,//����,��λ�����������豸������
    output wire        [UART_NUM-1: 0]  fifo_uart_us_empty_o       ,//����,��λ�����������豸������

    output wire        [UART_NUM*4-1: 0]rx_parity_error_cnt_o      ,// output [3:0]

    output wire        [UART_NUM-1: 0]  tx_o                       ,//��������
    input  wire        [UART_NUM-1: 0]  rx_i                        //��������
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
                .uart_bps_baud_cnt_max              (uart_bps_baud_cnt_max_i[16*i+15:16*i]),//����λ
                .uart_parity_bit                    (uart_parity_bit_i[2*i+1:2*i]),//ֹͣλ:0, 1, 2, 3�ֱ����1, 1.5, 2, 1��ֹͣλ
                .uart_stop_bit                      (uart_stop_bit_i[2*i+1:2*i]  ),//У��λ:0, 1, 2, 3�ֱ������У��, ��У��, żУ��, ��У��

                .fifo_uart_tx_rd_clk_o              (fifo_uart_tx_rd_clk[i]    ),
                .fifo_uart_tx_rd_en_o               (fifo_uart_tx_rd_en[i]     ),
                .fifo_uart_tx_dout_valid_i          (fifo_uart_tx_rd_en[i]     ),//���ѡ��FWFT FIFO, valid����rd en, ��ѡStardand FIFO, ���Valid�ź�
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