`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             ad9833_wrapper
// Create Date:           2024/07/20 18:29:48
// Version:               V1.0
// PATH:                  
// Descriptions:          
// 
// ********************************************************************************** // 
`default_nettype none


module ad9833_wrapper #(
    parameter                           AD9833_NUM                = 6     
) (
    input  wire                         sys_clk_i                  ,// clk100m
    input  wire                         rst_n_i                    ,

    input  wire                         start_cfg_pluse_i          ,

    output reg         [AD9833_NUM-1: 0]AD9833_SCLK                ,// max clk40m
    output reg         [AD9833_NUM-1: 0]AD9833_FSYNC               ,
    output reg         [AD9833_NUM-1: 0]AD9833_SDATA                
);

    wire                                start_pluse                ;
    wire               [  15: 0]        ad9833_cfg_data            ;
    wire                                ad9833_bus_busy            ;
    wire                                ad9833_cfg_done            ;
    wire                                SCLK                       ;
    wire                                FSYNC                      ;
    wire                                SDATA                      ;

    reg                [   3: 0]        cfg_cnt                    ;
    reg                                 cfg_en                     ;
    reg                                 start_cfg_pluse_num        ;

    reg                                 start_cfg_pluse_r1,start_cfg_pluse_r2  ;


always@(posedge sys_clk_i)begin
    start_cfg_pluse_r1 <= start_cfg_pluse_i;
    start_cfg_pluse_r2 <= start_cfg_pluse_r1;
end

always@(posedge sys_clk_i)begin
    if (!rst_n_i) begin
        cfg_en <= 'd0;
    end
    else if (cfg_cnt == AD9833_NUM - 1) begin
        cfg_en <= 'd0;
    end
    else if (start_cfg_pluse_r1 & ~start_cfg_pluse_r2) begin
        cfg_en <= 'd1;
    end
end

always@(posedge sys_clk_i)begin
    if (!rst_n_i) begin
        start_cfg_pluse_num <= 'd0;
    end
    else if (cfg_en) begin
        start_cfg_pluse_num <= 'd1;
    end
    else
        start_cfg_pluse_num <= 'd0;
end

always@(posedge sys_clk_i)begin
    if (!rst_n_i) begin
        cfg_cnt <= 'd0;
    end
    else if (ad9833_cfg_done && cfg_cnt == AD9833_NUM - 1) begin
        cfg_cnt <= 'd0;
    end
    else if (cfg_en && ad9833_cfg_done) begin
        cfg_cnt <= cfg_cnt + 'd1;
    end
end

always@(posedge sys_clk_i)begin
    AD9833_SCLK [cfg_cnt] <= SCLK ;
    AD9833_FSYNC[cfg_cnt] <= FSYNC;
    AD9833_SDATA[cfg_cnt] <= SDATA;
end

ad9833_ctrl u_ad9833_ctrl(
    .sys_clk_i                          (sys_clk_i                 ),// clk100m
    .rst_n_i                            (rst_n_i                   ),
    .start_cfg_pluse_i                  (start_cfg_pluse_num       ),
    .start_pluse_o                      (start_pluse               ),
    .ad9833_cfg_data_o                  (ad9833_cfg_data           ),// 3k hz . sin(x)
    .ad9833_cfg_done_o                  (ad9833_cfg_done           ),
    .ad9833_bus_busy_i                  (ad9833_bus_busy           ) 
);

ad9833_engine u_ad9833_engine(
    .sys_clk_i                          (sys_clk_i                 ),// clk100m
    .rst_n_i                            (rst_n_i                   ),
    .start_pluse_i                      (start_pluse               ),
    .ad9833_cfg_data_i                  (ad9833_cfg_data           ),// 3k hz . sin(x)
    .SCLK                               (SCLK                      ),// max clk40m
    .FSYNC                              (FSYNC                     ),
    .SDATA                              (SDATA                     ),
    .ad9833_bus_busy_o                  (ad9833_bus_busy           ) 
);


// ********************************************************************************** // 
//---------------------------------------------------------------------
// debug
//---------------------------------------------------------------------
ila_ad9833 ila_ad9833_inst (
    .clk                                (sys_clk_i                 ),// input wire clk

    .probe0                             (AD9833_SCLK               ),// input wire [5:0]  probe0  
    .probe1                             (AD9833_FSYNC              ),// input wire [5:0]  probe1 
    .probe2                             (AD9833_SDATA              ),// input wire [5:0]  probe2 
    .probe3                             (cfg_cnt                   ),// input wire [3:0]  probe3 
    .probe4                             (cfg_en                    ),// input wire [0:0]  probe4 
    .probe5                             (ad9833_cfg_data           ),// input wire [15:0]  probe5 
    .probe6                             (start_pluse               ),// input wire [0:0]  probe6 
    .probe7                             (ad9833_bus_busy           ) // input wire [0:0]  probe7
);


endmodule


`default_nettype wire