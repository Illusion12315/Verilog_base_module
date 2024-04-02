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
// ����һ��ͨ������
    assign                              req                       = |request_i;

// �洢��λ����һ���ٲý��
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        last_request <= 'd1;                                        //��ʼ���ȼ�Ϊ1
    end
    else if (req) begin                                             //���ϴ���������ȼ���������һλ
        last_request <= {respond_o[REQUIRE_NUM-2:0],respond_o[REQUIRE_NUM-1]};
    end
    else
        last_request <= last_request;
end

// ��Ҫ�����Ķ���������λ��
    assign                              double_request            = {request_i,request_i};
// ���������� - ���ȼ�
    assign                              double_request_extension  = double_request & ~(double_request - {{REQUIRE_NUM{1'b0}},last_request});
// ��λ���ϸ�λ
    assign                              respond_o                 = double_request_extension[REQUIRE_NUM-1:0] | double_request_extension[2*REQUIRE_NUM-1:REQUIRE_NUM];

endmodule