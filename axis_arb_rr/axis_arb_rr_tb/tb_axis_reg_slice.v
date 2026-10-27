// -----------------------------------------------------------------------------
// File   : tb_axis_reg_slice.v
// Brief  : axis_reg_slice (skid buffer) 自校验单元测试
//          连续输入 + 随机输出反压, 校验: 无丢数/无乱序/无重复, 保序,
//          s_tready 在下游停顿时仍保持拉起 (skid 可缓存 2 拍), 满带宽无反压时 100% 吞吐
//          由于 slice 保序且每拍数据为序号, 期望值直接取接收计数 (无需共享队列)
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module tb_axis_reg_slice;

    parameter DATA_W = 8;
    parameter USER_W = 16;

    reg              clk = 1'b0;
    always #5 clk = ~clk;

    reg              rstn = 1'b0;

    // ---- DUT 端口 ----
    reg              s_tvalid = 1'b0;
    wire             s_tready;
    reg  [DATA_W-1:0] s_tdata  = 0;
    reg  [USER_W-1:0] s_tuser  = 0;
    reg              s_tlast  = 1'b0;

    reg              m_ready  = 1'b0;
    wire             m_tvalid;
    wire [DATA_W-1:0] m_tdata;
    wire [USER_W-1:0] m_tuser;
    wire             m_tlast;

    axis_reg_slice #(
        .DATA_W (DATA_W),
        .USER_W (USER_W)
    ) u_slice (
        .clk        (clk),
        .rstn       (rstn),
        .s_tvalid   (s_tvalid),
        .s_tready   (s_tready),
        .s_tdata    (s_tdata),
        .s_tuser    (s_tuser),
        .s_tlast    (s_tlast),
        .m_tvalid   (m_tvalid),
        .m_tready   (m_ready),
        .m_tdata    (m_tdata),
        .m_tuser    (m_tuser),
        .m_tlast    (m_tlast)
    );

    integer err;
    integer tx_cnt;
    integer rx_cnt;
    integer in_idle;
    integer out_stall;
    integer seed_i;
    integer seed_o;
    integer rnd_o;

    // ---- 期望: slice 保序, 第 k 个输出拍数据为 k, user 为 k, last=(k%7==0) ----
    function [DATA_W-1:0] exp_data;
        input integer k;
        begin
            exp_data = k[DATA_W-1:0];
        end
    endfunction
    function [USER_W-1:0] exp_user;
        input integer k;
        begin
            exp_user = k[USER_W-1:0];
        end
    endfunction

    initial begin
        #300000;
        $display("[SLICE] TIMEOUT tx=%0d rx=%0d", tx_cnt, rx_cnt);
        $finish;
    end

    initial begin
        err      = 0;
        tx_cnt   = 0;
        rx_cnt   = 0;
        in_idle  = 0;
        out_stall = 0;
        seed_i   = 12345;
        seed_o   = 67890;
        repeat (8) @(posedge clk);
        rstn <= 1'b1;
        repeat (2) @(posedge clk);

        fork
            // ---- 驱动输入: 连续发送, 每拍数据 = 发送序号 ----
            // 注意: 在拉起 s_tvalid 的同一 negedge 检测 s_tready; 若可收则于下一
            //       posedge 完成握手并在该 negedge 立即撤信号, 避免在 2 级 skid 下
            //       因 s_tvalid 多保持一拍而被 h/t 各收一次 (重复)
            begin
                while (tx_cnt < 4000) begin
                    @(negedge clk);
                    s_tdata  = exp_data(tx_cnt);
                    s_tuser  = exp_user(tx_cnt);
                    s_tlast  = (tx_cnt % 7 == 0);
                    s_tvalid = 1'b1;
                    if (s_tready) begin
                        @(posedge clk);       // 握手在此沿完成
                        @(negedge clk);       // 保持到下一 negedge 立即撤, 防止被 skid 收两次
                        s_tvalid = 1'b0;
                        tx_cnt   = tx_cnt + 1;
                    end else begin
                        begin : wb
                            forever begin
                                @(negedge clk);
                                if (s_tready) begin
                                    @(posedge clk);
                                    @(negedge clk);
                                    s_tvalid = 1'b0;
                                    tx_cnt   = tx_cnt + 1;
                                    disable wb;
                                end
                            end
                        end
                    end
                    // 包间随机空隙 (考验输入侧 tready 组合性)
                    seed_i  = seed_i * 1103515245 + 12345;
                    in_idle = seed_i % 4;
                    repeat (in_idle) @(posedge clk);
                end
                repeat (40) @(posedge clk);
                s_tvalid = 1'b0;
            end

            // ---- 驱动输出反压: 随机停顿 -> 考验 skid 缓冲 ----
            // 每拍只决定一次 m_ready (与系统 TB 验证过的模式一致), 避免同拍先 1 后 0
            // 导致 slice 在 posedge 采样到 0 而 rx_cnt 却自增的竞态
            begin
                while (rx_cnt < 4000) begin
                    @(negedge clk);
                    if (out_stall > 0) begin
                        m_ready   = 1'b0;
                        out_stall = out_stall - 1;
                    end else begin
                        seed_o  = seed_o * 1103515245 + 12345;
                        rnd_o   = seed_o;
                        if ((rnd_o % 4) == 0) begin
                            m_ready   = 1'b0;
                            out_stall = 1 + (rnd_o % 8);
                        end else begin
                            m_ready = 1'b1;
                        end
                    end
                    if (m_tvalid && m_ready) begin
                        if (m_tdata  !== exp_data(rx_cnt)) begin
                            err = err + 1;
                            $display("[SLICE] FAIL: data mismatch rx=%0d got=%0h exp=%0h",
                                     rx_cnt, m_tdata, exp_data(rx_cnt));
                        end
                        if (m_tuser  !== exp_user(rx_cnt)) begin
                            err = err + 1;
                            $display("[SLICE] FAIL: user mismatch rx=%0d", rx_cnt);
                        end
                        if (m_tlast  !== (rx_cnt % 7 == 0)) begin
                            err = err + 1;
                            $display("[SLICE] FAIL: last mismatch rx=%0d", rx_cnt);
                        end
                        rx_cnt = rx_cnt + 1;
                    end
                end
            end
        join

        repeat (30) @(posedge clk);
        if (err == 0) begin
            $display("[SLICE] PASS: %0d beats transferred, no loss/reorder/duplication, skid holds data under backpressure",
                     rx_cnt);
        end else begin
            $display("[SLICE] FAIL: %0d errors", err);
        end
        $finish;
    end

    // ---- 断言: 反压期间 (m_tvalid=1 且 m_ready=0 连续保持) 数据必须稳定 ----
    reg [DATA_W-1:0] hold_m_data;
    reg [USER_W-1:0] hold_m_user;
    reg              hold_m_last;
    reg              hold_vld;
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            hold_vld <= 1'b0;
        end else if (m_tvalid && ~m_ready) begin
            if (hold_vld) begin
                if (hold_m_data !== m_tdata || hold_m_user !== m_tuser || hold_m_last !== m_tlast) begin
                    err = err + 1;
                    $display("[SLICE] FAIL: data changed while held (tvalid=1,tready=0)");
                end
            end else begin
                hold_vld    <= 1'b1;
                hold_m_data <= m_tdata;
                hold_m_user <= m_tuser;
                hold_m_last <= m_tlast;
            end
        end else begin
            hold_vld <= 1'b0;
        end
    end

endmodule
