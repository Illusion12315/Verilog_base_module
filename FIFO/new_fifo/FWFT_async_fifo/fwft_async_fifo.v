`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             fwft_async_fifo
// Create Date:           2024/04/11 22:15:31
// Version:               V1.0
// PATH:                  E:\FPGA\module_base\FIFO\new_fifo\FWFT_async_fifo\fwft_async_fifo.v
// Descriptions:          
// 
// ********************************************************************************** // 


module fwft_async_fifo #(
    parameter                           FIFO_DEEP                 = 1024  ,
    parameter                           DATA_WIDTH                = 8     ,
    parameter                           PROG_FULL_NUM             = 1000  ,
    parameter                           PROG_EMPTY_NUM            = 4     
) (
    input                               wr_clk_i                   ,
    input                               wr_rst_n_i                 ,
    input                               wr_en_i                    ,
    input              [DATA_WIDTH-1: 0]din                        ,
    output                              prog_full                  ,
    output                              full                       ,
    output             [clogb2(FIFO_DEEP): 0]wr_fifo_num           ,

    input                               rd_clk_i                   ,
    input                               rd_rst_n_i                 ,
    input                               rd_en_i                    ,
    output reg         [DATA_WIDTH-1: 0]dout                       ,
    output                              prog_empty                 ,
    output                              empty                      ,
    output             [clogb2(FIFO_DEEP): 0]rd_fifo_num            
);
//-----------------------------------------
//--function customrize
//-----------------------------------------
// clacluate the logarithm of base two
// for example, b = 8, a = clogb2(b) = 4
function integer clogb2;
    input                               integer number             ;
    begin
        for (clogb2 = 0; number>1; clogb2=clogb2+1) begin
            number = number >> 1;
        end
    end
endfunction
// ********************************************************************************** // 
//---------------------------------------------------------------------
// wires and regs
//---------------------------------------------------------------------
    localparam                          FIFO_DEEP_WIDTH           = clogb2(FIFO_DEEP);
    genvar i;
    integer j;

    wire               [FIFO_DEEP_WIDTH-1: 0]wr_addr               ;
    wire               [FIFO_DEEP_WIDTH-1: 0]rd_addr               ;

    reg                [FIFO_DEEP_WIDTH: 0]wr_addr_extension       ;
    wire               [FIFO_DEEP_WIDTH: 0]wr_addr_extension_gray  ;
    reg                [FIFO_DEEP_WIDTH: 0]wr_addr_extension_gray_sync_rd_clk_r1  ;
    reg                [FIFO_DEEP_WIDTH: 0]wr_addr_extension_gray_sync_rd_clk_r2  ;
    wire               [FIFO_DEEP_WIDTH: 0]wr_addr_extension_sync_rd  ;

    reg                [FIFO_DEEP_WIDTH: 0]rd_addr_extension       ;
    wire               [FIFO_DEEP_WIDTH: 0]rd_addr_extension_gray  ;
    reg                [FIFO_DEEP_WIDTH: 0]rd_addr_extension_gray_sync_wr_clk_r1  ;
    reg                [FIFO_DEEP_WIDTH: 0]rd_addr_extension_gray_sync_wr_clk_r2  ;
    wire               [FIFO_DEEP_WIDTH: 0]rd_addr_extension_sync_wr  ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// assigns
//---------------------------------------------------------------------
    assign                              wr_addr                   = wr_addr_extension[FIFO_DEEP_WIDTH-1: 0];
    assign                              rd_addr                   = rd_addr_extension[FIFO_DEEP_WIDTH-1: 0];

    assign                              wr_fifo_num               = wr_addr_extension - rd_addr_extension_sync_wr;
    assign                              rd_fifo_num               = wr_addr_extension_sync_rd - rd_addr_extension;

    assign                              full                      = (wr_fifo_num == FIFO_DEEP) | ((wr_fifo_num == FIFO_DEEP - 1) & wr_en_i);
    assign                              empty                     = (rd_fifo_num == 0) | ((rd_fifo_num == 1) & rd_en_i);

    assign                              prog_full                 = (wr_fifo_num >= PROG_FULL_NUM) | ((wr_fifo_num == PROG_FULL_NUM - 1) & wr_en_i);
    assign                              prog_empty                = (rd_fifo_num <= PROG_EMPTY_NUM) | ((rd_fifo_num == PROG_EMPTY_NUM + 1) & rd_en_i);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// wr addr customrize
//---------------------------------------------------------------------
// wr addr should add 1 when wr_en_i is valid
always@(posedge wr_clk_i or negedge wr_rst_n_i)begin
    if (!wr_rst_n_i)
        wr_addr_extension <= 'd0;
    else if (wr_en_i)
        wr_addr_extension <= wr_addr_extension + 'd1;
    else
        wr_addr_extension <= wr_addr_extension;
end
// wr_addr bin2gray
    assign                              wr_addr_extension_gray    = (wr_addr_extension >> 1) ^ wr_addr_extension;
// sync wr_addr to rd clk
always@(posedge rd_clk_i or negedge rd_rst_n_i)begin
    if (!rd_rst_n_i) begin
        wr_addr_extension_gray_sync_rd_clk_r1 <= 'd0;
        wr_addr_extension_gray_sync_rd_clk_r2 <= 'd0;
    end
    else begin
        wr_addr_extension_gray_sync_rd_clk_r1 <= wr_addr_extension_gray;
        wr_addr_extension_gray_sync_rd_clk_r2 <= wr_addr_extension_gray_sync_rd_clk_r1;
    end
end
// gray2bin
    assign                              wr_addr_extension_sync_rd[FIFO_DEEP_WIDTH]= wr_addr_extension_gray_sync_rd_clk_r2[FIFO_DEEP_WIDTH];
generate
    for (i = 0; i<FIFO_DEEP_WIDTH; i=i+1) begin
    assign                              wr_addr_extension_sync_rd[i]= wr_addr_extension_gray_sync_rd_clk_r2[i] ^ wr_addr_extension_sync_rd[i+1];
    end
endgenerate
// ********************************************************************************** // 
//---------------------------------------------------------------------
// rd addr customrize
//---------------------------------------------------------------------
// rd addr should add 1 when rd_en_i is valid
always@(posedge rd_clk_i or negedge rd_rst_n_i)begin
    if (!rd_rst_n_i)
        rd_addr_extension <= 'd0;
    else if (rd_en_i)
        rd_addr_extension <= rd_addr_extension + 'd1;
    else
        rd_addr_extension <= rd_addr_extension;
end
// wr_addr bin2gray
    assign                              rd_addr_extension_gray    = (rd_addr_extension >> 1) ^ rd_addr_extension;
// sync wr_addr to rd clk
always@(posedge wr_clk_i or negedge wr_rst_n_i)begin
    if (!wr_rst_n_i) begin
        rd_addr_extension_gray_sync_wr_clk_r1 <= 'd0;
        rd_addr_extension_gray_sync_wr_clk_r2 <= 'd0;
    end
    else begin
        rd_addr_extension_gray_sync_wr_clk_r1 <= rd_addr_extension_gray;
        rd_addr_extension_gray_sync_wr_clk_r2 <= rd_addr_extension_gray_sync_wr_clk_r1;
    end
end
// gray2bin
    assign                              rd_addr_extension_sync_wr[FIFO_DEEP_WIDTH]= rd_addr_extension_gray_sync_wr_clk_r2[FIFO_DEEP_WIDTH];
generate
    for (i = 0; i<FIFO_DEEP_WIDTH; i=i+1) begin
    assign                              rd_addr_extension_sync_wr[i]= rd_addr_extension_gray_sync_wr_clk_r2[i] ^ rd_addr_extension_sync_wr[i+1];
    end
endgenerate
// ********************************************************************************** // 
//---------------------------------------------------------------------
// simple double port ram
//---------------------------------------------------------------------
    reg                [DATA_WIDTH-1: 0]ram[0:FIFO_DEEP-1]         ;

initial begin
    for (j = 0; j < FIFO_DEEP; j = j+1) begin
        ram[j] <= 8'd0;
    end
end

always@(posedge wr_clk_i or negedge wr_rst_n_i)begin
    if (!wr_rst_n_i)
        ram[wr_addr] <= 'd0;
    else if (wr_en_i)
        ram[wr_addr] <= din;
end

always@(posedge rd_clk_i or negedge rd_rst_n_i)begin
    if (!rd_rst_n_i)
        dout <= 'hx;
    else if (rd_en_i)
        dout <= ram[rd_addr];
    else
        dout <= 'hx;
end
endmodule