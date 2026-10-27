`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               JingNeng
// Engineer:              Chen Xiong Zhi
// 
// File name:             median_filtering.v
// Create Date:           2025/01/05 21:20:47
// Version:               V1.0
// PATH:                  math_operations\median_filtering\median_filtering.v
// Descriptions:          
// 
// ********************************************************************************** // 
`default_nettype none


module median_filtering #(
    parameter                       MEAN_FILTER_LENGTH = 1024  ,//需要是2的整数次幂，如1 2 4 8等
    parameter                       S_AXI_DATA_WIDTH   = 16    //数据位宽
) (
    input  wire                     sys_clk_i           ,
    input  wire                     rst_n_i              

    input  wire                     s_axi_data_tvalid_i ,//输入端口
    input  wire signed [S_AXI_DATA_WIDTH-1: 0]s_axi_data_tdata_i,

    output wire                     m_axi_data_tvalid_o ,//输出端口
    output wire signed [S_AXI_DATA_WIDTH-1: 0]m_axi_data_tdata_o 
);
    localparam                      RAM_ADDR           = $clog2(MEAN_FILTER_LENGTH);//log2为底的对数
// (*ram_style = block*)
    reg      signed    [S_AXI_DATA_WIDTH-1: 0]filter_data_ram[0:MEAN_FILTER_LENGTH-1]  ;//缓存寄存器，可用ram或者reg实现
    reg                [RAM_ADDR-1: 0]filter_data_ram_addr=0  ;//缓存寄存器地址
    reg      signed    [S_AXI_DATA_WIDTH+RAM_ADDR-1: 0]mean_calculate_reg='d0  ;//计算结果
    reg                             first_time_flag=0   ;//第一次有效数据
    integer                         i                   ;

    assign                          m_axi_data_tvalid_o= first_time_flag && s_axi_data_tvalid_i;
    assign                          m_axi_data_tdata_o = mean_calculate_reg[S_AXI_DATA_WIDTH+RAM_ADDR-1: RAM_ADDR];//计算均值

initial begin
    for (i = 0; i<MEAN_FILTER_LENGTH; i = i+1) begin
        filter_data_ram[i] <= 'd0;
    end
end

//依次缓存数据，并且将地址覆盖
always@(posedge sys_clk_i)begin
    if (!rst_n_i) begin
        filter_data_ram_addr <= 'd0;
    end
    else if (s_axi_data_tvalid_i) begin
        filter_data_ram_addr <= filter_data_ram_addr + 'd1;
    end
end
//缓存数据
always@(posedge sys_clk_i)begin
    if (s_axi_data_tvalid_i) begin
        filter_data_ram[filter_data_ram_addr] <= s_axi_data_tdata_i;
    end
end

always@(posedge sys_clk_i)begin
    if (!rst_n_i) begin
        first_time_flag <= 'd0;
    end
    else if (s_axi_data_tvalid_i && (filter_data_ram_addr == (1 << RAM_ADDR) - 1)) begin
        first_time_flag <= 'd1;
    end
end







endmodule


`default_nettype wire