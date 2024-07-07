`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             clk_select_x
// Create Date:           2024/07/07 23:46:48
// Version:               V1.0
// PATH:                  E:\FPGA\module_base\clk_rst\clk_select_x.v
// Descriptions:          
// 
// ********************************************************************************** // 
// `default_nettype none

module clk_select_x (
    input  wire                         clk_0_i                    ,
    input  wire                         clk_1_i                    ,
    input  wire                         rst_n_i                    ,
    input  wire                         select_i                   ,

    output wire                         clk_sel_o                   
);

    reg                                 select_r                   ;

always@(posedge clk_0_i or negedge rst_n_i)begin
    if (!rst_n_i)
        select_r <= 'd0;
    else
        select_r <= select_i;
end

BUFGMUX BUFGMUX_inst (
    .O                                  (clk_sel_o                 ),// 1-bit output: Clock output
    .I0                                 (clk_0_i                   ),// 1-bit input: Clock input (S=0)
    .I1                                 (clk_1_i                   ),// 1-bit input: Clock input (S=1)
    .S                                  (select_r                  ) // 1-bit input: Clock select
);

endmodule