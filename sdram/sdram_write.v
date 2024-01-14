`include "sdram_defines.v"

module sdram_write (
    input                               sys_clk_i                  ,// clk 100 mhz
    input                               rst_n_i                    ,// low active

    input                               init_end_i                 ,// 初始化结束信号

    input                               wr_en_i                    ,// 数据写使能信号
    input              [  23:0]         wr_addr_i                  ,// 数据写阶段地址输入 Row address: A0~A12 Column address: A0~A8 [addr] = {bank[23:22],row[21:9],column[8:0]}
    input              [  15:0]         wr_data_i                  ,// 数据写阶段数据输入
    input              [   9:0]         wr_burst_lenth_i           ,// 写突发长度,具体数值可根据实际情况设定，但不能超过 SDRAM 芯片一行包含存储单元的个数

    output                              wr_ack_o                   ,// 数据写操作响应 拉高才能更新数据
    output                              wr_end_o                   ,// 一次突发写结束

    output reg         [   3:0]         write_cmd_o                ,// 数据写阶段指令
    output reg         [   1:0]         write_ba_o                 ,// 数据写阶段逻辑 Bank 地址
    output reg         [  12:0]         write_addr_o               ,// 数据写阶段地址输出

    output                              wr_sdram_en_o              ,// 数据写阶段数据输出使能
    output             [  15:0]         wr_sdram_data_o             // 数据写阶段数据输出
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// parameter
//---------------------------------------------------------------------
localparam                              WR_IDLE = 0                ;// 初始化状态
localparam                              WR_ACTIVE = 1              ;// 激活状态
localparam                              WR_TRCD = 2                ;// 激活等待状态,需要等待一定时间
localparam                              WR_WRITE = 3               ;// 写指令状态
localparam                              WR_DATA = 4                ;// 写数据状态
localparam                              WR_PRE = 5                 ;// 预充电状态
localparam                              WR_TRP = 6                 ;// 预充电等待状态
localparam                              WR_END = 7                 ;// 写结束状态

localparam                              TRCD_CLK_CNT_MAX = 2       ;// 激活等待周期数
localparam                              TRP_CLK_CNT_MAX = 2        ;// 预充电等待周期数
// ********************************************************************************** // 
//---------------------------------------------------------------------
// wires and regs
//---------------------------------------------------------------------
wire                                    trcd_end                   ;
wire                                    twrite_end                 ;
wire                                    trp_end                    ;

reg                    [   2:0]         next_state                 ;
reg                    [   2:0]         cur_state                  ;
reg                    [   9:0]         cnt_clk                    ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// main code
//---------------------------------------------------------------------
//第一段,状态跳转,时序逻辑
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cur_state<=WR_IDLE;
    else
        cur_state<=next_state;
end

//第二段,跳转条件,组合逻辑
always@(*)begin
    case(cur_state)
        WR_IDLE:
            if (wr_en_i && init_end_i)
                next_state <= WR_ACTIVE;
            else
                next_state <= WR_IDLE;
        WR_ACTIVE: next_state <= WR_TRCD;
        WR_TRCD:
            if (trcd_end)
                next_state <= WR_WRITE;
            else
                next_state <= WR_TRCD;
        WR_WRITE: next_state <= WR_DATA;
        WR_DATA:
            if (twrite_end)
                next_state <= WR_PRE;
            else
                next_state <= WR_DATA;
        WR_PRE: next_state <= WR_TRP;
        WR_TRP:
            if (trp_end)
                next_state <= WR_END;
            else
                next_state <= WR_TRP;
        WR_END: next_state <= WR_IDLE;
        default: next_state <= WR_IDLE;
    endcase
end
//周期计数器
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cnt_clk <= 'd0;
    else case (cur_state)
        WR_TRCD:
            if (trcd_end)
                cnt_clk <= 'd0;
            else
                cnt_clk <= cnt_clk + 'd1;
        WR_DATA:
            if (twrite_end)
                cnt_clk <= 'd0;
            else
                cnt_clk <= cnt_clk + 'd1;
        WR_TRP:
            if (trp_end)
                cnt_clk <= 'd0;
            else
                cnt_clk <= cnt_clk + 'd1;
        default: cnt_clk <= 'd0;
    endcase
end

assign trcd_end = (cur_state == WR_TRCD && cnt_clk == TRCD_CLK_CNT_MAX - 1);

assign twrite_end = (cur_state == WR_DATA && cnt_clk == wr_burst_lenth_i - 1);

assign trp_end = (cur_state == WR_TRP && cnt_clk == TRP_CLK_CNT_MAX - 1);

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        write_cmd_o <= `No_operation;
        write_ba_o <= 2'b11;
        write_addr_o <= 13'h1FFF;
    end
    else case (cur_state)
        WR_ACTIVE: begin
            write_cmd_o <= `Bank_Active;
            write_ba_o <= wr_addr_i[23:22];                         // bank
            write_addr_o <= wr_addr_i[21:9];                        // row
        end
        WR_WRITE: begin
            write_cmd_o <= `Write;
            write_ba_o <= wr_addr_i[23:22];                         // bank
            write_addr_o <= {4'b0000,wr_addr_i[8:0]};               // Column
        end
        WR_DATA: begin
            if (twrite_end) begin
                write_cmd_o <= `Burst_Terminate;
                write_ba_o <= 2'b11;
                write_addr_o <= 13'h1FFF;
            end
            else begin
                write_cmd_o <= `No_operation;
                write_ba_o <= 2'b11;
                write_addr_o <= 13'h1FFF;
            end
        end
        WR_PRE: begin
            write_cmd_o <= `Precharge;
            write_ba_o <= wr_addr_i[23:22];
            write_addr_o <= 13'h0400;
        end
        default: begin
            write_cmd_o <= `No_operation;
            write_ba_o <= 2'b11;
            write_addr_o <= 13'h1FFF;
        end
    endcase
end

assign wr_ack_o = (cur_state == WR_DATA);

assign wr_end_o = (cur_state == WR_END);

assign wr_sdram_en_o = (cur_state == WR_DATA);

assign wr_sdram_data_o = (cur_state == WR_DATA)? wr_data_i:'d0;

endmodule