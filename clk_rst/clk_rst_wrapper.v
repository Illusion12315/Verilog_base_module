`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             clk_rst_wrapper
// Create Date:           2024/07/07 22:49:28
// Version:               V1.0
// PATH:                  E:\FPGA\module_base\clk_rst\clk_rst_wrapper.v
// Descriptions:          
// 
// ********************************************************************************** // 
// `default_nettype none

module clk_rst_wrapper (
    input  wire                         sys_clk_i                  ,

    output wire                         clk50m                     ,
    output wire                         clk100m                    ,
    output reg                          hw_arst_n_o                ,
    output reg                          sw_arst_n_o                 
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// declarations
//---------------------------------------------------------------------
    localparam                          time_1s                   = 50_000_000;

    wire                                vio_rst_n                  ;
    reg                [  27: 0]        clk_cnt                    ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// clock
//---------------------------------------------------------------------
clk_wiz_0 clk_wiz_0_inst (
    // Clock out ports
    .clk_out1                           (clk50m                    ),// output clk_out1
    .clk_out2                           (clk100m                   ),// output clk_out2
    // Status and control signals
    .reset                              (1'd0                      ),// input reset
    .locked                             (locked                    ),// output locked
    // Clock in ports
    .clk_in1                            (sys_clk_i                 ) // input clk_in1
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// reset
//---------------------------------------------------------------------
// the reset starts within 1s of power-on and then reset is released
always@(posedge clk50m or negedge locked)begin
    if (!locked)
        clk_cnt <= 'd0;
    else if(clk_cnt == time_1s-'d1)
        clk_cnt <= clk_cnt;
    else
        clk_cnt <= clk_cnt+'d1;
end
// hardware asynchronous reset
always@(posedge clk50m or negedge locked)begin
    if (!locked)
        hw_arst_n_o <= 'd0;
    else if(clk_cnt == time_1s-'d1)
        hw_arst_n_o <= 'd1;
    else
        hw_arst_n_o <= 'd0;
end
// software asynchronous reset
always@(posedge clk50m or negedge hw_arst_n_o)begin
    if (!hw_arst_n_o)
        sw_arst_n_o <= 'd0;
    else
        sw_arst_n_o <= vio_rst_n;
end

// ********************************************************************************** // 
//---------------------------------------------------------------------
// debug
//---------------------------------------------------------------------
vio_clk_rst vio_clk_rst_inst (
    .clk                                (clk50m                    ),// input clk

    .probe_out0                         (vio_rst_n                 ) 
);

endmodule