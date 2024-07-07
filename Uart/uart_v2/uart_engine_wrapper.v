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
    
    input  wire        [   3: 0]        uart_data_bit              ,//数据位：5,6,7,8分别代表5,6,7,8位,若为非8，输入{3'bxxx,[4:0]},输出{[7:3],3'bxxx};
    input  wire        [  15: 0]        uart_bps_baud_cnt_max      ,//时钟频率除以波特率:115200
    input  wire        [   1: 0]        uart_parity_bit            ,//校验位：0，1，2，3分别代表无校验，奇校验，偶校验，无校验
    input  wire        [   1: 0]        uart_stop_bit              ,//停止位：0，1，2，3分别代表1，1.5，2，1的停止位
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
    output wire        [   3: 0]        rx_parity_error_cnt        ,//RX接收校验错误计数,无错误则为0,有误码后+1,位宽[3:0]
    
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
    .sys_clk_i                          (sys_clk_i                 ),//时钟,必须是50m,若不是,需要和uart_bps_baud_cnt_max配合使用
    .rst_n_i                            (rst_n_i                   ),

    .uart_data_bit                      (uart_data_bit             ),//数据位：5,6,7,8分别代表5,6,7,8位,若为非8，输入{3'bxxx,[4:0]},输出{[7:3],3'bxxx};
    .uart_bps_baud_cnt_max              (uart_bps_baud_cnt_max     ),//时钟频率除以波特率
    .uart_parity_bit                    (uart_parity_bit           ),//校验位：0，1，2，3分别代表无校验，奇校验，偶校验，无校验
    .uart_stop_bit                      (uart_stop_bit             ),//停止位：0，1，2，3分别代表1，1.5，2，1的停止位

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
    .sys_clk_i                          (sys_clk_i                 ),//时钟,必须是50m,若不是,需要和uart_bps_baud_cnt_max配合使用
    .rst_n_i                            (rst_n_i                   ),

    .uart_data_bit                      (uart_data_bit             ),//数据位：5,6,7,8分别代表5,6,7,8位,若为非8，输入{3'bxxx,[4:0]},输出{[7:3],3'bxxx};
    .uart_bps_baud_cnt_max              (uart_bps_baud_cnt_max     ),//波特率
    .uart_parity_bit                    (uart_parity_bit           ),//校验位：0，1，2，3分别代表无校验，奇校验，偶校验，无校验
    .uart_stop_bit                      (uart_stop_bit             ),//停止位：0，1，2，3分别代表1，1.5，2，1的停止位
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