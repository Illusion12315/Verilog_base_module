// -----------------------------------------------------------------------------
// File   : axis_reg_slice.v
// Brief  : AXI4-Stream register slice (skid buffer)
//          - 打断 TVALID/TREADY 组合路径, 改善时序
//          - 深度 2, 写入侧 s_tready 寄存输出, 吞吐 100% 不掉带宽
//          - 内部 [tlast:tuser:tdata] 打包寄存, 与 FIFO 保持一致
// Reset  : rstn 低有效
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module axis_reg_slice #(
    parameter integer DATA_W = 8,
    parameter integer USER_W = 16
) (
    input  wire                clk,
    input  wire                rstn,

    // ---- 写侧 ----
    input  wire                s_tvalid,
    output wire                s_tready,
    input  wire [DATA_W-1:0]   s_tdata,
    input  wire [USER_W-1:0]   s_tuser,
    input  wire                s_tlast,

    // ---- 读侧 ----
    output wire                m_tvalid,
    input  wire                m_tready,
    output wire [DATA_W-1:0]   m_tdata,
    output wire [USER_W-1:0]   m_tuser,
    output wire                m_tlast
);

    localparam integer LAST_BIT = DATA_W + USER_W;
    localparam integer W        = DATA_W + USER_W + 1;

    reg [W-1:0]  h_data;      // 队首
    reg          h_valid;
    reg [W-1:0]  t_data;      // 次级
    reg          t_valid;

    reg [W-1:0]  n_h_data;
    reg          n_h_valid;
    reg [W-1:0]  n_t_data;
    reg          n_t_valid;

    wire         take_in  = s_tvalid & s_tready;
    wire         take_out = m_tvalid & m_tready;
    wire [W-1:0] in_word  = {s_tlast, s_tuser, s_tdata};

    assign s_tready = ~t_valid;
    assign m_tvalid = h_valid;
    assign m_tdata  = h_data[DATA_W-1:0];
    assign m_tuser  = h_data[LAST_BIT-1:DATA_W];
    assign m_tlast  = h_data[LAST_BIT];

    // -------------------------------------------------------------------------
    // 次态 : 先处理出队, 再处理入队; 队首占用时新数据进次级,
    //        下游反压时次级数据必须原样保持
    // -------------------------------------------------------------------------
    always @* begin
        n_h_valid = h_valid;
        n_h_data  = h_data;
        n_t_valid = t_valid;
        n_t_data  = t_data;

        if (take_out) begin
            n_h_valid = t_valid;
            n_h_data  = t_data;
            n_t_valid = 1'b0;
        end

        if (take_in) begin
            if (~n_h_valid) begin
                n_h_valid = 1'b1;
                n_h_data  = in_word;
            end else if (~n_t_valid) begin
                n_t_valid = 1'b1;
                n_t_data  = in_word;
            end
        end
    end

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            h_valid <= 1'b0;
            t_valid <= 1'b0;
            h_data  <= {W{1'b0}};
            t_data  <= {W{1'b0}};
        end else begin
            h_valid <= n_h_valid;
            h_data  <= n_h_data;
            t_valid <= n_t_valid;
            t_data  <= n_t_data;
        end
    end

endmodule
