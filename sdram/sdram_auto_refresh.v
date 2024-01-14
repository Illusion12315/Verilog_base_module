`include "sdram_defines.v"

module sdram_auto_refresh (
    input                               sys_clk_i                  ,// clk 100mhz
    input                               rst_n_i                    ,// low active
    
    input                               init_end_i                 ,// ��ʼ�������ź�
    input                               auto_refresh_en_i          ,

    output                              auto_refresh_req_o         ,// �Զ�ˢ������
    output                              auto_refresh_end_o         ,// �Զ�ˢ�½�����־
    output reg         [   3:0]         auto_refresh_cmd_o         ,// �Զ�ˢ�½׶�д�� sdram ��ָ��
    output             [   1:0]         auto_refresh_ba_o          ,// �Զ�ˢ�½׶� Bank ��ַ
    output             [  12:0]         auto_refresh_addr_o         // ��ַ����,����Ԥ������,A12-A0
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// parameter
//---------------------------------------------------------------------
localparam                              AUTO_REFRESH_TIME = 750    ;// �Զ�ˢ�µȴ�ʱ����(7.5us)

localparam                              TRP_CLK_CNT_MAX = 2        ;// Ԥ���ȴ�������
localparam                              TRC_CLK_CNT_MAX = 8        ;// �Զ�ˢ�µȴ�������
localparam                              AUTO_REFRESH_CNT_MAX = 2   ;

localparam                              AUTO_REFRESH_IDLE = 0      ;// ��ʼ״̬
localparam                              AUTO_REFRESH_PCHA = 1      ;// Ԥ���״̬
localparam                              AUTO_REFRESH_TRP = 2       ;// Ԥ���d�ȴ�״̬
localparam                              AUTO_REFRESH_REF = 3       ;// �Զ�ˢ��״̬
localparam                              AUTO_REFRESH_TRF = 4       ;// �Զ�ˢ�µȴ�״̬
localparam                              AUTO_REFRESH_END = 5       ;// �Զ�ˢ�½���״̬
// ********************************************************************************** // 
//---------------------------------------------------------------------
// wires and regs
//---------------------------------------------------------------------
wire                                    trp_end                    ;// Ԥ���ȴ�״̬������־�ź�
wire                                    trc_end                    ;// �Զ�ˢ�µȴ�״̬������־�ź�
reg                    [  15:0]         cnt_auto_refresh_wait      ;
reg                    [   2:0]         next_state                 ;
reg                    [   2:0]         cur_state                  ;
reg                    [   7:0]         cnt_clk                    ;
reg                    [   2:0]         cnt_auto_refresh           ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// main code
//---------------------------------------------------------------------
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cnt_auto_refresh_wait <= 'd0;
    else if (cnt_auto_refresh_wait > AUTO_REFRESH_TIME - 1)
        cnt_auto_refresh_wait <= 'd0;
    else if (init_end_i)
        cnt_auto_refresh_wait <= cnt_auto_refresh_wait + 'd1;
    else
        cnt_auto_refresh_wait <= cnt_auto_refresh_wait;
end
// request for refresh
assign auto_refresh_req_o = (cnt_auto_refresh_wait == AUTO_REFRESH_TIME - 1);

//---------------------------------------------------------------------
// ztj
//---------------------------------------------------------------------
//��һ��,״̬��ת,ʱ���߼�
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cur_state<=AUTO_REFRESH_IDLE;
    else
        cur_state<=next_state;
end

//�ڶ���,��ת����,����߼�
always@(*)begin
    case(cur_state)
        AUTO_REFRESH_IDLE:
            if (auto_refresh_en_i && init_end_i)                    //respond refresh en , then to pre charge
                next_state <= AUTO_REFRESH_PCHA;
            else
                next_state <= AUTO_REFRESH_IDLE;
        AUTO_REFRESH_PCHA: next_state <= AUTO_REFRESH_TRP;
        AUTO_REFRESH_TRP:
            if (trp_end)
                next_state <= AUTO_REFRESH_REF;
            else
                next_state <= AUTO_REFRESH_TRP;
        AUTO_REFRESH_REF: next_state <= AUTO_REFRESH_TRF;
        AUTO_REFRESH_TRF:
            if (trc_end && cnt_auto_refresh == AUTO_REFRESH_CNT_MAX)
                next_state <= AUTO_REFRESH_END;
            else if (trc_end)
                next_state <= AUTO_REFRESH_REF;
            else
                next_state <= AUTO_REFRESH_TRF;
        AUTO_REFRESH_END: next_state <= AUTO_REFRESH_IDLE;
        default: next_state <= AUTO_REFRESH_IDLE;
    endcase
end
//�Զ�ˢ�¼�������ÿһ��ˢ�����󣬻�����ˢ������
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cnt_auto_refresh <= 'd0;
    else if (cur_state == AUTO_REFRESH_END)
        cnt_auto_refresh <= 'd0;
    else if (cur_state == AUTO_REFRESH_REF)
        cnt_auto_refresh <= cnt_auto_refresh + 'd1;
end
//���ڼ������������Ԥ���ȴ����ڣ���ˢ�µȴ�����
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cnt_clk <= 'd0;
    else case (cur_state)
        AUTO_REFRESH_TRP:
            if (trp_end)
                cnt_clk <= 'd0;
            else
                cnt_clk <= cnt_clk + 'd1;
        AUTO_REFRESH_TRF:
            if (trc_end)
                cnt_clk <= 'd0;
            else
                cnt_clk <= cnt_clk + 'd1;
        default: cnt_clk <= 'd0;
    endcase
end
//Ԥ���ȴ���ϱ�־
assign trp_end = (cur_state == AUTO_REFRESH_TRP && cnt_clk == TRP_CLK_CNT_MAX - 1);
//��ˢ�µȴ���ϱ�־
assign trc_end = (cur_state == AUTO_REFRESH_TRF && cnt_clk == TRC_CLK_CNT_MAX - 1);
//һ����ˢ��������Ӧ���
assign auto_refresh_end_o = (cur_state == AUTO_REFRESH_END);

assign auto_refresh_ba_o = 2'b11;

assign auto_refresh_addr_o = 13'h1FFF;

always@(*)begin
    case (cur_state)
        AUTO_REFRESH_PCHA: auto_refresh_cmd_o <= `Precharge;
        AUTO_REFRESH_REF: auto_refresh_cmd_o <= `Refresh;
        default: auto_refresh_cmd_o <= `No_operation;
    endcase
end
endmodule