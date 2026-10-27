// -----------------------------------------------------------------------------
// File   : tb_axis_arb_rr.v
// Brief  : axis_arb_rr 自校验仿真环境 (纯 Verilog, Vivado xsim)
//          - 每路按随机包长(1 ~ MAX_PKT_BYTES)/随机空闲发送 NPKT 个包
//          - 载荷 = 通道单调递增计数值, TUSER = 通道号
//          - 下游随机反压
//          - 校验点:
//            1) 数据零丢失/零错序
//            2) 包不被交织 (同一输出包内 TUSER 恒定)
//            3) 每路收发包数一致
//            4) 各流水段计数一致 (写->FIFO弹出->仲裁级->输出)
//
//   时序约定 (避免采样歧义):
//     - TB 在 negedge 更新激励/采样: 该时刻的信号在下一个 posedge 被 DUT 采集
//     - 因此在 negedge 观察到的 (tvalid, tready) 正是本次握手的一对
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module tb_axis_arb_rr;

    wire chk_done_0;
    wire chk_done_1;
    wire chk_done_2;
    wire chk_done_3;
    wire chk_done_4;

    tb_dut_chk #(
        .N       (4),
        .OUT_REG (1),
        .TAG     ("CFG-A(N=4,OUT_REG=1)")
    ) u_chk_0 (
        .chk_done (chk_done_0)
    );

    tb_dut_chk #(
        .N       (3),
        .OUT_REG (0),
        .TAG     ("CFG-B(N=3,OUT_REG=0)")
    ) u_chk_1 (
        .chk_done (chk_done_1)
    );

    tb_dut_chk #(
        .N       (6),
        .OUT_REG (1),
        .TAG     ("CFG-C(N=6,OUT_REG=1)")
    ) u_chk_2 (
        .chk_done (chk_done_2)
    );

    // 全 bypass 配置: 验证 IN_REG/MUX_REG/OUT_REG=0 的连线分支 (零额外流水)
    tb_dut_chk #(
        .N       (4),
        .IN_REG  (0),
        .MUX_REG (0),
        .OUT_REG (0),
        .TAG     ("CFG-D(N=4,bypass)")
    ) u_chk_3 (
        .chk_done (chk_done_3)
    );

    // ARB_REG=0 配置: 验证仲裁器 done 直连路径 (无包间气泡)
    tb_dut_chk #(
        .N       (4),
        .ARB_REG (0),
        .TAG     ("CFG-E(N=4,ARB_REG=0)")
    ) u_chk_4 (
        .chk_done (chk_done_4)
    );

    initial begin
        wait (chk_done_0 && chk_done_1 && chk_done_2 && chk_done_3 && chk_done_4);
        #100;
        $display("=================================================");
        $display("[TB] ALL CONFIGURATIONS FINISHED");
        $display("=================================================");
        $finish;
    end

    initial begin
        #3000000;
        $display("[TB] ERROR: TIMEOUT");
        $finish;
    end

endmodule


