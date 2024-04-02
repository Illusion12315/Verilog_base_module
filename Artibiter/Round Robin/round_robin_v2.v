`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             round_robin_v2
// Create Date:           2024/04/02 20:40:44
// Version:               V1.0
// PATH:                  E:\FPGA\module_base\Artibiter\Round Robin\round_robin_v2.v
// Descriptions:          
// 
// ********************************************************************************** // 


module round_robin_v2 #(
    parameter                           REQUIRE_NUM               = 4     
) (
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,

    input              [REQUIRE_NUM-1: 0]request_i                 ,
    output             [REQUIRE_NUM-1: 0]respond_o                  
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// wires and regs
//---------------------------------------------------------------------
    wire                                req                        ;
    wire               [2*REQUIRE_NUM-1: 0]double_request          ;
    wire               [2*REQUIRE_NUM-1: 0]double_request_extension  ;

    reg                [REQUIRE_NUM-1: 0]last_request              ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// logic
//---------------------------------------------------------------------
// 任意一个通道请求
    assign                              req                       = |request_i;

// 存储移位后上一次仲裁结果
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        last_request <= 'd1;                                        //初始优先级为1
    end
    else if (req) begin                                             //对上次输出的优先级进行左移一位
        last_request <= {respond_o[REQUIRE_NUM-2:0],respond_o[REQUIRE_NUM-1]};
    end
    else
        last_request <= last_request;
end

// 需要两倍的二进制请求位宽
    assign                              double_request            = {request_i,request_i};
// 二进制请求 - 优先级
    assign                              double_request_extension  = double_request & ~(double_request - {{REQUIRE_NUM{1'b0}},last_request});
// 低位或上高位
    assign                              respond_o                 = double_request_extension[REQUIRE_NUM-1:0] | double_request_extension[2*REQUIRE_NUM-1:REQUIRE_NUM];

endmodule