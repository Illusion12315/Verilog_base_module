// -----------------------------------------------------------------------------
// File   : rr_arbiter.v
// Brief  : 轮询 (round-robin) 仲裁器, 带"事务级锁定"
//          - req  : 各路请求
//          - done : 当前事务结束脉冲 -> 释放锁定, 并把轮询指针推进到
//                   刚服务通道的下一路, 保证公平
//          - 已发出的 grant 在 done 到达之前保持不变, 不受 req 抖动影响
// Reset  : rstn 低有效
// Note   : 采用"旋转掩码 + 固定优先级"实现严格轮询:
//          把 req 复制成 2N 位并按 rr_ptr 旋转, 取低 N 位的最低置位 bit,
//          即得到从 rr_ptr 起的第一个有效请求; 支持 N 非 2 的幂。
//          端口采用非 ANSI 风格, 以便 grant_idx 使用模块内 localparam 定宽。
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module rr_arbiter (
    clk,
    rstn,
    req,
    done,
    grant,
    grant_idx
);

    // -------------------------------------------------------------------------
    // clog2 : ceil(log2(x))
    // -------------------------------------------------------------------------
    function integer clog2;
        input integer value;
        integer       tmp;
        begin
            tmp   = value - 1;
            clog2 = 0;
            while (tmp > 0) begin
                tmp   = tmp >> 1;
                clog2 = clog2 + 1;
            end
        end
    endfunction

    parameter integer N     = 4;
    localparam integer IDX_W = (N > 1) ? clog2(N) : 1;

    // -------------------------------------------------------------------------
    // 端口
    // -------------------------------------------------------------------------
    input  wire            clk;
    input  wire            rstn;

    input  wire [N-1:0]    req;              // 请求
    input  wire            done;             // 当前事务完成脉冲

    output reg  [N-1:0]    grant;            // one-hot 授权
    output reg  [IDX_W-1:0] grant_idx;       // 二进制授权编号

    // -------------------------------------------------------------------------
    // 内部信号
    // -------------------------------------------------------------------------
    reg              busy;                   // 事务锁定中
    reg  [IDX_W-1:0] rr_ptr;                 // 轮询起点
    reg  [IDX_W-1:0] rr_next;                // grant_idx + 1 (模 N)

    reg  [2*N-1:0]   req2;
    reg  [N-1:0]     rot_lo;                 // 旋转后的低 N 位请求
    reg  [N-1:0]     win;                    // rot_lo 的最低置位 bit (偏移量域)
    reg  [N-1:0]     g_next;                 // 待锁存的 one-hot 授权
    reg  [IDX_W-1:0] idx_next;               // 待锁存的授权编号

    integer k;
    integer idx_i;
    integer ptr_i;

    // -------------------------------------------------------------------------
    // 目的 : 求当前 RR 优先级下的胜者 (偏移量域)
    // -------------------------------------------------------------------------
    always @* begin
        req2   = {req, req} >> rr_ptr;
        rot_lo = req2[N-1:0];
        win    = rot_lo & (-rot_lo);         // 取最低置位 bit
    end

    // -------------------------------------------------------------------------
    // 偏移量域 -> 通道编号域
    // -------------------------------------------------------------------------
    always @* begin
        g_next   = {N{1'b0}};
        idx_next = {IDX_W{1'b0}};
        for (k = 0; k < N; k = k + 1) begin
            if (win[k]) begin
                idx_i = rr_ptr + k;
                if (idx_i >= N) begin
                    idx_i = idx_i - N;
                end
                g_next[idx_i]  = 1'b1;
                idx_next       = idx_i[IDX_W-1:0];
            end
        end
    end

    // -------------------------------------------------------------------------
    // 轮询指针下一位 (模 N)
    //   以"本次即将授权的通道 +1"为下一次仲裁起点:
    //   必须在发出授权的同时推进, 否则新 grant 仍会用旧指针算出同一个通道
    // -------------------------------------------------------------------------
    always @* begin
        ptr_i   = idx_next + 1;
        if (ptr_i >= N) begin
            ptr_i = ptr_i - N;
        end
        rr_next = ptr_i[IDX_W-1:0];
    end

    // -------------------------------------------------------------------------
    // 状态机 (流水线友好结构)
    //   grant_en : 本拍可更新授权寄存器 (空闲期每拍重仲裁 / 锁定期仅 done 时更新)
    //   rr_ptr   : 只在"确实颁发新授权"时推进到其下一路; 无新胜者时保持原值
    //   相比"if (done) rr_ptr <= rr_next" 的写法, 把 done 从 rr_ptr 的
    //   D-O 组合路径中摘出, 只挂在 CE 上 -> 缩短关键路径
    // -------------------------------------------------------------------------
    wire grant_en = (busy & done) | ~busy;

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            busy      <= 1'b0;
            grant     <= {N{1'b0}};
            grant_idx <= {IDX_W{1'b0}};
            rr_ptr    <= {IDX_W{1'b0}};
        end else if (grant_en) begin
            busy      <= |g_next;
            grant     <= g_next;
            grant_idx <= idx_next;
            rr_ptr    <= (|g_next) ? rr_next : rr_ptr;
        end
    end

endmodule
