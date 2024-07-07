module uart_tx_logic_o (
    input                               sys_clk_i                  ,//ʱ��,������50m
    input                               rst_n_i                    ,//��λ

    input              [   3:0]         uart_data_bit              ,//����λ��5,6,7,8�ֱ����5,6,7,8λ
    input              [  15:0]         baud_cnt_max               ,//ʱ��Ƶ�ʳ��Բ�����
    input              [   1:0]         uart_parity_bit            ,//У��λ��0��1��2��3�ֱ������У�飬��У�飬żУ�飬��У��
    input              [   1:0]         uart_stop_bit              ,//ֹͣλ��0��1��2��3�ֱ����1��1.5��2��1��ֹͣλ

    input              [   7:0]         tx_data_i                  ,//8bit����
    input                               tx_data_flag_i             ,//���ݱ�־
    output                              tx_busy_o                  ,//��æ
    output reg                          tx_o                        //tx��bit���
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// regs
//---------------------------------------------------------------------
reg                    [   3:0]         bit_cnt                    ;
reg                                     bit_flag                   ;
reg                    [  15:0]         baud_cnt                   ;
reg                    [   7:0]         tx_data_r                  ;
reg                    [   2:0]         next_state                 ;
reg                    [   2:0]         cur_state                  ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// localparam
//---------------------------------------------------------------------
localparam                              IDLE = 'd0                 ;
localparam                              START = 'd1                ;
localparam                              DATA = 'd2                 ;
localparam                              PARITY = 'd3               ;
localparam                              STOP = 'd4                 ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// assign
//---------------------------------------------------------------------
assign tx_busy_o = ~(next_state == IDLE);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// logic
//---------------------------------------------------------------------
//baud_cnt
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        baud_cnt<=0;
    else if(baud_cnt==baud_cnt_max)
        baud_cnt<=0;
    else case (next_state)
        START,DATA,PARITY,STOP: baud_cnt<=baud_cnt+'d1;
        default: baud_cnt<='d0;
    endcase
end
//bit_flag
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        bit_flag<=0;
    else if(baud_cnt==baud_cnt_max)
        bit_flag<=1;
    else
        bit_flag<=0;
end
//bit������
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        bit_cnt<=0;
    else case (cur_state)
        DATA:
            if (bit_cnt == uart_data_bit-1 && bit_flag) begin
                bit_cnt<='d0;
            end
            else if (bit_flag) begin
                bit_cnt<=bit_cnt+'d1;
            end
            else
                bit_cnt<=bit_cnt;
        STOP:
            if (bit_flag) begin
                bit_cnt<=bit_cnt+'d1;
            end
            else
                bit_cnt<=bit_cnt;
        default: bit_cnt<='d0;
    endcase
end
//��һ��,״̬��ת,ʱ���߼�
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cur_state<=IDLE;
    else
        cur_state<=next_state;
end
//�ڶ���,��ת����,����߼�
always@(*)begin
    case(cur_state)
        IDLE   :
            if (tx_data_flag_i) begin
                next_state<=START;
            end
            else
                next_state<=IDLE;
        START  :
            if (bit_flag) begin
                next_state<=DATA;
            end
            else
                next_state<=START;
        DATA   :
            if (bit_flag && bit_cnt == uart_data_bit-1 && (uart_parity_bit == 1 || uart_parity_bit == 2)) begin
                next_state<=PARITY;
            end
            else if (bit_flag && bit_cnt == uart_data_bit-1 && (uart_parity_bit == 0 || uart_parity_bit == 3)) begin
                next_state<=STOP;
            end
            else
                next_state<=DATA;
        PARITY :
            if (bit_flag) begin
                next_state<=STOP;
            end
            else
                next_state<=PARITY;
        STOP   :
            case (uart_stop_bit)
                0,3:
                    if (bit_flag && bit_cnt == 0) begin
                        next_state<=IDLE;
                    end
                    else
                        next_state<=STOP;
                1:
                    if (bit_cnt == 'd1 && baud_cnt == baud_cnt_max/2) begin
                        next_state<=IDLE;
                    end
                    else
                        next_state<=STOP;
                2:
                    if (bit_flag && bit_cnt == 1) begin
                        next_state<=IDLE;
                    end
                    else
                        next_state<=STOP;
                default:next_state<=IDLE;
            endcase
        default:next_state<=IDLE;
    endcase
end
//�������������
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        tx_data_r<='d0;
    else if (tx_data_flag_i) begin
        tx_data_r<=tx_data_i;
    end
end
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        tx_o<=1;
    else case (next_state)
        START: tx_o<='d0;
        DATA: tx_o<=tx_data_r[bit_cnt];                             //MSB
        PARITY:
            if (uart_parity_bit == 1) begin
                tx_o<= ~^tx_data_r;                                 //��У��
            end
            else
                tx_o<= ^tx_data_r;                                  //żУ��
        STOP: tx_o<='d1;
        default: tx_o<='d1;
    endcase
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// debug
//---------------------------------------------------------------------
// ila_uart_tx_debug ila_uart_tx_debug_inst (
//     .clk                               (sys_clk_i                 ),// input wire clk


//     .probe0                            (baud_cnt_max              ),// input wire [15:0]  probe0   
//     .probe1                            (uart_parity_bit           ),// input wire [1:0]  probe1    
//     .probe2                            (uart_stop_bit             ),// input wire [1:0]  probe2    
//     .probe3                            (tx_data_flag_i            ),// input wire [0:0]  probe3    
//     .probe4                            (tx_data_i                 ),// input wire [7:0]  probe4    
//     .probe5                            (bit_flag                  ),// input wire [0:0]  probe5    
//     .probe6                            (bit_cnt                   ),// input wire [3:0]  probe6    
//     .probe7                            (next_state                ),// input wire [2:0]  probe7 
//     .probe8                            (tx_o                      ) // input wire [0:0]  probe8
// );
endmodule