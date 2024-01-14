//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: chenxiongzhi
// 
// Create Date: 2023/08/24 16:22:08
// Design Name: 
// Module Name: RST
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


//上电自动产生复位
module start_rst_module
#(
    parameter                           RST_TIME_CNT = 'd1_000      
)
(
    input                               i_sys_clk                  ,
    input                               i_rst_in                   ,
	
    output                              o_rst_out                   
);
reg                    [  15:0]         cnt='d0                    ;
reg                                     auto_rst_n                 ;

assign    o_rst_out = auto_rst_n & i_rst_in;

always@(posedge i_sys_clk)begin
    if(cnt<RST_TIME_CNT-'d1)begin
        cnt<=cnt+'d1;
        auto_rst_n<='d0;
    end
    else begin
        cnt<=cnt;
        auto_rst_n<=1'd1;
    end
end

endmodule
/*

//调用上电复位模块
start_rst_module
    start_rst
(
    .i_sys_clk                         (                          ),//输入时钟
    .i_rst_in                          (                          ),//复位
	
    .o_rst_out                         (                          ) //产生复位信号
);

*/

//复位同步
module    reset_sync_module(
    input                               i_sys_clk                  ,//同步时钟
    input                               i_rst_n                    ,//待同步异步复位信号
    output                              o_sync_rst                  //同步复位信号
);

(* ASYNC_REG = "TRUE" *)
reg                                     r_rst1,r_rst2              ;

assign    o_sync_rst = r_rst2;

always@(posedge i_sys_clk or negedge i_rst_n)begin
    if(!i_rst_n)begin
        r_rst1    <=    'd0;
        r_rst2    <=    'd0;
    end else begin
        r_rst1    <=    i_rst_n;
        r_rst2    <=    r_rst1;
    end
end

endmodule
/*

//调用复位同步模块
reset_sync_module rst_sync(
    .i_sys_clk                         (                          ),//同步时钟
    .i_rst_n                           (                          ),//待同步异步复位信号
    .o_sync_rst                        (                          ) //同步复位信号
);

*/

//单bit慢时钟同步到快时钟
module    slow2fast_sync_module(
    input                               i_signal                   ,//待同步信号，慢时钟
    input                               i_clk_fast                 ,//快时钟域
    output                              o_signal                    //输出同步完成的信号
);

(* ASYNC_REG = "TRUE" *)
reg                                     r_s1,r_s2                  ;

assign    o_signal    =    r_s2;

always@(posedge i_clk_fast)begin
    r_s1    <=    i_signal;
    r_s2    <=    r_s1;
end

endmodule
/*

//调用单bit慢时钟同步到快时钟模块
slow2fast_sync_module s2f_sync(
    .i_signal                          (                          ),//待同步信号，慢时钟
    .i_clk_fast                        (                          ),//快时钟域
    .o_signal                          (                          ) //输出同步完成的信号
);

*/

//单bit快时钟同步到慢时钟
module    fast2slow_sync_module(
    input                               i_clk_fast                 ,//快时钟
    input                               i_signal                   ,//
    input                               i_clk_slow                 ,//
    output                              o_signal                    //
);
wire                                    r_pos                      ;
(* ASYNC_REG = "TRUE" *)
reg                                     r_d1,r_d2                  ;

assign    r_pos = i_signal|r_d1|r_d2;

always@(posedge i_clk_fast)begin
    r_d1    <=    i_signal;
    r_d2    <=    r_d1;
end

(* ASYNC_REG = "TRUE" *)
reg                                     r_p1,r_p2                  ;

assign    o_signal = r_p2;

always@(posedge i_clk_slow)begin
    r_p1    <=    i_signal;
    r_p2    <=    r_p1;
end

endmodule

//打两拍
module    beat_it_twice(
    input                               i_sys_clk                  ,
    input                               i_signal                   ,
    output                              o_signal_delay2             
);

(* ASYNC_REG = "TRUE" *)
reg                                     r_rst1,r_rst2              ;

assign    o_signal_delay2 = r_rst2;

always@(posedge i_sys_clk)begin
    r_rst1    <=    i_signal;
    r_rst2    <=    r_rst1;
end

endmodule