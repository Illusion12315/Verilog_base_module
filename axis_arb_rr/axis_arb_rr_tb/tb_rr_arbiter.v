// -----------------------------------------------------------------------------
// File   : tb_rr_arbiter.v
// Brief  : rr_arbiter 定点单元测试 (确定性, 无随机)
//          case1: req 全高 -> 授权按 0->1->2->3->0 旋转
//          case2: 无 done 时授权必须保持 (事务级锁定)
//          case3: req 稀疏 -> 只在新请求的最近的上一个位置上选下一个请求者
//          case4: done 后立刻重新仲裁
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module tb_rr_arbiter;

    parameter N = 4;

    reg              clk = 1'b0;
    reg              rstn = 1'b0;
    always #5 clk = ~clk;

    reg  [N-1:0]     req = {N{1'b0}};
    reg              done = 1'b0;
    wire [N-1:0]     grant;
    wire [1:0]       grant_idx;

    rr_arbiter #(
        .N (N)
    ) u_arb (
        .clk       (clk),
        .rstn      (rstn),
        .req       (req),
        .done      (done),
        .grant     (grant),
        .grant_idx (grant_idx)
    );

    integer err;

    initial begin
        #100000;
        $display("[ARB] TIMEOUT");
        $finish;
    end

    initial begin
        err = 0;
        repeat (4) @(posedge clk);
        rstn <= 1'b1;
        repeat (2) @(posedge clk);

        // ---------------- case1 : 全请求下的旋转顺序 ----------------
        expect_grant(req_all(0), 1'b0, 4'b0001, "case1 ch0");
        expect_grant(req_all(0), 1'b1, 4'b0010, "case1 ch1");
        expect_grant(req_all(0), 1'b1, 4'b0100, "case1 ch2");
        expect_grant(req_all(0), 1'b1, 4'b1000, "case1 ch3");
        expect_grant(req_all(0), 1'b1, 4'b0001, "case1 wrap to ch0");

        // ---------------- case2 : 无 done 时必须保持授权 ------------
        expect_grant(req_all(0), 1'b0, 4'b0001, "case2 hold 1");
        expect_grant(req_all(0), 1'b0, 4'b0001, "case2 hold 2");
        expect_grant(req_all(0), 1'b0, 4'b0001, "case2 hold 3");

        // ---------------- case3 : 稀疏请求 --------------------------
        // 上一时段服务的是 ch0, 指针已推到 ch1 -> 全请求下应选 ch1
        expect_grant(req_all(0), 1'b1, 4'b0010, "case3 rotate to ch1");
        // 释放后请求为 ch0/ch2, 指针为 ch2 -> 选 ch2
        expect_grant(4'b0101,   1'b1, 4'b0100, "case3 release to ch2");
        // 无 done -> 保持授权, 即使请求变化
        expect_grant(4'b0101,   1'b0, 4'b0100, "case3 hold ch2");
        // 释放 -> 指针为 ch3, 请求 ch0/ch2 -> 越过 ch3 选 ch0
        expect_grant(4'b0101,   1'b1, 4'b0001, "case3 ch0 served");
        // 再释放 -> 指针回到 ch1, 请求 ch0/ch2 -> 选 ch2
        expect_grant(4'b0101,   1'b1, 4'b0100, "case3 back to ch2");

        // ---------------- case4 : 释放后重新响应新请求 --------------
        expect_grant(4'b0000,   1'b1, 4'b0000, "case4 release with no req");
        expect_grant(4'b1000,   1'b0, 4'b1000, "case4 single req ch3");
        expect_grant(4'b0000,   1'b1, 4'b0000, "case4 release again");

        if (err == 0) begin
            $display("[ARB] PASS: all unit cases ok");
        end else begin
            $display("[ARB] FAIL: %0d errors", err);
        end
        $finish;
    end

    function [N-1:0] req_all;
        input integer dummy;
        begin
            req_all = {N{1'b1}};
        end
    endfunction

    // -------------------------------------------------------------------------
    // negedge 驱动 (req, done) -> 下一 posedge 更新 -> 比较 grant
    // -------------------------------------------------------------------------
    task expect_grant;
        input [N-1:0] new_req;
        input         new_done;
        input [N-1:0] exp_grant;
        input [8*32:1] msg;
        begin
            @(negedge clk);
            req  = new_req;
            done = new_done;
            @(posedge clk);
            #1;
            if (grant !== exp_grant) begin
                err = err + 1;
                $display("[ARB] FAIL %0s : grant=%b expect=%b idx=%0d",
                         msg, grant, exp_grant, grant_idx);
            end
        end
    endtask

endmodule
