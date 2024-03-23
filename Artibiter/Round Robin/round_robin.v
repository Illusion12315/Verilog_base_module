`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             round_robin
// Create Date:           2024/03/22 23:20:11
// Version:               V1.0
// PATH:                  E:\FPGA\module_base\Artibiter\Round Robin\round_robin.v
// Descriptions:          
// 
// ********************************************************************************** // 

module round_robin #(
    parameter                           REQUIRE_NUM               = 4     // it should be two to the power
) (
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,

    input              [REQUIRE_NUM-1: 0]request_i                 ,
    output reg         [REQUIRE_NUM-1: 0]respond_o                  
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// wires and regs
//---------------------------------------------------------------------
    wire                                req                        ;
    wire               [REQUIRE_NUM-1: 0]priority_w                ;
    reg                [REQUIRE_NUM+REQUIRE_NUM-1: 0]request_shield  ;
    reg                [REQUIRE_NUM+REQUIRE_NUM-1: 0]request_shield_negation  ;
    reg                [$clog2(REQUIRE_NUM)-1: 0]req_cnt           ;
    reg                [REQUIRE_NUM+REQUIRE_NUM-1: 0]respond_r     ;
    integer                             i                          ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// assigns
//---------------------------------------------------------------------
    assign                              req                       = |request_i;
    assign                              priority_w                = bin2onehot(req_cnt);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// logic
//---------------------------------------------------------------------
// 经典平均循环算法
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        req_cnt <= 'd0;
    end
    else if (req) begin
        req_cnt <= req_cnt + 'd1;
    end
end
// 二进制请求 - 优先级
always@(*)begin
    request_shield = {request_i,request_i} - {{REQUIRE_NUM{1'b0}},priority_w};
end
// 按位取反
always@(*)begin
    request_shield_negation = ~request_shield;
end
// 相与
always@(*)begin
    respond_r = request_shield_negation & {request_i,request_i};
end
// 输出
always@(*)begin
    respond_o = respond_r[REQUIRE_NUM+REQUIRE_NUM-1 -:REQUIRE_NUM] | respond_r[REQUIRE_NUM-1 -:REQUIRE_NUM];
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// functions
//---------------------------------------------------------------------
function   [REQUIRE_NUM-1: 0] bin2onehot;
    input              [$clog2(REQUIRE_NUM)-1: 0]bin               ;
    assign                              bin2onehot                = ({REQUIRE_NUM{1'b0}}+1'b1) << bin;
endfunction

endmodule