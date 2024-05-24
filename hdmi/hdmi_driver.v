module hdmi_driver #(
    parameter                           N                         = 1     
) (
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,

    input              [  15: 0]        pix_data_i                 ,

    output reg         [  10: 0]        pix_x_o                    ,// 1920
    output reg         [  10: 0]        pix_y_o                    ,// 1080

    output                              hsync_o                    ,
    output                              vsync_o                    ,
    output reg         [  15: 0]        rgb_o                       
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// declaration
//---------------------------------------------------------------------
    localparam                          H_Sync_Time               = 44    ;// 行同步
    localparam                          H_Back_Porch              = 148   ;// 行时序后沿
    localparam                          H_Left_Border             = 0     ;// 行时序左边框
    localparam                          H_Addr_Time               = 1920  ;// 行有效数据
    localparam                          H_Right_Border            = 0     ;// 行时序右边框  
    localparam                          H_Front_Porch             = 88    ;// 行时序前沿
    localparam                          H_Total_Time              = 2200  ;// 行扫描周期

    localparam                          V_Sync_Time               = 5     ;// 场同步
    localparam                          V_Back_Porch              = 36    ;// 场时序后沿
    localparam                          V_Top_Border              = 0     ;// 场时序上边框
    localparam                          V_Addr_Time               = 1080  ;// 场有效数据
    localparam                          V_Bottom_Border           = 0     ;// 场时序下边框
    localparam                          V_Front_Porch             = 4     ;// 场时序前沿
    localparam                          V_Total_Time              = 1125  ;// 场扫描周期

    reg                [  11: 0]        cnt_h                      ;
    reg                [  10: 0]        cnt_v                      ;
    reg                                 rgb_valid                  ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// 
//---------------------------------------------------------------------
// cnt_h:行同步信号计数器
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        cnt_h <= 'd0;
    end
    else if (cnt_h == H_Total_Time - 1) begin
        cnt_h <= 'd0;
    end
    else begin
        cnt_h <= cnt_h + 'd1;
    end
end
// hsync:行同步信号
    assign                              hsync_o                   = (cnt_h <= H_Sync_Time - 'd1) ? 'd1 : 'd0;
// cnt_v:场同步信号计数器
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        cnt_v <= 'd0;
    end
    else if ((cnt_v == V_Total_Time - 'd1) && (cnt_h == H_Total_Time - 1)) begin
        cnt_v <= 'd0;
    end
    else if (cnt_h == H_Total_Time - 1) begin
        cnt_v <= cnt_v + 'd1;
    end
    else begin
        cnt_h <= cnt_h;
    end
end
// vsync:场同步信号
    assign                              vsync_o                   = (cnt_v <= V_Sync_Time - 'd1) ? 'd1 : 'd0;
// rgb_valid:VGA 有效显示区域


endmodule