`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             clk_select_v
// Create Date:           2024/07/07 23:13:58
// Version:               V1.0
// PATH:                  E:\FPGA\module_base\clk_rst\clk_select_v.v
// Descriptions:          
// 
// ********************************************************************************** // 
// `default_nettype none

module clk_select_v (
    input  wire                         clk_0_i                    ,
    input  wire                         clk_1_i                    ,
    input  wire                         rst_n_i                    ,
    input  wire                         select_i                   ,

    output reg                          clk_sel_o                   
);
    reg                                 clk_1_r,clk_1_en           ;
    reg                                 clk_0_r,clk_0_en           ;
    
always@(posedge clk_1_i or negedge rst_n_i) begin
    if(!rst_n_i)
        clk_1_r <= 0;
    else
        clk_1_r <= select_i & ~clk_0_en;
end

always@(negedge clk_1_i or negedge rst_n_i) begin
    if(!rst_n_i)
        clk_1_en <= 0;
    else
        clk_1_en <= clk_1_r;
end

always@(posedge clk_0_i or negedge rst_n_i) begin
    if(!rst_n_i)
        clk_0_r <= 0;
    else
        clk_0_r <= ~select_i & ~clk_1_en;
end

always@(posedge clk_0_i or negedge rst_n_i) begin
    if(!rst_n_i)
        clk_0_en <= 0;
    else
        clk_0_en <= clk_0_r;
end

    assign                              outclk                    = (clk_0_en & clk_0_i) | (clk_1_en & clk_1_i);

endmodule