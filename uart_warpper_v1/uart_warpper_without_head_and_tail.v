module uart_warpper_without_head_and_tail (
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,

    input              [   7:0]         uart_data_bit              ,//数据位：5,6,7,8分别代表5,6,7,8位,若为非8，输入{3'bxxx,[4:0]},输出{[7:3],3'bxxx};
    input              [  15:0]         baud_cnt_max               ,//时钟频率除以波特率:115200
    input              [   1:0]         uart_parity_bit            ,//校验位：0，1，2，3分别代表无校验，奇校验，偶校验，无校验
    input              [   1:0]         uart_stop_bit              ,//停止位：0，1，2，3分别代表1，1.5，2，1的停止位

    input                               fifo_uart_tx_clk           ,//tx_fifo
    input                               fifo_uart_tx_wren          ,//tx_fifo
    input              [   7:0]         fifo_uart_tx_data          ,//tx_fifo
    output                              fifo_uart_tx_prog_full     ,//tx_fifo

    input                               fifo_uart_rx_clk           ,//rx_fifo
    input                               fifo_uart_rx_rden          ,//rx_fifo
    output             [   7:0]         fifo_uart_rx_data          ,//rx_fifo
    output                              fifo_uart_rx_empty         ,//rx_fifo

    output                              tx_o                       ,
    input                               rx_i                        
);
wire                   [   7:0]         tx_data                    ;
wire                                    tx_busy                    ;
wire                                    tx_empty                   ;

wire                                    rx_data_flag               ;
wire                   [   7:0]         rx_data                    ;
wire                                    rx_prog_full               ;

reg                                     tx_data_flag               ;

always@(posedge sys_clk_i or negedge rst_n_i)begin
  if (!rst_n_i) begin
    tx_data_flag<='d0;
  end
  else if (!tx_empty && !tx_busy) begin
    tx_data_flag<='d1;
  end
  else
    tx_data_flag<='d0;
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// uart_tx
//---------------------------------------------------------------------
uart_tx_logic_o uart_tx_logic_o_inst (
    .sys_clk_i                         (sys_clk_i                 ),//时钟,必须是50m
    .rst_n_i                           (rst_n_i                   ),

    .uart_data_bit                     (uart_data_bit             ),//数据位：5,6,7,8分别代表5,6,7,8位,若为非8，输入{3'bxxx,[4:0]},输出{[7:3],3'bxxx};
    .baud_cnt_max                      (baud_cnt_max              ),//时钟频率除以波特率
    .uart_parity_bit                   (uart_parity_bit           ),//校验位：0，1，2，3分别代表无校验，奇校验，偶校验，无校验
    .uart_stop_bit                     (uart_stop_bit             ),//停止位：0，1，2，3分别代表1，1.5，2，1的停止位

    .tx_data_i                         (tx_data                   ),
    .tx_data_flag_i                    (tx_data_flag              ),
    .tx_busy_o                         (tx_busy                   ),

    .tx_o                              (tx_o                      ) 
  );

fifo_uart_tx fifo_uart_tx_inst (
    .rst                               (!rst_n_i                  ),// input wire rst
    .wr_clk                            (fifo_uart_tx_clk          ),// input wire wr_clk
    .wr_en                             (fifo_uart_tx_wren         ),// input wire wr_en
    .din                               (fifo_uart_tx_data         ),// input wire [7 : 0] din
    .prog_full                         (fifo_uart_tx_prog_full    ),// output wire prog_full
    .full                              (                          ),// output wire full

    .rd_clk                            (sys_clk_i                 ),// input wire rd_clk
    .rd_en                             (tx_data_flag              ),// input wire rd_en
    .dout                              (tx_data                   ),// output wire [7 : 0] dout
    .empty                             (tx_empty                  ) // output wire empty
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// Uart_rx
//---------------------------------------------------------------------
uart_rx_logic_i uart_rx_logic_i_inst (
    .sys_clk_i                         (sys_clk_i                 ),//时钟,必须是50m
    .rst_n_i                           (rst_n_i                   ),

    .uart_data_bit                     (uart_data_bit             ),//数据位：5,6,7,8分别代表5,6,7,8位,若为非8，输入{3'bxxx,[4:0]},输出{[7:3],3'bxxx};
    .baud_cnt_max                      (baud_cnt_max              ),//波特率
    .uart_parity_bit                   (uart_parity_bit           ),//校验位：0，1，2，3分别代表无校验，奇校验，偶校验，无校验
    .uart_stop_bit                     (uart_stop_bit             ),//停止位：0，1，2，3分别代表1，1.5，2，1的停止位

    .rx_i                              (rx_i                      ),

    .rx_data_flag_o                    (rx_data_flag              ),
    .rx_data_o                         (rx_data                   ) 
  );

fifo_uart_rx fifo_uart_rx_inst (
    .rst                               (!rst_n_i                  ),// input wire rst
    .wr_clk                            (sys_clk_i                 ),// input wire wr_clk
    .wr_en                             (!rx_prog_full && rx_data_flag),// input wire wr_en
    .din                               (rx_data                   ),// input wire [7 : 0] din
    .prog_full                         (rx_prog_full              ),// output wire prog_full
    .full                              (                          ),// output wire full

    .rd_clk                            (fifo_uart_rx_clk          ),// input wire rd_clk
    .rd_en                             (fifo_uart_rx_rden         ),// input wire rd_en
    .dout                              (fifo_uart_rx_data         ),// output wire [7 : 0] dout
    .empty                             (fifo_uart_rx_empty        ) // output wire empty
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// debug
//---------------------------------------------------------------------
// ila_uart_warpper_debug axi_debug (
//     .clk                               (fifo_uart_rx_clk          ),// input wire clk


//     .probe0                            (fifo_uart_tx_wren         ),// input wire [0:0]  probe0  
//     .probe1                            (fifo_uart_tx_data         ),// input wire [7:0]  probe1 
//     .probe2                            (fifo_uart_tx_prog_full    ),// input wire [0:0]  probe2 
//     .probe3                            (fifo_uart_rx_rden         ),// input wire [0:0]  probe3 
//     .probe4                            (fifo_uart_rx_data         ),// input wire [7:0]  probe4 
//     .probe5                            (fifo_uart_rx_empty        ) // input wire [0:0]  probe5
// );
endmodule