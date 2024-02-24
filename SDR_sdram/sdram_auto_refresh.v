`include "sdram_defines.v"

module sdram_auto_refresh (
    input                               sys_clk_i                  ,// clk 100mhz
    input                               rst_n_i                    ,// low active
    
    input                               init_end_i                 ,// 初始化结束信号
    input                               auto_refresh_en_i          ,

    output                              auto_refresh_req_o         ,// 自动刷新请求
    output                              auto_refresh_end_o         ,// 自动刷新结束标志
    output reg         [   3:0]         auto_refresh_cmd_o         ,// 自动刷新阶段写入 sdram 的指令
    output             [   1:0]         auto_refresh_ba_o          ,// 自动刷新阶段 Bank 地址
    output             [  12:0]         auto_refresh_addr_o         // 地址数据,辅助预充电操作,A12-A0
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// parameter
//---------------------------------------------------------------------
localparam                              AUTO_REFRESH_TIME = 750    ;// 自动刷新等待时钟数(7.5us)

localparam                              TRP_CLK_CNT_MAX = 2        ;// 预充电等待周期数
localparam                              TRC_CLK_CNT_MAX = 8        ;// 自动刷新等待周期数
localparam                              AUTO_REFRESH_CNT_MAX = 2   ;

localparam                              AUTO_REFRESH_IDLE = 0      ;// 初始状态
localparam                              AUTO_REFRESH_PCHA = 1      ;// 预充电状态
localparam                              AUTO_REFRESH_TRP = 2       ;// 预充电d等待状态
localparam                              AUTO_REFRESH_REF = 3       ;// 自动刷新状态
localparam                              AUTO_REFRESH_TRF = 4       ;// 自动刷新等待状态
localparam                              AUTO_REFRESH_END = 5       ;// 自动刷新结束状态
// ********************************************************************************** // 
//---------------------------------------------------------------------
// wires and regs
//---------------------------------------------------------------------
wire                                    trp_end                    ;// 预充电等待状态结束标志信号
wire                                    trc_end                    ;// 自动刷新等待状态结束标志信号
reg                    [  15:0]         cnt_auto_refresh_wait      ;
reg                    [   2:0]         next_state                 ;
reg                    [   2:0]         cur_state                  ;
reg                    [   7:0]         cnt_clk                    ;
reg                    [   2:0]         cnt_auto_refresh           ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// main code
//---------------------------------------------------------------------
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cnt_auto_refresh_wait <= 'd0;
    else if (cnt_auto_refresh_wait > AUTO_REFRESH_TIME - 1)
        cnt_auto_refresh_wait <= 'd0;
    else if (init_end_i)
        cnt_auto_refresh_wait <= cnt_auto_refresh_wait + 'd1;
    else
        cnt_auto_refresh_wait <= cnt_auto_refresh_wait;
end
// request for refresh
assign auto_refresh_req_o = (cnt_auto_refresh_wait == AUTO_REFRESH_TIME - 1);

//---------------------------------------------------------------------
// ztj
//---------------------------------------------------------------------
//第一段,状态跳转,时序逻辑
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cur_state<=AUTO_REFRESH_IDLE;
    else
        cur_state<=next_state;
end

//第二段,跳转条件,组合逻辑
always@(*)begin
    case(cur_state)
        AUTO_REFRESH_IDLE:
            if (auto_refresh_en_i && init_end_i)                    //respond refresh en , then to pre charge
                next_state <= AUTO_REFRESH_PCHA;
            else
                next_state <= AUTO_REFRESH_IDLE;
        AUTO_REFRESH_PCHA: next_state <= AUTO_REFRESH_TRP;
        AUTO_REFRESH_TRP:
            if (trp_end)
                next_state <= AUTO_REFRESH_REF;
            else
                next_state <= AUTO_REFRESH_TRP;
        AUTO_REFRESH_REF: next_state <= AUTO_REFRESH_TRF;
        AUTO_REFRESH_TRF:
            if (trc_end && cnt_auto_refresh == AUTO_REFRESH_CNT_MAX)
                next_state <= AUTO_REFRESH_END;
            else if (trc_end)
                next_state <= AUTO_REFRESH_REF;
            else
                next_state <= AUTO_REFRESH_TRF;
        AUTO_REFRESH_END: next_state <= AUTO_REFRESH_IDLE;
        default: next_state <= AUTO_REFRESH_IDLE;
    endcase
end
//自动刷新计数器，每一次刷新请求，会连续刷新两次
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cnt_auto_refresh <= 'd0;
    else if (cur_state == AUTO_REFRESH_END)
        cnt_auto_refresh <= 'd0;
    else if (cur_state == AUTO_REFRESH_REF)
        cnt_auto_refresh <= cnt_auto_refresh + 'd1;
end
//周期计数器，会计数预充电等待周期，自刷新等待周期
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cnt_clk <= 'd0;
    else case (cur_state)
        AUTO_REFRESH_TRP:
            if (trp_end)
                cnt_clk <= 'd0;
            else
                cnt_clk <= cnt_clk + 'd1;
        AUTO_REFRESH_TRF:
            if (trc_end)
                cnt_clk <= 'd0;
            else
                cnt_clk <= cnt_clk + 'd1;
        default: cnt_clk <= 'd0;
    endcase
end
//预充电等待完毕标志
assign trp_end = (cur_state == AUTO_REFRESH_TRP && cnt_clk == TRP_CLK_CNT_MAX - 1);
//自刷新等待完毕标志
assign trc_end = (cur_state == AUTO_REFRESH_TRF && cnt_clk == TRC_CLK_CNT_MAX - 1);
//一次自刷新请求响应完成
assign auto_refresh_end_o = (cur_state == AUTO_REFRESH_END);

assign auto_refresh_ba_o = 2'b11;

assign auto_refresh_addr_o = 13'h1FFF;

always@(*)begin
    case (cur_state)
        AUTO_REFRESH_PCHA: auto_refresh_cmd_o <= `Precharge;
        AUTO_REFRESH_REF: auto_refresh_cmd_o <= `Refresh;
        default: auto_refresh_cmd_o <= `No_operation;
    endcase
end
endmodule