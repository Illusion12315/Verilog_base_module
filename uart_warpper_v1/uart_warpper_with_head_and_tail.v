module uart_warpper_with_head_and_tail (
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,

    input              [   7:0]         uart_data_bit              ,//数据位：5,6,7,8分别代表5,6,7,8位,若为非8，输入{3'bxxx,[4:0]},输出{[7:3],3'bxxx};
    input              [  15:0]         baud_cnt_max               ,//时钟频率除以波特率:115200
    input              [   1:0]         uart_parity_bit            ,//校验位：0，1，2，3分别代表无校验，奇校验，偶校验，无校验
    input              [   1:0]         uart_stop_bit              ,//停止位：0，1，2，3分别代表1，1.5，2，1的停止位

    input                               fifo_uart_tx_clk           ,//tx_fifo
    input                               fifo_uart_tx_wren          ,//tx_fifo
    input                               fifo_uart_tx_wren_r1       ,
    input              [   7:0]         fifo_uart_tx_data          ,//tx_fifo
    output                              fifo_uart_tx_prog_full     ,//tx_fifo

    input                               uart_tx_wren_start         ,
    input                               uart_tx_wren_end           ,

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
// ********************************************************************************** // 
//---------------------------------------------------------------------
// wr_fifo
//---------------------------------------------------------------------
reg                    [  15:0]         length_cnt                 ;
reg                                     work_en                    ;

always@(posedge fifo_uart_tx_clk or negedge rst_n_i)begin
    if (!rst_n_i) begin
        work_en<='d0;
    end
    else if (uart_tx_wren_end) begin
        work_en<='d0;
    end
    else if (uart_tx_wren_start) begin
        work_en<='d1;
    end
end

always@(posedge fifo_uart_tx_clk or negedge rst_n_i)begin
    if (!rst_n_i) begin
        length_cnt<='d0;
    end
    else if (!work_en) begin
        length_cnt<='d0;
    end
    else if (work_en && fifo_uart_tx_wren) begin
        length_cnt<=length_cnt+'d1;
    end
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// rd_fifo
//---------------------------------------------------------------------
wire                                    length_empty               ;
wire                   [  15:0]         length_rd_data             ;
reg                    [  15:0]         rd_cnt                     ;
reg                    [   1:0]         state                      ;
wire                                    length_rd_en               ;
localparam                              IDLE = 0                   ;
localparam                              READ = 1                   ;
localparam                              TAIL = 2                   ;

assign length_rd_en = (state == TAIL) & !length_empty;

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        state<=IDLE;
    end
    else case (state)
        IDLE: if (!length_empty) begin
          state<=READ;
        end
        READ: if (rd_cnt == length_rd_data+1) begin
          state<=TAIL;
        end
        TAIL: state<=IDLE;
        default:state<=IDLE;
    endcase
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        tx_data_flag<='d0;
    end
    else case (state)
        READ:
            if (!tx_empty && !tx_busy)
              tx_data_flag<='d1;
            else
              tx_data_flag<='d0;
        default: tx_data_flag<='d0;
    endcase
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        rd_cnt<='d0;
    end
    else case (state)
        READ: if (tx_data_flag) begin
            rd_cnt<=rd_cnt+'d1;
        end
        default: rd_cnt<='d0;
    endcase
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
    .wr_en                             (fifo_uart_tx_wren_r1      ),// input wire wr_en
    .din                               (fifo_uart_tx_data         ),// input wire [7 : 0] din
    .prog_full                         (fifo_uart_tx_prog_full    ),// output wire prog_full
    .full                              (                          ),// output wire full

    .rd_clk                            (sys_clk_i                 ),// input wire rd_clk
    .rd_en                             (tx_data_flag              ),// input wire rd_en
    .dout                              (tx_data                   ),// output wire [7 : 0] dout
    .empty                             (tx_empty                  ) // output wire empty
);

tx_length_fifo tx_length_fifo_inst (
    .rst                               (!rst_n_i                  ),// input wire rst

    .wr_clk                            (fifo_uart_tx_clk          ),// input wire wr_clk
    .wr_en                             (uart_tx_wren_end && fifo_uart_tx_wren_r1),// input wire wr_en
    .din                               (length_cnt                ),// input wire [15 : 0] din
    .full                              (                          ),// output wire full

    .rd_clk                            (sys_clk_i                 ),// input wire rd_clk
    .rd_en                             (length_rd_en              ),// input wire rd_en
    .dout                              (length_rd_data            ),// output wire [15 : 0] dout
    .empty                             (length_empty              ) // output wire empty
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
// ila_uart_warpper_debug ila_uart_warpper_debug_inst (
//     .clk                               (sys_clk_i                 ),// input wire clk

//     .probe0                            (length_empty              ),// input wire [0:0]  probe0  
//     .probe1                            ({tx_data_flag,tx_data,length_rd_data[6:0]}),// input wire [15:0]  probe1 
//     .probe2                            (length_rd_en              ),// input wire [0:0]  probe2 
//     .probe3                            (state                     ),// input wire [1:0]  probe3 
//     .probe4                            ({tx_busy,tx_empty,tx_o,rd_cnt[12:0]}) // input wire [15:0]  probe4 
// );
endmodule