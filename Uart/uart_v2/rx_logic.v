`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             rx_logic
// Create Date:           2024/05/31 09:53:31
// Version:               V1.0
// PATH:                  C:\Users\Administrator\Desktop\project\module base\uart\uart_warpper\rx_logic.v
// Descriptions:          
// 
// ********************************************************************************** // 


module uart_rx_logic_i (
    input  wire                         sys_clk_i                  ,//时钟,必须是50m,若不是,需要和uart_bps_baud_cnt_max配合使用
    input  wire                         rst_n_i                    ,

    input  wire        [   3: 0]        uart_data_bit              ,//数据位：5,6,7,8分别代表5,6,7,8位
    input  wire        [  15: 0]        uart_bps_baud_cnt_max      ,//波特率
    input  wire        [   1: 0]        uart_parity_bit            ,//校验位：0，1，2，3分别代表无校验，奇校验，偶校验，无校验
    input  wire        [   1: 0]        uart_stop_bit              ,//停止位：0，1，2，3分别代表1，1.5，2，1的停止位
    output reg         [   3: 0]        rx_parity_error_cnt        ,//RX接收校验错误计数,无错误则为0,有误码后+1,位宽[3:0]

    input  wire                         rx_i                       ,
    output reg                          rx_data_flag_o             ,
    output reg         [   7: 0]        rx_data_o                   
);
    wire                                start_negedge              ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// regs
//---------------------------------------------------------------------
    reg                                 rx_flag                    ;
    reg                [   7: 0]        rx_data                    ;
    reg                [   3: 0]        bit_cnt                    ;
    reg                [  15: 0]        baud_cnt                   ;
    reg                                 bit_flag                   ;
    reg                                 work_en                    ;
    reg                [   3: 0]        bit_num                    ;
    reg                                 verify_bit                 ;
    reg                                 verify_sim_odd             ;//奇
    reg                                 verify_sim_even            ;//偶
(*ASYNC_REG = "TRUE"*)
    reg                                 rx_r1,rx_r2,rx_r3          ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// logic
//---------------------------------------------------------------------
//bit_num
always@(posedge sys_clk_i)begin
    if (uart_parity_bit == 1 || uart_parity_bit == 2) begin
        if (uart_stop_bit == 1 || uart_stop_bit == 2) begin
            bit_num <= 1'b1 + uart_data_bit + 1'b1 + 2'd2;
        end
        else
            bit_num <= 1'b1 + uart_data_bit + 1'b1 + 1'b1;
    end
    else begin
        if (uart_stop_bit == 1 || uart_stop_bit == 2) begin
            bit_num <= 1'b1 + uart_data_bit + 1'b1 + 1'b1;
        end
        else
            bit_num <= 1'b1 + uart_data_bit + 1'b1;
    end
end
//下降沿产生开始信号
    assign                              start_negedge             = ~rx_r2 & rx_r3;
//打3拍
always@(posedge sys_clk_i)begin
    rx_r1 <= rx_i;
    rx_r2 <= rx_r1;
    rx_r3 <= rx_r2;
end
//rx接收使能
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        work_en <= 'd0;
    else if (start_negedge) begin
        work_en <= 'd1;
    end
    else if (uart_parity_bit == 1 || uart_parity_bit == 2) begin
        if (bit_cnt == 1'b1 + uart_data_bit + 1'b1 && bit_flag =='d1) begin
            work_en <= 'd0;
        end
    end
    else begin
        if (bit_cnt == 1'b1 + uart_data_bit && bit_flag =='d1) begin
            work_en <= 'd0;
        end
    end
end
//计数器
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        baud_cnt <= 'd0;
    else if (baud_cnt == uart_bps_baud_cnt_max-1 || work_en == 'd0) begin
        baud_cnt <= 'd0;
    end
    else if (work_en) begin
        baud_cnt <= baud_cnt + 'd1;
    end
    else
        baud_cnt <= baud_cnt;
end
//采集标志
always@(posedge sys_clk_i)begin
    if (baud_cnt == uart_bps_baud_cnt_max/2 - 1) begin
        bit_flag <= 'd1;
    end
    else
        bit_flag <= 'd0;
end
//bit计数器
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        bit_cnt <= 'd0;
    else if (uart_parity_bit == 1 || uart_parity_bit == 2) begin
        if (bit_cnt == 1'b1 + uart_data_bit + 1'b1 && bit_flag == 'd1) begin
            bit_cnt <= 'd0;
        end
        else if (bit_flag) begin
            bit_cnt <= bit_cnt + 'd1;
        end
    end
    else begin
        if (bit_cnt == 1'b1 + uart_data_bit && bit_flag =='d1) begin
            bit_cnt <= 'd0;
        end
        else if (bit_flag) begin
            bit_cnt <= bit_cnt + 'd1;
        end
    end
end
//接收8bit数据
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        rx_data <= 'd0;
    else if (bit_cnt >= 'd1 && bit_cnt <= uart_data_bit && bit_flag == 'd1) begin
        rx_data <= {rx_r3,rx_data[7:1]};
    end
end
//校验
always@(*)begin
    case (uart_data_bit)
        5: begin
            verify_sim_odd  = ~^rx_data[7:3];
            verify_sim_even = ^rx_data[7:3];
        end
        6: begin
            verify_sim_odd  = ~^rx_data[7:2];
            verify_sim_even = ^rx_data[7:2];
        end
        7: begin
            verify_sim_odd  = ~^rx_data[7:1];
            verify_sim_even = ^rx_data[7:1];
        end
        8: begin
            verify_sim_odd  = ~^rx_data[7:0];
            verify_sim_even = ^rx_data[7:0];
        end
        default: begin
            verify_sim_odd  = 'd0;
            verify_sim_even = 'd0;
        end
    endcase
end
//偶校验
    // assign                              verify_sim_even           = ^rx_data;
//奇校验
    // assign                              verify_sim_odd            = ~^rx_data;
//获取校验位
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        verify_bit <= 'd0;
    else if (uart_parity_bit == 1 || uart_parity_bit == 2) begin
        if (bit_cnt == 1'b1 + uart_data_bit && bit_flag == 'd1) begin
            verify_bit <= rx_r3;
        end
    end
end
//错误计数
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        rx_parity_error_cnt <= 'd0;
    else if (uart_parity_bit == 1) begin
        if (bit_cnt == 1'b1 + uart_data_bit + 1'b1 && bit_flag && (verify_sim_odd != verify_bit)) begin
            rx_parity_error_cnt <= rx_parity_error_cnt + 'd1;
        end
    end
    else if (uart_parity_bit == 2) begin
        if (bit_cnt == 1'b1 + uart_data_bit + 1'b1 && bit_flag && (verify_sim_even != verify_bit)) begin
            rx_parity_error_cnt <= rx_parity_error_cnt + 'd1;
        end
    end
    else
        rx_parity_error_cnt <= rx_parity_error_cnt;
end
//rx_flag
always@(posedge sys_clk_i)begin
    if (uart_parity_bit == 1 || uart_parity_bit == 2) begin
        if (bit_cnt == 1'b1 + uart_data_bit + 1'b1 && bit_flag =='d1) begin
            rx_flag <= 'd1;
        end
        else
            rx_flag <= 'd0;
    end
    else begin
        if (bit_cnt == 1'b1 + uart_data_bit && bit_flag =='d1) begin
            rx_flag <= 'd1;
        end
        else
            rx_flag <= 'd0;
    end
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        rx_data_o <= 'd0;
    else if (rx_flag) begin
        rx_data_o <= rx_data;
    end
end

always@(posedge sys_clk_i)begin
    rx_data_flag_o <= rx_flag;
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// debug
//---------------------------------------------------------------------
// ila_uart_rx_debug ila_uart_rx_debug_inst (
//     .clk                                (sys_clk_i                 ),// input wire clk

//     .probe0                             (rx_r3                     ),// input wire [0:0]  probe0  
//     .probe1                             (start_negedge             ),// input wire [0:0]  probe1 
//     .probe2                             (bit_flag                  ),// input wire [0:0]  probe2 
//     .probe3                             (bit_cnt                   ),// input wire [3:0]  probe3 
//     .probe4                             (rx_parity_error_cnt       ),// input wire [3:0]  probe4 
//     .probe5                             (rx_data_flag_o            ),// input wire [0:0]  probe5 
//     .probe6                             (rx_data_o                 ) // input wire [7:0]  probe6
// );
endmodule