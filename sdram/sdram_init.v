`include "sdram_defines.v"

module sdram_init (
    input                               sys_clk_i                  ,// clk 100 mhz
    input                               rst_n_i                    ,// low active

    output reg         [   3:0]         init_cmd_o                 ,// 初始化阶段写入 sdram 的指令
    output reg         [   1:0]         init_ba_o                  ,// 初始化阶段 Bank 地址
    output reg         [  12:0]         init_addr_o                ,// 初始化阶段地址数据,辅助预充电和配置模式寄存器操作,A12-A0

    output wire                         init_end_o                  // 初始化结束信号
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// localparam
//---------------------------------------------------------------------
localparam                              TIME_125us = 12_500        ;

localparam                              INIT_IDLE = 'd0            ;// 初始状态
localparam                              INIT_PRE = 'd1             ;// 预充电状态
localparam                              INIT_TRP = 'd2             ;// 预充电d等待状态
localparam                              INIT_AR = 'd3              ;// 自动刷新状态
localparam                              INIT_TRF = 'd4             ;// 自动刷新等待状态
localparam                              INIT_MRS = 'd5             ;// 配置模式寄存器状态
localparam                              INIT_TMRD = 'd6            ;// 配置模式寄存器状态
localparam                              INIT_END = 'd7             ;// 初始化完成状态

localparam                              AUTO_REFRESH_CNT_MAX = 8   ;// 自动刷新次数
localparam                              TRP_CLK_CNT_MAX = 2        ;// 预充电等待周期数
localparam                              TRC_CLK_CNT_MAX = 8        ;// 自动刷新等待周期数
localparam                              TMRD_CLK_CNT_MAX = 3       ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// wires & regs
//---------------------------------------------------------------------
wire                                    wait_end                   ;
wire                                    trp_end                    ;// 预充电等待状态结束标志信号
wire                                    trc_end                    ;// 自动刷新等待状态结束标志信号
wire                                    tmrd_end                   ;// 自动刷新等待状态结束标志信号
reg                    [  15:0]         cnt_125us                  ;
reg                    [   2:0]         next_state                 ;
reg                    [   2:0]         cur_state                  ;
reg                    [   7:0]         cnt_clk                    ;
reg                    [   4:0]         cnt_init_auto_refresh      ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// main code
//---------------------------------------------------------------------
//第一段,状态跳转,时序逻辑
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cur_state<=INIT_IDLE;
    else
        cur_state<=next_state;
end

//第二段,跳转条件,组合逻辑
always@(*)begin
    case(cur_state)
        INIT_IDLE:                                                  // 执行空操作指令
            if (wait_end)
                next_state <= INIT_PRE;
            else
                next_state <= INIT_IDLE;
        INIT_PRE: next_state <= INIT_TRP;
        INIT_TRP:                                                   // 执行空操作指令
            if (trp_end)
                next_state <= INIT_AR;
            else
                next_state <= INIT_TRP;
        INIT_AR: next_state <= INIT_TRF;
        INIT_TRF:                                                   // 执行空操作指令
            if (trc_end && cnt_init_auto_refresh == AUTO_REFRESH_CNT_MAX)
                next_state <= INIT_MRS;
            else if (trc_end)
                next_state <= INIT_AR;
            else
                next_state <= INIT_TRF;
        INIT_MRS: next_state <= INIT_TMRD;
        INIT_TMRD:                                                  // 执行空操作指令
            if (tmrd_end)
                next_state <= INIT_END;
            else
                next_state <= INIT_TMRD;
        INIT_END: next_state <= INIT_END;                           // 初始化完成状态,保持此状态
        default: next_state <= INIT_IDLE;
    endcase
end
//---------------------------------------------------------------------
// logic
//---------------------------------------------------------------------
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cnt_125us <= 'd0;
    else if (cnt_125us < TIME_125us)
        cnt_125us <= cnt_125us + 'd1;
end

assign wait_end = (cnt_125us == TIME_125us - 1)? 'd1:'d0;

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cnt_init_auto_refresh <= 'd0;
    else if (cur_state == INIT_END)
        cnt_init_auto_refresh <= 'd0;
    else if (cur_state == INIT_AR)
        cnt_init_auto_refresh <= cnt_init_auto_refresh + 'd1;
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cnt_clk <= 'd0;
    else case (cur_state)
        INIT_TRP:
            if (trp_end)
                cnt_clk <= 'd0;
            else
                cnt_clk <= cnt_clk + 'd1;
        INIT_TRF:
            if (trc_end)
                cnt_clk <= 'd0;
            else
                cnt_clk <= cnt_clk + 'd1;
        INIT_TMRD:
            if (tmrd_end)
                cnt_clk <= 'd0;
            else
                cnt_clk <= cnt_clk + 'd1;
        default: cnt_clk <= 'd0;
    endcase
end

assign trp_end = (cur_state == INIT_TRP) & (cnt_clk == TRP_CLK_CNT_MAX - 1);

assign trc_end = (cur_state == INIT_TRF) & (cnt_clk == TRC_CLK_CNT_MAX - 1);

assign tmrd_end = (cur_state == INIT_TMRD) & (cnt_clk == TMRD_CLK_CNT_MAX - 1);

always@(*)begin
    case (cur_state)
        INIT_PRE: begin                                             // 预充电指令
            init_cmd_o <= `Precharge;
            init_ba_o <= 2'b11;
            init_addr_o <= 13'h1fff;
        end
        INIT_AR: begin                                              // 自动刷新指令
            init_cmd_o <= `Refresh;
            init_ba_o <= 2'b11;
            init_addr_o <= 13'h1fff;
        end
        INIT_MRS: begin                                             // 模式寄存器设置指令
            init_cmd_o <= `Load_Mode_Register;
            init_ba_o <= 2'b00;
            init_addr_o <= {                                        // 地址辅助配置模式寄存器,参数不同,配置的模式不同
            3'b000,                                                 // A12-A10:预留
            1'b0,                                                   // A9=0:读写方式,0:突发读&突发写,1:突发读&单写
            2'b00,                                                  // {A8,A7}=00:标准模式,默认
            3'b011,                                                 // {A6,A5,A4}=011:CAS 潜伏期,010:2,011:3,其他:保留
            1'b0,                                                   // A3=0:突发传输方式,0:顺序,1:隔行
            3'b111                                                  // {A2,A1,A0}=111:突发长度,000:单字节,001:2 字节,010:4 字节,011:8 字节,111:整页,其他:保留
            };
        end
        default: begin
            init_cmd_o <= `No_operation;
            init_ba_o <= 2'b11;
            init_addr_o <= 13'h1fff;
        end
    endcase
end

assign init_end_o = (cur_state == INIT_END);
endmodule