// -----------------------------------------------------------------------------
// File   : axis_packet_fifo.v
// Brief  : AXI4-Stream packet FIFO (同步时钟, store-and-forward)
//          - 写侧 : 标准 AXIS 从机接口
//          - 读侧 : 标准 AXIS 主机接口, 首字预取 (FWFT), 支持满带宽连续弹出
//          - pkt_avail : FIFO 内已存有 >=1 个"完整数据包"(收到过 tlast)
//          - 内部存储 {tlast, tuser, tdata} 打包成一字宽, 推断为 BRAM
// Reset  : rstn 低有效; 存储器本身不复位
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module axis_packet_fifo #(
    parameter integer DEPTH  = 2048,   // FIFO 字数 (拍数)
    parameter integer DATA_W = 8,      // TDATA 位宽
    parameter integer USER_W = 16      // TUSER 位宽
) (
    input  wire                clk,
    input  wire                rstn,

    // ---- 写侧 (AXIS slave) ----
    input  wire                s_tvalid,
    output wire                s_tready,
    input  wire [DATA_W-1:0]   s_tdata,
    input  wire [USER_W-1:0]   s_tuser,
    input  wire                s_tlast,

    // ---- 读侧 (AXIS master) ----
    output wire                m_tvalid,
    input  wire                m_tready,
    output wire [DATA_W-1:0]   m_tdata,
    output wire [USER_W-1:0]   m_tuser,
    output wire                m_tlast,

    // ---- 整包就绪指示 ----
    output wire                pkt_avail
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

    // -------------------------------------------------------------------------
    // 局部参数
    // -------------------------------------------------------------------------
    localparam integer LAST_BIT = DATA_W + USER_W;      // 打包字中的 tlast 位
    localparam integer W        = DATA_W + USER_W + 1;  // 打包字宽
    localparam integer PTR_W    = clog2(DEPTH);
    localparam integer CNT_W    = PTR_W + 1;            // 计数留 1bit 余量防溢出
    localparam integer PKT_W    = PTR_W + 1;            // 缓存包数计数宽度

    // -------------------------------------------------------------------------
    // 信号声明
    // -------------------------------------------------------------------------
    reg [W-1:0]       mem [0:DEPTH-1];   // 存储体 (推断 BRAM)

    reg [PTR_W-1:0]   wr_ptr;
    reg [PTR_W-1:0]   rd_ptr;
    reg [CNT_W-1:0]   cnt;               // 存放在 mem 中的字数

    reg [W-1:0]       mem_dout;          // BRAM 输出寄存器
    reg               rd_hit;            // mem_dout 本拍有效

    reg [W-1:0]       h_data;            // 读侧流水: 级首(直接输出)
    reg               h_valid;
    reg [W-1:0]       t_data;            // 读侧流水: 次级(等待上位弹出)
    reg               t_valid;

    reg [W-1:0]       n_h_data;
    reg               n_h_valid;
    reg [W-1:0]       n_t_data;
    reg               n_t_valid;

    reg [PKT_W-1:0]   pkt_cnt;

    // -------------------------------------------------------------------------
    // 写侧握手与控制
    //   cnt 只统计 mem 中的字数, 已流入读侧流水的字不再占用 mem 空间,
    //   因此 cnt 达到 DEPTH 时才反压, 不会浪费深度。
    // -------------------------------------------------------------------------
    wire              full    = (cnt >= DEPTH);
    wire              wr_en   = s_tvalid & s_tready;
    wire [W-1:0]      wr_word = {s_tlast, s_tuser, s_tdata};

    assign s_tready = ~full;

    // -------------------------------------------------------------------------
    // 读侧握手与控制
    //   pop       : 消费者取走队首
    //   rd_req    : 向 BRAM 发读命令
    //   BRAM 读 (含输出寄存器) 有 1 拍延迟, 要维持 1 字/拍 的连续弹出,
    //   必须允许"正在落地 1 条 + 在飞 1 条"共存, 因此按如下余量发读命令:
    //     occ_now   = 队首 + 次级 + 本拍待落地的字数
    //     occ_after = 本拍弹出后的剩余字数
    //   仅当 occ_after <= 1 时发读命令 -> 保证数据落地时一定有寄存器可接
    //   (不允许两个占用都被占满时还发命令, 也允许刚发完就再发一条)
    // -------------------------------------------------------------------------
    wire              pop       = h_valid & m_tready;
    wire [1:0]        occ_now   = h_valid + t_valid + rd_hit;
    wire [1:0]        occ_after = occ_now - pop;
    wire              rd_room   = (occ_after <= 2'd1);
    wire              rd_req    = (cnt != 0) & rd_room;

    assign m_tvalid = h_valid;
    assign m_tdata  = h_data[DATA_W-1:0];
    assign m_tuser  = h_data[LAST_BIT-1:DATA_W];
    assign m_tlast  = h_data[LAST_BIT];

    assign pkt_avail = (pkt_cnt != 0);

    // -------------------------------------------------------------------------
    // 存储体 : 同步写 + 寄存输出的同步读
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (wr_en) begin
            mem[wr_ptr] <= wr_word;
        end
        if (rd_req) begin
            mem_dout <= mem[rd_ptr];
        end
    end

    // -------------------------------------------------------------------------
    // 读侧流水次态 : 先处理消费(pop), 再插入 BRAM 回读数据
    // -------------------------------------------------------------------------
    always @* begin
        n_h_valid = h_valid;
        n_h_data  = h_data;
        n_t_valid = t_valid;
        n_t_data  = t_data;

        // 队首被取走: 次级顺补到队首
        if (pop) begin
            n_h_valid = t_valid;
            n_h_data  = t_data;
            n_t_valid = 1'b0;
        end

        // BRAM 回读数据落位
        if (rd_hit) begin
            if (~n_h_valid) begin
                n_h_valid = 1'b1;
                n_h_data  = mem_dout;
            end else if (~n_t_valid) begin
                n_t_valid = 1'b1;
                n_t_data  = mem_dout;
            end
        end
    end

    // -------------------------------------------------------------------------
    // 时序状态
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            wr_ptr   <= {PTR_W{1'b0}};
            rd_ptr   <= {PTR_W{1'b0}};
            cnt      <= {CNT_W{1'b0}};
            rd_hit   <= 1'b0;
            h_valid  <= 1'b0;
            t_valid  <= 1'b0;
            h_data   <= {W{1'b0}};
            t_data   <= {W{1'b0}};
            pkt_cnt  <= {PKT_W{1'b0}};
        end else begin
            if (wr_en)  wr_ptr <= wr_ptr + 1'b1;
            if (rd_req) rd_ptr <= rd_ptr + 1'b1;

            if (wr_en & ~rd_req) begin
                cnt <= cnt + 1'b1;
            end else if (rd_req & ~wr_en) begin
                cnt <= cnt - 1'b1;
            end

            rd_hit   <= rd_req;
            h_valid  <= n_h_valid;
            h_data   <= n_h_data;
            t_valid  <= n_t_valid;
            t_data   <= n_t_data;

            // 完整包计数: 写入 tlast 拍 +1, 弹出 tlast 拍 -1
            case ({wr_en & s_tlast, pop & m_tlast})
                2'b10:   pkt_cnt <= pkt_cnt + 1'b1;
                2'b01:   pkt_cnt <= pkt_cnt - 1'b1;
                default: pkt_cnt <= pkt_cnt;
            endcase
        end
    end

endmodule
