module pps_uart_warpper #(
    parameter                           UART_NUM = 6                
) (
    input                               pcie_axi_clk               ,
    input                               clk_50m                    ,
    input                               sys_reset_n                ,

    input              [UART_NUM-1:0]   fifo_uart_tx_wren          ,
    input              [UART_NUM-1:0]   uart_tx_wren_start         ,
    input              [UART_NUM-1:0]   uart_tx_wren_end           ,
    input              [UART_NUM*8-1:0] uart_tx_data               ,
    output             [UART_NUM-1:0]   fifo_uart_tx_prog_full     ,
    
    input              [UART_NUM*16-1:0]uart_bps                   ,//波特率
    //    波特率     1200      2400	      4800	    9600       19200      38400	        57600      115200   230400	  460800	921600
    //    设值      0xa2c2    0x5160     0x28B0   0x1458     0x0a2c    0x0516	   0x0364      0x01b2   0xD9      0x6C	    0x36	  
    input              [UART_NUM*4-1:0] uart_data_bit              ,//数据位
    input              [UART_NUM*2-1:0] uart_stop_bit              ,//停止位：0，1，2，3分别代表1，1.5，2，1的停止位
    input              [UART_NUM*2-1:0] uart_parity_bit            ,//校验位：0，1，2，3分别代表无校验，奇校验，偶校验，无校验
    
    input              [UART_NUM-1:0]   fifo_uart_rx_rden          ,
    output             [UART_NUM-1:0]   fifo_uart_rx_empty         ,
    output             [UART_NUM*8-1:0] uart_rx_data               ,

    output             [UART_NUM-1:0]   tx_o                       ,
    input              [UART_NUM-1:0]   rx_i                        
);
reg                    [UART_NUM*16-1:0]baud_cnt_max_r1='d0,baud_cnt_max_r2='d0;
reg                    [UART_NUM*2-1:0] uart_stop_bit_r1='d0,uart_stop_bit_r2='d0;
reg                    [UART_NUM*2-1:0] uart_parity_bit_r1='d0,uart_parity_bit_r2='d0;

reg                    [UART_NUM-1:0]   fifo_uart_tx_wren_r1       ;

always@(posedge clk_50m)begin
    uart_stop_bit_r1<=uart_stop_bit;
    uart_stop_bit_r2<=uart_stop_bit_r1;
end
always@(posedge clk_50m)begin
    uart_parity_bit_r1<=uart_parity_bit;
    uart_parity_bit_r2<=uart_parity_bit_r1;
end
always@(posedge clk_50m)begin
    baud_cnt_max_r1<=uart_bps;
    baud_cnt_max_r2<=baud_cnt_max_r1;
end
always@(posedge pcie_axi_clk)begin
    fifo_uart_tx_wren_r1<=fifo_uart_tx_wren;
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// uart_warpper
//---------------------------------------------------------------------
generate
    begin
        genvar i;
        for(i=0;i<UART_NUM;i=i+1)
            begin:pps_uart
                uart_warpper_without_head_and_tail # (
                    .DATA_BIT                          (8                         )
                  )
                  uart_warpper_without_head_and_tail_inst (
                    .sys_clk_i                         (clk_50m                   ),
                    .rst_n_i                           (sys_reset_n               ),

                    .baud_cnt_max                      (baud_cnt_max_r2[16*i+15:16*i]),
                    .uart_parity_bit                   (uart_parity_bit_r2[2*i+1:2*i]),
                    .uart_stop_bit                     (uart_stop_bit_r2[2*i+1:2*i]),

                    .fifo_uart_tx_clk                  (pcie_axi_clk              ),
                    .fifo_uart_tx_wren                 (fifo_uart_tx_wren_r1[i]   ),
                    .fifo_uart_tx_data                 (uart_tx_data[8*i+7:8*i]   ),
                    .fifo_uart_tx_prog_full            (fifo_uart_tx_prog_full[i] ),

                    .fifo_uart_rx_clk                  (pcie_axi_clk              ),
                    .fifo_uart_rx_rden                 (fifo_uart_rx_rden[i]      ),
                    .fifo_uart_rx_data                 (uart_rx_data[8*i+7:8*i]   ),
                    .fifo_uart_rx_empty                (fifo_uart_rx_empty[i]     ),

                    .tx_o                              (tx_o[i]                   ),
                    .rx_i                              (rx_i[i]                   ) 
                  );
            end
    end
endgenerate
endmodule