`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             uart_engine_wrapper
// Create Date:           2024/05/31 10:31:48
// Version:               V1.0
// PATH:                  C:\Users\Administrator\Desktop\project\module base\uart\uart_wrapper\uart_engine_wrapper.v
// Descriptions:          
// 
// ********************************************************************************** // 


module uart_engine_wrapper (
    input  wire                         sys_clk_i                  ,
    input  wire                         rst_n_i                    ,
    
    input  wire        [   3: 0]        uart_data_bit              ,//����λ��5,6,7,8�ֱ����5,6,7,8λ,��Ϊ��8������{3'bxxx,[4:0]},���{[7:3],3'bxxx};
    input  wire        [  15: 0]        uart_bps_baud_cnt_max      ,//ʱ��Ƶ�ʳ��Բ�����:115200
    input  wire        [   1: 0]        uart_parity_bit            ,//У��λ��0��1��2��3�ֱ������У�飬��У�飬żУ�飬��У��
    input  wire        [   1: 0]        uart_stop_bit              ,//ֹͣλ��0��1��2��3�ֱ����1��1.5��2��1��ֹͣλ
    // tx fifo
    output wire                         fifo_uart_tx_rd_clk_o      ,
    output reg                          fifo_uart_tx_rd_en_o       ,
    input  wire                         fifo_uart_tx_dout_valid_i  ,
    input  wire        [   7: 0]        fifo_uart_tx_dout_i        ,
    input  wire                         fifo_uart_tx_empty_i       ,
    // rx fifo
    output wire                         fifo_uart_rx_wr_clk_o      ,
    output wire                         fifo_uart_rx_wr_en_o       ,
    output wire        [   7: 0]        fifo_uart_rx_din_o         ,
    input  wire                         fifo_uart_rx_prog_full_i   ,
    output wire        [   3: 0]        rx_parity_error_cnt        ,//RX����У��������,�޴�����Ϊ0,�������+1,λ��[3:0]
    
    output wire                         tx_o                       ,
    input  wire                         rx_i                        
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// uart_tx
//---------------------------------------------------------------------
    wire                                tx_busy                    ;
// rd clk
    assign                              fifo_uart_tx_rd_clk_o     = sys_clk_i;
// rd en
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        fifo_uart_tx_rd_en_o <= 'd0;
    end
    else if (!fifo_uart_tx_empty_i && !tx_busy) begin
        fifo_uart_tx_rd_en_o <= 'd1;
    end
    else
        fifo_uart_tx_rd_en_o <= 'd0;
end

uart_tx_logic_o uart_tx_logic_o_inst (
    .sys_clk_i                          (sys_clk_i                 ),//ʱ��,������50m,������,��Ҫ��uart_bps_baud_cnt_max���ʹ��
    .rst_n_i                            (rst_n_i                   ),

    .uart_data_bit                      (uart_data_bit             ),//����λ��5,6,7,8�ֱ����5,6,7,8λ,��Ϊ��8������{3'bxxx,[4:0]},���{[7:3],3'bxxx};
    .uart_bps_baud_cnt_max              (uart_bps_baud_cnt_max     ),//ʱ��Ƶ�ʳ��Բ�����
    .uart_parity_bit                    (uart_parity_bit           ),//У��λ��0��1��2��3�ֱ������У�飬��У�飬żУ�飬��У��
    .uart_stop_bit                      (uart_stop_bit             ),//ֹͣλ��0��1��2��3�ֱ����1��1.5��2��1��ֹͣλ

    .tx_data_i                          (fifo_uart_tx_dout_i       ),
    .tx_data_flag_i                     (fifo_uart_tx_dout_valid_i ),
    .tx_busy_o                          (tx_busy                   ),

    .tx_o                               (tx_o                      ) 
  );
// ********************************************************************************** // 
//---------------------------------------------------------------------
// Uart_rx
//---------------------------------------------------------------------
    wire                                rx_data_flag               ;
    wire               [   7: 0]        rx_data                    ;
// wr clk
    assign                              fifo_uart_rx_wr_clk_o     = sys_clk_i;
// wr en
    assign                              fifo_uart_rx_wr_en_o      = !fifo_uart_rx_prog_full_i && rx_data_flag;
// wr data
    assign                              fifo_uart_rx_din_o        = rx_data;

uart_rx_logic_i uart_rx_logic_i_inst (
    .sys_clk_i                          (sys_clk_i                 ),//ʱ��,������50m,������,��Ҫ��uart_bps_baud_cnt_max���ʹ��
    .rst_n_i                            (rst_n_i                   ),

    .uart_data_bit                      (uart_data_bit             ),//����λ��5,6,7,8�ֱ����5,6,7,8λ,��Ϊ��8������{3'bxxx,[4:0]},���{[7:3],3'bxxx};
    .uart_bps_baud_cnt_max              (uart_bps_baud_cnt_max     ),//������
    .uart_parity_bit                    (uart_parity_bit           ),//У��λ��0��1��2��3�ֱ������У�飬��У�飬żУ�飬��У��
    .uart_stop_bit                      (uart_stop_bit             ),//ֹͣλ��0��1��2��3�ֱ����1��1.5��2��1��ֹͣλ
    .rx_parity_error_cnt                (rx_parity_error_cnt       ),

    .rx_i                               (rx_i                      ),

    .rx_data_flag_o                     (rx_data_flag              ),
    .rx_data_o                          (rx_data                   ) 
  );
// ********************************************************************************** // 
//---------------------------------------------------------------------
// debug
//---------------------------------------------------------------------
// ila_uart_engine ila_uart_engine_inst (
//     .clk                                (sys_clk_i                 ),// input wire clk


//     .probe0                             (tx_busy                   ),// input wire [0:0]  probe0  
//     .probe1                             (fifo_uart_tx_empty_i      ),// input wire [0:0]  probe1 
//     .probe2                             (fifo_uart_tx_rd_en_o      ),// input wire [0:0]  probe2 
//     .probe3                             (fifo_uart_tx_dout_i       ),// input wire [7:0]  probe3 
//     .probe4                             (rx_data_flag              ),// input wire [0:0]  probe4 
//     .probe5                             (fifo_uart_rx_prog_full_i  ),// input wire [0:0]  probe5 
//     .probe6                             (fifo_uart_rx_wr_en_o      ),// input wire [0:0]  probe6 
//     .probe7                             (rx_data                   ) // input wire [7:0]  probe7
// );
endmodule