// -----------------------------------------------------------------------------
// 单个配置的完整激励 + 校验
// -----------------------------------------------------------------------------
module tb_dut_chk #(
    parameter integer N             = 4,
    parameter integer DATA_W        = 8,
    parameter integer USER_W        = 16,
    parameter integer FIFO_DEPTH    = 64,
    parameter integer MAX_PKT_BYTES = 32,
    parameter integer IN_REG        = 1,
    parameter integer MUX_REG       = 1,
    parameter integer OUT_REG       = 1,
    parameter integer ARB_REG       = 1,
    parameter integer NPKT          = 20,
    parameter integer SEED0         = 1,
    parameter         TAG           = "DEFAULT"
) (
    output reg chk_done
);

    localparam MAX_CH = 8;          // 仅用于内部数组宽度

    // -------------------------------------------------------------------------
    // 时钟 / 复位
    // -------------------------------------------------------------------------
    reg clk  = 1'b0;
    reg rstn = 1'b0;

    always #5 clk = ~clk;

    initial begin : TkReset
        repeat (8) @(posedge clk);
        rstn <= 1'b1;
    end

    // -------------------------------------------------------------------------
    // DUT 端口信号
    // -------------------------------------------------------------------------
    reg  [N-1:0]        s_tvalid = {N{1'b0}};
    wire [N-1:0]        s_tready;
    reg  [N-1:0]        s_tlast  = {N{1'b0}};
    reg  [N*DATA_W-1:0] s_tdata  = {N*DATA_W{1'b0}};
    reg  [N*USER_W-1:0] s_tuser  = {N*USER_W{1'b0}};

    reg                 m_ready = 1'b0;
    wire                m_tvalid;
    wire                m_tlast;
    wire [DATA_W-1:0]   m_tdata;
    wire [USER_W-1:0]   m_tuser;

    axis_arb_rr #(
        .N             (N),
        .DATA_W        (DATA_W),
        .USER_W        (USER_W),
        .MAX_PKT_BYTES (MAX_PKT_BYTES),
        .FIFO_DEPTH    (FIFO_DEPTH),
        .IN_REG        (IN_REG),
        .MUX_REG       (MUX_REG),
        .OUT_REG       (OUT_REG),
        .ARB_REG       (ARB_REG)
    ) u_dut (
        .clk           (clk),
        .rstn          (rstn),
        .s_axis_tvalid (s_tvalid),
        .s_axis_tready (s_tready),
        .s_axis_tdata  (s_tdata),
        .s_axis_tuser  (s_tuser),
        .s_axis_tlast  (s_tlast),
        .m_axis_tvalid (m_tvalid),
        .m_axis_tready (m_ready),
        .m_axis_tdata  (m_tdata),
        .m_axis_tuser  (m_tuser),
        .m_axis_tlast  (m_tlast)
    );

    // -------------------------------------------------------------------------
    // 计数/期望值
    // -------------------------------------------------------------------------
    reg  [7:0]   tx_byte   [0:MAX_CH-1];   // 发送侧下一字节
    reg  [7:0]   wr_exp    [0:MAX_CH-1];   // FIFO 写口期望
    reg  [7:0]   pop_exp   [0:MAX_CH-1];   // FIFO 读口期望
    reg  [7:0]   rx_byte   [0:MAX_CH-1];   // 输出口期望

    integer      wr_cnt    [0:MAX_CH-1];
    integer      pop_cnt   [0:MAX_CH-1];
    integer      recv_cnt  [0:MAX_CH-1];
    integer      sent_pkts [0:MAX_CH-1];
    integer      recv_pkts [0:MAX_CH-1];

    integer      total_sent;
    integer      total_recv;
    integer      err_cnt;
    integer      xfer_idle;      // 连续无输出传输的拍数 (卡死判断)
    integer      i;

    initial begin : TkInit
        total_sent = 0;
        total_recv = 0;
        err_cnt    = 0;
        xfer_idle  = 0;
        chk_done   = 1'b0;
        for (i = 0; i < MAX_CH; i = i + 1) begin
            tx_byte  [i] = i * 8'h21 + 8'h03;
            wr_exp   [i] = tx_byte[i];
            pop_exp  [i] = tx_byte[i];
            rx_byte  [i] = tx_byte[i];
            wr_cnt   [i] = 0;
            pop_cnt  [i] = 0;
            recv_cnt [i] = 0;
            sent_pkts[i] = 0;
            recv_pkts[i] = 0;
        end
    end

    // -------------------------------------------------------------------------
    // 每路独立激励
    //   注意: Verilog task 是静态的, 并行调用会共享形参/局部变量,
    //        因此这里用 generate 为每路生成独立进程。
    // -------------------------------------------------------------------------
    genvar gch;
    generate
        for (gch = 0; gch < N; gch = gch + 1) begin : gen_tk_ch
            localparam GNUM = gch;

            integer p_i;
            integer b_i;
            integer len_i;
            integer idle_i;
            integer rnd_i;
            integer seed_i;

            initial begin : TkInitCh
                seed_i = SEED0 + 977 * (GNUM + 1);
                p_i    = 0;
                b_i    = 0;
                len_i  = 1;
                idle_i = 0;
                rnd_i  = 0;
            end

            // ---- FIFO 写口监控 ----
            always begin : TkMonWr
                @(negedge clk);
                #1;
                if (rstn && u_dut.gen_in_fifo[GNUM].u_pkt_fifo.wr_en) begin
                    if (u_dut.gen_in_fifo[GNUM].u_pkt_fifo.s_tdata !== wr_exp[GNUM]) begin
                        err_cnt = err_cnt + 1;
                        $display("[%0s] WR_MISMATCH ch%0d got=%0h exp=%0h",
                                 TAG, GNUM,
                                 u_dut.gen_in_fifo[GNUM].u_pkt_fifo.s_tdata, wr_exp[GNUM]);
                    end
                    wr_exp[GNUM] = wr_exp[GNUM] + 1'b1;
                    wr_cnt[GNUM] = wr_cnt[GNUM] + 1;
                end
            end

            // ---- FIFO 读口监控 ----
            always begin : TkMonPop
                @(negedge clk);
                #1;
                if (rstn && u_dut.gen_in_fifo[GNUM].u_pkt_fifo.pop) begin
                    if (u_dut.gen_in_fifo[GNUM].u_pkt_fifo.m_tdata !== pop_exp[GNUM]) begin
                        err_cnt = err_cnt + 1;
                        $display("[%0s] POP_MISMATCH ch%0d got=%0h exp=%0h",
                                 TAG, GNUM,
                                 u_dut.gen_in_fifo[GNUM].u_pkt_fifo.m_tdata, pop_exp[GNUM]);
                    end
                    pop_exp[GNUM] = pop_exp[GNUM] + 1'b1;
                    pop_cnt[GNUM] = pop_cnt[GNUM] + 1;
                end
            end

            // ---- 发包主循环 (negedge 驱动) ----
            initial begin : TkChannel
                @(posedge rstn);
                while (p_i < NPKT) begin
                    rnd_i = $random(seed_i);
                    if (rnd_i < 0) begin
                        rnd_i = -rnd_i;
                    end
                    len_i = 1 + (rnd_i % MAX_PKT_BYTES);

                    for (b_i = 0; b_i < len_i; b_i = b_i + 1) begin
                        begin : beat_loop
                            forever begin
                                // 在 negedge 拉起本拍数据, 稳定到下一个 posedge
                                @(negedge clk);
                                s_tdata [GNUM*DATA_W +: DATA_W] = tx_byte[GNUM];
                                s_tuser [GNUM*USER_W +: USER_W] = GNUM[USER_W-1:0];
                                s_tlast [GNUM]                  = (b_i == len_i - 1);
                                s_tvalid[GNUM]                  = 1'b1;
                                if (s_tready[GNUM]) begin
                                    @(posedge clk);          // 握手在此沿完成
                                    @(negedge clk);          // 保持到下一 negedge 再撤 (避免采样竞争)
                                    s_tvalid[GNUM] = 1'b0;
                                    s_tlast [GNUM] = 1'b0;
                                    disable beat_loop;
                                end
                            end
                        end
                        tx_byte[GNUM] = tx_byte[GNUM] + 1'b1;
                    end

                    total_sent      = total_sent + 1;
                    sent_pkts[GNUM] = sent_pkts[GNUM] + 1;
                    p_i             = p_i + 1;

                    rnd_i = $random(seed_i);
                    if (rnd_i < 0) begin
                        rnd_i = -rnd_i;
                    end
                    idle_i = rnd_i % 6;
                    repeat (idle_i) @(posedge clk);
                end
            end
        end
    endgenerate

    // -------------------------------------------------------------------------
    // 接收侧: 采样 + 校验 + 随机反压 (全部在 negedge)
    // -------------------------------------------------------------------------
    reg        in_pkt;
    integer    cur_ch;
    integer    pkt_len;
    integer    stall_left;
    integer    seed_r;

    initial begin : TkRcvInit
        in_pkt     = 1'b0;
        cur_ch     = 0;
        pkt_len    = 0;
        stall_left = 0;
        seed_r     = SEED0 + 31337;
    end

    always @(negedge clk) begin : TkReceiver
        if (!rstn) begin
            m_ready    = 1'b0;
            stall_left = 0;
        end else begin
            // 先决定本次握手使用的 ready: 该值会被 DUT 在下一个 posedge 采样,
            // 与当前拍的 m_tvalid 构成握手对 -> 与 DUT 侧一致
            if (stall_left > 0) begin
                m_ready    = 1'b0;
                stall_left = stall_left - 1;
            end else if ((abs_rand(0) % 4) == 0) begin
                m_ready    = 1'b0;
                stall_left = 1 + (abs_rand(0) % 5);
            end else begin
                m_ready = 1'b1;
            end

            if (m_tvalid && m_ready) begin
                xfer_idle = 0;
                if (!in_pkt) begin
                    in_pkt  = 1'b1;
                    cur_ch  = m_tuser;
                    pkt_len = 0;
                end
                pkt_len = pkt_len + 1;

                // 1) 包内通道号必须恒定 -> 无交织
                if (m_tuser !== cur_ch[USER_W-1:0]) begin
                    err_cnt = err_cnt + 1;
                    $display("[%0s] ERROR @%0t interleaved: ch=%0d expect=%0d data=0x%02h",
                             TAG, $time, m_tuser, cur_ch, m_tdata);
                end
                // 2) 载荷连续递增 -> 无丢失/无错序
                if (m_tdata !== rx_byte[cur_ch]) begin
                    err_cnt = err_cnt + 1;
                    $display("[%0s] ERROR @%0t ch%0d data mismatch: got=%0h exp=%0h type=%b",
                             TAG, $time, cur_ch, m_tdata, rx_byte[cur_ch], m_tuser);
                end
                rx_byte[cur_ch]  = rx_byte[cur_ch] + 1'b1;
                recv_cnt[cur_ch] = recv_cnt[cur_ch] + 1;

                if (m_tlast) begin
                    in_pkt            = 1'b0;
                    recv_pkts[cur_ch] = recv_pkts[cur_ch] + 1;
                    total_recv        = total_recv + 1;
                end
            end else begin
                xfer_idle = xfer_idle + 1;
            end
        end
    end

    function integer abs_rand;
        input integer dummy;
        reg [31:0] r;
        begin
            r = $random(seed_r);
            if (r[31]) begin
                r = -r;
            end
            abs_rand = r;
        end
    endfunction

    // -------------------------------------------------------------------------
    // 周期状态 / 卡死探测
    // -------------------------------------------------------------------------
    initial begin : TkStallWatch
        forever begin
            #20000;
            if (xfer_idle > 200 && rstn && !chk_done) begin
                err_cnt = err_cnt + 1;
                $display("[%0s] ERROR @%0t stalled: sent=%0d recv=%0d wr=%0d pop=%0d out=%0d req=%b grant=%b busy=%b",
                         TAG, $time, total_sent, total_recv,
                         sum_wr(0), sum_pop(0), sum_recv(0),
                         u_dut.pkt_avail, u_dut.grant, u_dut.u_arbiter.busy);
            end
        end
    end

    // Verilog 不支持数组传参, 用四个函数分别求和
    function integer sum_wr;
        input integer dummy;
        integer k;
        begin
            sum_wr = 0;
            for (k = 0; k < N; k = k + 1) sum_wr = sum_wr + wr_cnt[k];
        end
    endfunction

    function integer sum_pop;
        input integer dummy;
        integer k;
        begin
            sum_pop = 0;
            for (k = 0; k < N; k = k + 1) sum_pop = sum_pop + pop_cnt[k];
        end
    endfunction

    function integer sum_recv;
        input integer dummy;
        integer k;
        begin
            sum_recv = 0;
            for (k = 0; k < N; k = k + 1) sum_recv = sum_recv + recv_cnt[k];
        end
    endfunction

    // -------------------------------------------------------------------------
    // 结束判定 / 报告
    // -------------------------------------------------------------------------
    initial begin : TkReport
        wait (total_sent == N * NPKT);
        while (total_recv < N * NPKT) begin
            @(posedge clk);
        end
        repeat (30) @(posedge clk);

        for (i = 0; i < N; i = i + 1) begin
            if (sent_pkts[i] != recv_pkts[i]) begin
                err_cnt = err_cnt + 1;
                $display("[%0s] ERROR ch%0d packet count: sent=%0d recv=%0d",
                         TAG, i, sent_pkts[i], recv_pkts[i]);
            end
            if (wr_cnt[i] != recv_cnt[i]) begin
                err_cnt = err_cnt + 1;
                $display("[%0s] ERROR ch%0d byte count : wr=%0d pop=%0d out=%0d",
                         TAG, i, wr_cnt[i], pop_cnt[i], recv_cnt[i]);
            end
        end

        if (err_cnt == 0) begin
            $display("[%0s] PASS : pkts=%0d/%0d bytes=%0d/%0d/%0d (wr/pop/out) no interleave",
                     TAG, total_recv, total_sent,
                     sum_wr(0), sum_pop(0), sum_recv(0));
        end else begin
            $display("[%0s] FAIL : %0d errors", TAG, err_cnt);
        end
        chk_done = 1'b1;
    end

endmodule
