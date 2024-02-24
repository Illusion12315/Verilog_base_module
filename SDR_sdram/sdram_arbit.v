`include "sdram_defines.v"

module sdram_arbit (
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,
    // init
    input  wire        [   3:0]         init_cmd_i                 ,// 初始化阶段写入 sdram 的指令
    input  wire        [   1:0]         init_ba_i                  ,// 初始化阶段 Bank 地址
    input  wire        [  12:0]         init_addr_i                ,// 初始化阶段地址数据,辅助预充电和配置模式寄存器操作,A12-A0
    input  wire                         init_end_i                 ,// 初始化结束信号
    // auto refresh
    input                               auto_refresh_req_i         ,// 自动刷新请求
    input                               auto_refresh_end_i         ,// 自动刷新结束标志
    input  wire        [   3:0]         auto_refresh_cmd_i         ,// 自动刷新阶段写入 sdram 的指令
    input              [   1:0]         auto_refresh_ba_i          ,// 自动刷新阶段 Bank 地址
    input              [  12:0]         auto_refresh_addr_i        ,// 地址数据,辅助预充电操作,A12-A0
    output                              auto_refresh_en_o          ,// 自动刷新使能
    // write
    input                               wr_req_i                   ,// 写请求 来自外部
    input                               wr_end_i                   ,// 一次突发写结束

    input  wire        [   3:0]         write_cmd_i                ,// 数据写阶段指令
    input  wire        [   1:0]         write_ba_i                 ,// 数据写阶段逻辑 Bank 地址
    input  wire        [  12:0]         write_addr_i               ,// 数据写阶段地址输出

    input                               wr_sdram_en_i              ,// 数据写阶段数据输出使能
    input              [  15:0]         wr_sdram_data_i            ,// 数据写阶段数据输出
    
    output                              wr_en_o                    ,// 数据写使能信号
    // read
    input                               rd_req_i                   ,
    input                               rd_end_i                   ,// 一次突发读结束

    input  wire        [   3:0]         read_cmd_i                 ,// 数据读阶段指令
    input  wire        [   1:0]         read_ba_i                  ,// 数据读阶段逻辑 Bank 地址
    input  wire        [  12:0]         read_addr_i                ,// 数据读阶段地址输出
    
    output                              rd_en_o                    ,// 数据读使能信号
    output             [  15:0]         rd_data_o                  ,// 数据读阶段数据输入
    // sdram ctrl interface
    output reg         [   1:0]         sdram_ba_o                 ,
    output reg         [  12:0]         sdram_addr_o               ,
    output                              sdram_dq_en_o              ,
    output             [  15:0]         sdram_dq_o                 ,
    input              [  15:0]         sdram_dq_i                 ,
    output                              sdram_cke_o                ,
    output                              sdram_cs_n_o               ,
    output                              sdram_ras_n_o              ,
    output                              sdram_cas_n_o              ,
    output                              sdram_we_n_o                

);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// localparam
//---------------------------------------------------------------------
localparam                              ARBIT_IDLE = 0             ;
localparam                              ARBIT_ARBIT = 1            ;
localparam                              ARBIT_AUTO_REFRESH = 2     ;
localparam                              ARBIT_WRITE = 3            ;
localparam                              ARBIT_READ = 4             ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// regs
//---------------------------------------------------------------------
reg                    [   2:0]         next_state                 ;
reg                    [   2:0]         cur_state                  ;
reg                    [   3:0]         sdram_cmd                  ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// main code
//---------------------------------------------------------------------
//第一段,状态跳转,时序逻辑
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cur_state<=ARBIT_IDLE;
    else
        cur_state<=next_state;
end

//第二段,跳转条件,组合逻辑
always@(*)begin
    case(cur_state)
        ARBIT_IDLE:
            if (init_end_i)
                next_state <= ARBIT_ARBIT;
            else
                next_state <= ARBIT_IDLE;
        ARBIT_ARBIT:
            if (auto_refresh_req_i)
                next_state <= ARBIT_AUTO_REFRESH;
            else if (wr_req_i)
                next_state <= ARBIT_WRITE;
            else if (rd_req_i)
                next_state <= ARBIT_READ;
            else
                next_state <= ARBIT_ARBIT;
        ARBIT_AUTO_REFRESH:
            if (auto_refresh_end_i)
                next_state <= ARBIT_ARBIT;
            else
                next_state <= ARBIT_AUTO_REFRESH;
        ARBIT_WRITE:
            if (wr_end_i)
                next_state <= ARBIT_ARBIT;
            else
                next_state <= ARBIT_WRITE;
        ARBIT_READ:
            if (rd_end_i)
                next_state <= ARBIT_ARBIT;
            else
                next_state <= ARBIT_READ;
        default: next_state <= ARBIT_IDLE;
    endcase
end

// auto refresh
assign auto_refresh_en_o = (cur_state == ARBIT_AUTO_REFRESH);
// write
assign wr_en_o = (cur_state == ARBIT_WRITE);
// read
assign rd_en_o = (cur_state == ARBIT_READ);

assign {sdram_cs_n_o,sdram_ras_n_o,sdram_cas_n_o,sdram_we_n_o} = sdram_cmd;

always@(*)begin
    case (cur_state)
        ARBIT_IDLE: begin
            sdram_cmd <= init_cmd_i;
            sdram_ba_o <= init_ba_i;
            sdram_addr_o <= init_addr_i;
        end
        ARBIT_ARBIT: begin
            sdram_cmd <= `No_operation;
            sdram_ba_o <= 2'b11;
            sdram_addr_o <= 13'h1FFF;
        end
        ARBIT_AUTO_REFRESH: begin
            sdram_cmd <= auto_refresh_cmd_i;
            sdram_ba_o <= auto_refresh_ba_i;
            sdram_addr_o <= auto_refresh_addr_i;
        end
        ARBIT_WRITE: begin
            sdram_cmd <= write_cmd_i;
            sdram_ba_o <= write_ba_i;
            sdram_addr_o <= write_addr_i;
        end
        ARBIT_READ: begin
            sdram_cmd <= read_cmd_i;
            sdram_ba_o <= read_ba_i;
            sdram_addr_o <= read_addr_i;
        end
        default: begin
            sdram_cmd <= `No_operation;
            sdram_ba_o <= 2'b11;
            sdram_addr_o <= 13'h1FFF;
        end
    endcase
end

assign sdram_dq_en_o = wr_sdram_en_i;

assign sdram_dq_o = (wr_sdram_en_i)? wr_sdram_data_i:'d0;

assign rd_data_o = sdram_dq_i;
endmodule