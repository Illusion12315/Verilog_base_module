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
    localparam                          H_Sync_Time               = 44    ;// ��ͬ��
    localparam                          H_Back_Porch              = 148   ;// ��ʱ�����
    localparam                          H_Left_Border             = 0     ;// ��ʱ����߿�
    localparam                          H_Addr_Time               = 1920  ;// ����Ч����
    localparam                          H_Right_Border            = 0     ;// ��ʱ���ұ߿�  
    localparam                          H_Front_Porch             = 88    ;// ��ʱ��ǰ��
    localparam                          H_Total_Time              = 2200  ;// ��ɨ������

    localparam                          V_Sync_Time               = 5     ;// ��ͬ��
    localparam                          V_Back_Porch              = 36    ;// ��ʱ�����
    localparam                          V_Top_Border              = 0     ;// ��ʱ���ϱ߿�
    localparam                          V_Addr_Time               = 1080  ;// ����Ч����
    localparam                          V_Bottom_Border           = 0     ;// ��ʱ���±߿�
    localparam                          V_Front_Porch             = 4     ;// ��ʱ��ǰ��
    localparam                          V_Total_Time              = 1125  ;// ��ɨ������

    reg                [  11: 0]        cnt_h                      ;
    reg                [  10: 0]        cnt_v                      ;
    reg                                 rgb_valid                  ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// 
//---------------------------------------------------------------------
// cnt_h:��ͬ���źż�����
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
// hsync:��ͬ���ź�
    assign                              hsync_o                   = (cnt_h <= H_Sync_Time - 'd1) ? 'd1 : 'd0;
// cnt_v:��ͬ���źż�����
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
// vsync:��ͬ���ź�
    assign                              vsync_o                   = (cnt_v <= V_Sync_Time - 'd1) ? 'd1 : 'd0;
// rgb_valid:VGA ��Ч��ʾ����


endmodule