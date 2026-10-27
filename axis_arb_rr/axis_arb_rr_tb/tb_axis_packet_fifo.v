// -----------------------------------------------------------------------------
// File   : tb_axis_packet_fifo.v
// Brief  : axis_packet_fifo 定点单元测试 (确定性, 无随机)
//          case1: 写入 3 拍包 -> 观察 pkt_avail 置起 -> 读出并校验
//          case2: 写入 1 拍极短包
//          case3: 写入过程中反压 (tready 被下游拉低)
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module tb_axis_packet_fifo;

    reg                 clk = 1'b0;
    reg                 rstn = 1'b0;
    always #5 clk = ~clk;

    reg                 s_tvalid = 1'b0;
    wire                s_tready;
    reg  [7:0]          s_tdata = 8'h00;
    reg  [15:0]         s_tuser = 16'h0000;
    reg                 s_tlast = 1'b0;

    reg                 m_ready = 1'b0;
    wire                m_tvalid;
    wire                m_tlast;
    wire [7:0]          m_tdata;
    wire [15:0]         m_tuser;
    wire                pkt_avail;

    axis_packet_fifo #(
        .DEPTH  (16),
        .DATA_W (8),
        .USER_W (16)
    ) u_fifo (
        .clk       (clk),
        .rstn      (rstn),
        .s_tvalid  (s_tvalid),
        .s_tready  (s_tready),
        .s_tdata   (s_tdata),
        .s_tuser   (s_tuser),
        .s_tlast   (s_tlast),
        .m_tvalid  (m_tvalid),
        .m_tready  (m_ready),
        .m_tdata   (m_tdata),
        .m_tuser   (m_tuser),
        .m_tlast   (m_tlast),
        .pkt_avail (pkt_avail)
    );

    integer err;
    integer got;
    integer idx;
    integer cyc_cnt;
    integer n_cnt;

    initial begin
        #200000;
        $display("[FIFO] TIMEOUT: something hangs");
        $finish;
    end

    initial begin
        err = 0;
        repeat (4) @(posedge clk);
        rstn <= 1'b1;
        repeat (2) @(posedge clk);

        $display("[FIFO] start case1");
        // ---------------- case1 : 3 拍包 ----------------
        write_beat(8'h11, 16'hA1, 1'b0);
        write_beat(8'h12, 16'hA2, 1'b0);
        write_beat(8'h13, 16'hA3, 1'b1);
        repeat (3) @(posedge clk);
        if (pkt_avail !== 1'b1) begin
            err = err + 1;
            $display("[FIFO] FAIL: pkt_avail should be 1 after complete packet");
        end
        read_beat(8'h11, 16'hA1, 1'b0);
        read_beat(8'h12, 16'hA2, 1'b0);
        read_beat(8'h13, 16'hA3, 1'b1);
        repeat (3) @(posedge clk);
        if (pkt_avail !== 1'b0) begin
            err = err + 1;
            $display("[FIFO] FAIL: pkt_avail should be 0 after packet popped");
        end

        $display("[FIFO] case1 done, start case2");
        // ---------------- case2 : 1 拍包 ----------------
        write_beat(8'h77, 16'hB7, 1'b1);
        repeat (3) @(posedge clk);
        if (pkt_avail !== 1'b1) begin
            err = err + 1;
            $display("[FIFO] FAIL case2: pkt_avail should be 1");
        end
        read_beat(8'h77, 16'hB7, 1'b1);
        repeat (3) @(posedge clk);
        if (pkt_avail !== 1'b0) begin
            err = err + 1;
            $display("[FIFO] FAIL case2: pkt_avail should be 0");
        end

        $display("[FIFO] case2 done, start case3");
        // ---------------- case3 : 写侧被打断 / 读侧反压 ----------------
        write_beat(8'h21, 16'hC1, 1'b0);
        repeat (4) @(posedge clk);          // 中途停住
        write_beat(8'h22, 16'hC2, 1'b0);
        write_beat(8'h23, 16'hC3, 1'b1);
        repeat (3) @(posedge clk);
        if (pkt_avail !== 1'b1) begin
            err = err + 1;
            $display("[FIFO] FAIL case3: pkt_avail should be 1");
        end
        // 读侧反压: ready=0 期间队首数据必须稳定保持
        @(negedge clk);
        m_ready = 1'b0;
        repeat (3) @(posedge clk);
        if (m_tvalid !== 1'b1 || m_tdata !== 8'h21) begin
            err = err + 1;
            $display("[FIFO] FAIL case3: head should hold during backpressure (vld=%b d=%0h)",
                     m_tvalid, m_tdata);
        end
        read_beat(8'h21, 16'hC1, 1'b0);
        read_beat(8'h22, 16'hC2, 1'b0);
        read_beat(8'h23, 16'hC3, 1'b1);
        repeat (3) @(posedge clk);

        $display("[FIFO] case3 done, start case4");
        // ---------------- case4 : 满带宽连续读 ----------------
        for (idx = 0; idx < 8; idx = idx + 1) begin
            write_beat(8'h50 + idx, 16'h00D0 + idx, (idx == 7));
        end
        repeat (6) @(posedge clk);            // 等待预取填满
        @(negedge clk);
        m_ready = 1'b1;
        cyc_cnt = 0;
        n_cnt   = 0;
        while (n_cnt < 8) begin
            @(posedge clk);
            if (m_tvalid) begin
                n_cnt = n_cnt + 1;
            end
            cyc_cnt = cyc_cnt + 1;
        end
        if (cyc_cnt !== 8) begin
            err = err + 1;
            $display("[FIFO] FAIL case4: throughput %0d cycles for 8 words (expect 8)", cyc_cnt);
        end
        @(negedge clk);
        m_ready = 1'b0;
        repeat (3) @(posedge clk);

        if (err == 0) begin
            $display("[FIFO] PASS: all unit cases ok");
        end else begin
            $display("[FIFO] FAIL: %0d errors", err);
        end

        // 打印内部计数
        $display("[FIFO] cnt=%0d pkt_cnt=%0d h_valid=%b t_valid=%b",
                 u_fifo.cnt, u_fifo.pkt_cnt, u_fifo.h_valid, u_fifo.t_valid);
        $finish;
    end

    // -------------------------------------------------------------------------
    // 写一拍 (negedge 驱动, posedge 完成握手)
    // -------------------------------------------------------------------------
    task write_beat;
        input [7:0]  d;
        input [15:0] u;
        input        l;
        begin
            begin : wb_loop
                forever begin
                    @(negedge clk);
                    s_tdata  = d;
                    s_tuser  = u;
                    s_tlast  = l;
                    s_tvalid = 1'b1;
                    if (s_tready) begin
                        @(posedge clk);      // 握手在此沿完成
                        @(negedge clk);      // 保持有效到下一 negedge 再撤, 避免与设计采样沿竞争
                        s_tvalid = 1'b0;
                        s_tlast  = 1'b0;
                        disable wb_loop;
                    end
                end
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // 读一拍并校验
    // -------------------------------------------------------------------------
    task read_beat;
        input [7:0]  d;
        input [15:0] u;
        input        l;
        begin
            begin : rb_loop
                forever begin
                    @(negedge clk);
                    m_ready = 1'b1;
                    if (m_tvalid) begin
                        #1;
                        if (m_tdata !== d || m_tuser !== u || m_tlast !== l) begin
                            err = err + 1;
                            $display("[FIFO] FAIL: read got d=%0h u=%0h l=%b, expect d=%0h u=%0h l=%b",
                                     m_tdata, m_tuser, m_tlast, d, u, l);
                        end
                        @(posedge clk);      // 弹出在此沿完成
                        @(negedge clk);      // 保持 ready 到下一 negedge 再撤
                        m_ready = 1'b0;
                        disable rb_loop;
                    end
                end
            end
        end
    endtask

endmodule
