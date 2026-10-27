// -----------------------------------------------------------------------------
// File   : axis_arb_rr.v
// Brief  : N 路 AXI4-Stream 输入 -> 1 路 AXI4-Stream 输出
//          - 每路输入自带 packet FIFO, 整包缓存 (store-and-forward)
//          - 轮询 (round-robin) 优先级仲裁, 仲裁粒度为"包":
//            一个包的第一拍被读出后锁定该通道, 直到该包的 tlast 拍离开 FIFO
//            才释放优先级 -> 包与包之间不会交织
//          - 单时钟域
//
// 流水线结构 (面向时序优化, 各级接口均为寄存型 ready/valid):
//
//   s_axis[i] -> [in skid] -> [packet FIFO] -> N:1 MUX -> [mux skid] -> [out skid] -> m_axis
//                  (IN_REG)      (BRAM + 2级)   (comb)     (MUX_REG)     (OUT_REG)
//
//   - IN_REG  : 每路一级寄存 slice, s_axis_tready 由寄存器驱动
//   - MUX_REG : one-hot 选通后的数据先寄存, 再进输出级
//   - OUT_REG : 输出寄存, m_axis_tvalid/m_axis_tdata 由寄存器驱动
//   - ARB_REG : 把"tlast 已弹出"脉冲 (pop_eof) 打一拍再送仲裁器,
//               切断 h_valid -> done -> rr_ptr 的关键路径 (时序优化)
//   除 ARB_REG 外各级均可单独关闭; 全部打开时首包延迟约 8 拍,
//   之后稳态 1 拍/字。ARB_REG 打开时包与包之间多 1 拍气泡
//   (仅影响包边界吞吐, 对 1KB 量级包可忽略), 换取仲裁域时序余量。
//
// Reset  : rstn 低电平有效 (建议外部做同步释放)
// Note   : TDATA = 8bit (1 字节/拍), 故不使用 TKEEP/TSTRB;
//          协议要求每个数据包必须由 s_axis_tlast 正常结束,
//          否则该包永远不会被标记为"可发送"(pkt_avail 不置起)。
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module axis_arb_rr #(
    parameter integer N             = 4,     // 输入通道数 (>=2)
    parameter integer DATA_W        = 8,     // TDATA 位宽 (bit)
    parameter integer USER_W        = 16,    // TUSER 位宽 (bit)
    parameter integer MAX_PKT_BYTES = 1038,  // 单包最大字节数 (仅用于深度检查/说明)
    parameter integer FIFO_DEPTH    = 2048,  // 每路 packet FIFO 字数, 需为 2 的幂
    parameter integer IN_REG        = 1,     // 1: 每路输入插入 skid buffer (推荐)
    parameter integer MUX_REG       = 1,     // 1: MUX 输出插入 skid buffer (推荐)
    parameter integer OUT_REG       = 1,     // 1: 输出插入 skid buffer (推荐)
    parameter integer ARB_REG       = 1      // 1: tlast 弹出信号打拍后再进仲裁器 (推荐)
) (
    input  wire                clk,
    input  wire                rstn,

    // ------------------------------------------------------------------
    // 从机侧 : N 路 AXI4-Stream 输入 (数组式)
    //   s_axis_tdata[i*DATA_W +: DATA_W]  对应第 i 路
    //   s_axis_tuser[i*USER_W +: USER_W]  对应第 i 路
    // ------------------------------------------------------------------
    input  wire [N-1:0]            s_axis_tvalid,
    output wire [N-1:0]            s_axis_tready,
    input  wire [N*DATA_W-1:0]     s_axis_tdata,
    input  wire [N*USER_W-1:0]     s_axis_tuser,
    input  wire [N-1:0]            s_axis_tlast,

    // ------------------------------------------------------------------
    // 主机侧 : 1 路 AXI4-Stream 输出
    // ------------------------------------------------------------------
    output wire                    m_axis_tvalid,
    input  wire                    m_axis_tready,
    output wire [DATA_W-1:0]       m_axis_tdata,
    output wire [USER_W-1:0]       m_axis_tuser,
    output wire                    m_axis_tlast
);

    // ==================================================================
    // clog2: ceil(log2(x))
    // ==================================================================
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

    // ==================================================================
    // 局部参数
    // ==================================================================
    localparam integer BYTES_PER_BEAT = (DATA_W + 7) / 8;
    localparam integer MAX_PKT_BEATS  = (MAX_PKT_BYTES + BYTES_PER_BEAT - 1) / BYTES_PER_BEAT;
    localparam integer PTR_N_W        = clog2(N);

    // ==================================================================
    // 内部信号
    // ==================================================================
    // 输入寄存级输出 (in skid -> packet FIFO)
    wire [N-1:0]                 in_tvalid;
    wire [N-1:0]                 in_tready;
    wire [N*DATA_W-1:0]          in_tdata;
    wire [N*USER_W-1:0]          in_tuser;
    wire [N-1:0]                 in_tlast;

    // packet FIFO 读侧
    wire [N-1:0]                 pkt_avail;   // 第 i 路 FIFO 中已有 >=1 个完整数据包
    wire [N-1:0]                 f_tvalid;
    wire [N*DATA_W-1:0]          f_tdata;
    wire [N*USER_W-1:0]          f_tuser;
    wire [N-1:0]                 f_tlast;

    // 仲裁
    wire [N-1:0]                 grant;       // one-hot
    wire [PTR_N_W-1:0]           grant_idx;

    // 数据弹出与握手
    wire [N-1:0]                 f_pop;       // FIFO 读侧弹出
    wire                         pop_eof;     // 当前弹出的是被选中包的最后一拍
    wire                         out_ready;   // 仲裁级下游(寄存器级)是否可收

    // MUX 组合输出 -> [mux skid] -> 输出级
    wire                         mmux_tvalid;
    wire [DATA_W-1:0]            mmux_tdata;
    wire [USER_W-1:0]            mmux_tuser;
    wire                         mmux_tlast;
    wire                         mmux_tready;

    wire                         arb_done;   // 送往仲裁器的 done (可选打拍)
    wire                         pop_gate;   // 包边界弹出口控 (1: 允许弹出)

    wire                         arb_tvalid;
    wire [DATA_W-1:0]            arb_tdata;
    wire [USER_W-1:0]            arb_tuser;
    wire                         arb_tlast;
    wire                         arb_tready;

    // ==================================================================
    // 每路输入: skid buffer (寄存型从机接口)
    //   作用: s_axis_tready 由寄存器驱动, 切断上游 valid/ready 组合路径;
    //         同时让 packet FIFO 的写数据全部来自寄存器
    // ==================================================================
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_in_slice
            if (IN_REG != 0) begin : g_on
                axis_reg_slice #(
                    .DATA_W (DATA_W),
                    .USER_W (USER_W)
                ) u_in_slice (
                    .clk        (clk),
                    .rstn       (rstn),
                    .s_tvalid   (s_axis_tvalid[i]),
                    .s_tready   (s_axis_tready[i]),
                    .s_tdata    (s_axis_tdata [i*DATA_W +: DATA_W]),
                    .s_tuser    (s_axis_tuser [i*USER_W +: USER_W]),
                    .s_tlast    (s_axis_tlast [i]),
                    .m_tvalid   (in_tvalid[i]),
                    .m_tready   (in_tready[i]),
                    .m_tdata    (in_tdata  [i*DATA_W +: DATA_W]),
                    .m_tuser    (in_tuser  [i*USER_W +: USER_W]),
                    .m_tlast    (in_tlast  [i])
                );
            end else begin : g_off
                assign in_tvalid[i]      = s_axis_tvalid[i];
                assign in_tdata [i*DATA_W +: DATA_W] = s_axis_tdata [i*DATA_W +: DATA_W];
                assign in_tuser [i*USER_W +: USER_W] = s_axis_tuser [i*USER_W +: USER_W];
                assign in_tlast[i]       = s_axis_tlast[i];
                assign s_axis_tready[i]  = in_tready[i];
            end
        end
    endgenerate

    // ==================================================================
    // 每路输入: packet FIFO (store-and-forward)
    //   整包写入后才置起 pkt_avail, 读侧仅在仲裁授权后弹出
    // ==================================================================
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_in_fifo
            axis_packet_fifo #(
                .DEPTH  (FIFO_DEPTH),
                .DATA_W (DATA_W),
                .USER_W (USER_W)
            ) u_pkt_fifo (
                .clk        (clk),
                .rstn       (rstn),
                // -- 写侧 (输入寄存级输出) --
                .s_tvalid   (in_tvalid[i]),
                .s_tready   (in_tready[i]),
                .s_tdata    (in_tdata [i*DATA_W +: DATA_W]),
                .s_tuser    (in_tuser [i*USER_W +: USER_W]),
                .s_tlast    (in_tlast [i]),
                // -- 读侧 (仲裁授权后弹出) --
                .m_tvalid   (f_tvalid[i]),
                .m_tready   (f_pop[i]),
                .m_tdata    (f_tdata  [i*DATA_W +: DATA_W]),
                .m_tuser    (f_tuser  [i*USER_W +: USER_W]),
                .m_tlast    (f_tlast  [i]),
                // -- 整包就绪指示 --
                .pkt_avail  (pkt_avail[i])
            );
        end
    endgenerate

    // ==================================================================
    // 读侧流控: 被授权通道在"下游寄存器级可收"时弹出一拍
    //   out_ready 为下游寄存级的 s_tready (寄存器驱动), 路径很短
    //   pop_gate  : 包边界弹出口控 (见 ARB_REG 块)
    // ==================================================================
    assign f_pop     = grant & {N{pop_gate & out_ready}};
    // 当前弹出的是本包最后一拍 -> 通知仲裁器释放锁定并推进轮询指针
    //   store-and-forward 保证整包已在 FIFO 内, 故 pop 时 f_tvalid 必然为 1
    assign pop_eof   = |(f_pop & f_tvalid & f_tlast);

    // ==================================================================
    // 仲裁器 done 的寄存级 (ARB_REG) + 包边界弹出口控
    //   pop_eof (由 FIFO h_valid/tlast 组合出) 是包边界关键路径的起点,
    //   打一拍再进仲裁器, 把 h_valid -> done -> rr_ptr 的长组合链切成两段。
    //   代价: 包与包边界多 1 拍气泡 (hold_r), 对 1KB 量级包可忽略。
    //
    //   重要: 仅延迟 done 是不够的 —— done 未到达仲裁器的那一拍, grant
    //   仍锁定在刚服务通道; 若其 FIFO 头部已是下一包首拍 (或下一包仍未
    //   写完整), 直接弹出会破坏"整包不变交织 / store-and-forward"。
    //   因此用 hold_r 在 tlast 弹出后的那一拍全局冻结 f_pop:
    //     cy0: tlast 弹出, pop_eof=1
    //     cy1: done_r=1 (仲裁器下沿采样), grant 仍旧, hold_r=1 -> 禁止弹出
    //     cy2: 新 grant 生效, hold_r=0 -> 恢复弹出
    //   稳态净损失 = 包间 1 拍。
    // ==================================================================
    generate
        if (ARB_REG != 0) begin : gen_arb_reg
            reg done_r;
            reg hold_r;
            always @(posedge clk or negedge rstn) begin
                if (~rstn) begin
                    done_r <= 1'b0;
                    hold_r <= 1'b0;
                end else begin
                    done_r <= pop_eof;
                    hold_r <= pop_eof;   // tlast 弹出后 1 拍冻结所有弹出
                end
            end
            assign arb_done = done_r;
            assign pop_gate = ~hold_r;
        end else begin : gen_arb_bypass
            assign arb_done = pop_eof;
            assign pop_gate = 1'b1;
        end
    endgenerate

    // ==================================================================
    // 轮询仲裁器: 包级锁定
    // ==================================================================
    rr_arbiter #(
        .N (N)
    ) u_arbiter (
        .clk        (clk),
        .rstn       (rstn),
        .req        (pkt_avail),
        .done       (arb_done),
        .grant      (grant),
        .grant_idx  (grant_idx)
    );

    // ==================================================================
    // N:1 MUX (组合): one-hot grant 选择被授权通道的数据
    // ==================================================================
    integer k;
    reg               mmux_tvalid_r;
    reg [DATA_W-1:0]  mmux_tdata_r;
    reg [USER_W-1:0]  mmux_tuser_r;
    reg               mmux_tlast_r;

    always @* begin
        mmux_tvalid_r = 1'b0;
        mmux_tdata_r  = {DATA_W{1'b0}};
        mmux_tuser_r  = {USER_W{1'b0}};
        mmux_tlast_r  = 1'b0;
        for (k = 0; k < N; k = k + 1) begin
            if (grant[k]) begin
                mmux_tvalid_r = f_tvalid[k];
                mmux_tdata_r  = f_tdata [k*DATA_W +: DATA_W];
                mmux_tuser_r  = f_tuser [k*USER_W +: USER_W];
                mmux_tlast_r  = f_tlast [k];
            end
        end
    end

    // 包边界气泡内 (hold_r 置位), 被选 FIFO 头部可能已滑入下一包首拍,
    // 但该拍并未真正弹出 (f_pop 被 pop_gate 关断), 必须同时抑止呈现,
    // 否则下游会误收一拍"未弹出的下一包首拍" -> 该字会重复出现在输出。
    assign mmux_tvalid = mmux_tvalid_r & pop_gate;
    assign mmux_tdata  = mmux_tdata_r;
    assign mmux_tuser  = mmux_tuser_r;
    assign mmux_tlast  = mmux_tlast_r;

    // ==================================================================
    // MUX 输出寄存级: 把 one-hot 选通结果先打一拍, 隔离 grant->数据的路径
    // ==================================================================
    generate
        if (MUX_REG != 0) begin : gen_mux_slice
            axis_reg_slice #(
                .DATA_W (DATA_W),
                .USER_W (USER_W)
            ) u_mux_slice (
                .clk        (clk),
                .rstn       (rstn),
                .s_tvalid   (mmux_tvalid),
                .s_tready   (mmux_tready),
                .s_tdata    (mmux_tdata),
                .s_tuser    (mmux_tuser),
                .s_tlast    (mmux_tlast),
                .m_tvalid   (arb_tvalid),
                .m_tready   (arb_tready),
                .m_tdata    (arb_tdata),
                .m_tuser    (arb_tuser),
                .m_tlast    (arb_tlast)
            );
        end else begin : gen_mux_bypass
            assign arb_tvalid = mmux_tvalid;
            assign arb_tdata  = mmux_tdata;
            assign arb_tuser  = mmux_tuser;
            assign arb_tlast  = mmux_tlast;
            assign mmux_tready = arb_tready;
        end
    endgenerate

    // ==================================================================
    // 输出寄存级
    // ==================================================================
    generate
        if (OUT_REG != 0) begin : gen_out_slice
            axis_reg_slice #(
                .DATA_W (DATA_W),
                .USER_W (USER_W)
            ) u_out_slice (
                .clk        (clk),
                .rstn       (rstn),
                .s_tvalid   (arb_tvalid),
                .s_tready   (arb_tready),
                .s_tdata    (arb_tdata),
                .s_tuser    (arb_tuser),
                .s_tlast    (arb_tlast),
                .m_tvalid   (m_axis_tvalid),
                .m_tready   (m_axis_tready),
                .m_tdata    (m_axis_tdata),
                .m_tuser    (m_axis_tuser),
                .m_tlast    (m_axis_tlast)
            );
        end else begin : gen_out_bypass
            assign m_axis_tvalid = arb_tvalid;
            assign m_axis_tdata  = arb_tdata;
            assign m_axis_tuser  = arb_tuser;
            assign m_axis_tlast  = arb_tlast;
            assign arb_tready    = m_axis_tready;
        end
    endgenerate

    // ==================================================================
    // 仲裁级看到的"下游可收"
    //   取最近一级寄存 slice 的 s_tready (由寄存器驱动, 组合深度最小)
    // ==================================================================
    assign out_ready = (MUX_REG != 0) ? mmux_tready :
                       (OUT_REG != 0) ? arb_tready : m_axis_tready;

    // ==================================================================
    // 参数合法性检查 (仅仿真期提示)
    // ==================================================================
    generate
        if (FIFO_DEPTH < MAX_PKT_BEATS) begin : gen_depth_check
            initial begin
                $display("[axis_arb_rr] ERROR @%m : FIFO_DEPTH(%0d) < MAX_PKT_BEATS(%0d), store-and-forward would deadlock, please increase FIFO_DEPTH.",
                         FIFO_DEPTH, MAX_PKT_BEATS);
            end
        end
    endgenerate

endmodule
