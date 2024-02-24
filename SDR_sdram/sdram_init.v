`include "sdram_defines.v"

module sdram_init (
    input                               sys_clk_i                  ,// clk 100 mhz
    input                               rst_n_i                    ,// low active

    output reg         [   3:0]         init_cmd_o                 ,// ��ʼ���׶�д�� sdram ��ָ��
    output reg         [   1:0]         init_ba_o                  ,// ��ʼ���׶� Bank ��ַ
    output reg         [  12:0]         init_addr_o                ,// ��ʼ���׶ε�ַ����,����Ԥ��������ģʽ�Ĵ�������,A12-A0

    output wire                         init_end_o                  // ��ʼ�������ź�
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// localparam
//---------------------------------------------------------------------
localparam                              TIME_125us = 12_500        ;

localparam                              INIT_IDLE = 'd0            ;// ��ʼ״̬
localparam                              INIT_PRE = 'd1             ;// Ԥ���״̬
localparam                              INIT_TRP = 'd2             ;// Ԥ���d�ȴ�״̬
localparam                              INIT_AR = 'd3              ;// �Զ�ˢ��״̬
localparam                              INIT_TRF = 'd4             ;// �Զ�ˢ�µȴ�״̬
localparam                              INIT_MRS = 'd5             ;// ����ģʽ�Ĵ���״̬
localparam                              INIT_TMRD = 'd6            ;// ����ģʽ�Ĵ���״̬
localparam                              INIT_END = 'd7             ;// ��ʼ�����״̬

localparam                              AUTO_REFRESH_CNT_MAX = 8   ;// �Զ�ˢ�´���
localparam                              TRP_CLK_CNT_MAX = 2        ;// Ԥ���ȴ�������
localparam                              TRC_CLK_CNT_MAX = 8        ;// �Զ�ˢ�µȴ�������
localparam                              TMRD_CLK_CNT_MAX = 3       ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// wires & regs
//---------------------------------------------------------------------
wire                                    wait_end                   ;
wire                                    trp_end                    ;// Ԥ���ȴ�״̬������־�ź�
wire                                    trc_end                    ;// �Զ�ˢ�µȴ�״̬������־�ź�
wire                                    tmrd_end                   ;// �Զ�ˢ�µȴ�״̬������־�ź�
reg                    [  15:0]         cnt_125us                  ;
reg                    [   2:0]         next_state                 ;
reg                    [   2:0]         cur_state                  ;
reg                    [   7:0]         cnt_clk                    ;
reg                    [   4:0]         cnt_init_auto_refresh      ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// main code
//---------------------------------------------------------------------
//��һ��,״̬��ת,ʱ���߼�
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cur_state<=INIT_IDLE;
    else
        cur_state<=next_state;
end

//�ڶ���,��ת����,����߼�
always@(*)begin
    case(cur_state)
        INIT_IDLE:                                                  // ִ�пղ���ָ��
            if (wait_end)
                next_state <= INIT_PRE;
            else
                next_state <= INIT_IDLE;
        INIT_PRE: next_state <= INIT_TRP;
        INIT_TRP:                                                   // ִ�пղ���ָ��
            if (trp_end)
                next_state <= INIT_AR;
            else
                next_state <= INIT_TRP;
        INIT_AR: next_state <= INIT_TRF;
        INIT_TRF:                                                   // ִ�пղ���ָ��
            if (trc_end && cnt_init_auto_refresh == AUTO_REFRESH_CNT_MAX)
                next_state <= INIT_MRS;
            else if (trc_end)
                next_state <= INIT_AR;
            else
                next_state <= INIT_TRF;
        INIT_MRS: next_state <= INIT_TMRD;
        INIT_TMRD:                                                  // ִ�пղ���ָ��
            if (tmrd_end)
                next_state <= INIT_END;
            else
                next_state <= INIT_TMRD;
        INIT_END: next_state <= INIT_END;                           // ��ʼ�����״̬,���ִ�״̬
        default: next_state <= INIT_IDLE;
    endcase
end
//---------------------------------------------------------------------
// logic
//---------------------------------------------------------------------
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cnt_125us <= 'd0;
    else if (cnt_125us < TIME_125us)
        cnt_125us <= cnt_125us + 'd1;
end

assign wait_end = (cnt_125us == TIME_125us - 1)? 'd1:'d0;

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cnt_init_auto_refresh <= 'd0;
    else if (cur_state == INIT_END)
        cnt_init_auto_refresh <= 'd0;
    else if (cur_state == INIT_AR)
        cnt_init_auto_refresh <= cnt_init_auto_refresh + 'd1;
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cnt_clk <= 'd0;
    else case (cur_state)
        INIT_TRP:
            if (trp_end)
                cnt_clk <= 'd0;
            else
                cnt_clk <= cnt_clk + 'd1;
        INIT_TRF:
            if (trc_end)
                cnt_clk <= 'd0;
            else
                cnt_clk <= cnt_clk + 'd1;
        INIT_TMRD:
            if (tmrd_end)
                cnt_clk <= 'd0;
            else
                cnt_clk <= cnt_clk + 'd1;
        default: cnt_clk <= 'd0;
    endcase
end

assign trp_end = (cur_state == INIT_TRP) & (cnt_clk == TRP_CLK_CNT_MAX - 1);

assign trc_end = (cur_state == INIT_TRF) & (cnt_clk == TRC_CLK_CNT_MAX - 1);

assign tmrd_end = (cur_state == INIT_TMRD) & (cnt_clk == TMRD_CLK_CNT_MAX - 1);

always@(*)begin
    case (cur_state)
        INIT_PRE: begin                                             // Ԥ���ָ��
            init_cmd_o <= `Precharge;
            init_ba_o <= 2'b11;
            init_addr_o <= 13'h1fff;
        end
        INIT_AR: begin                                              // �Զ�ˢ��ָ��
            init_cmd_o <= `Refresh;
            init_ba_o <= 2'b11;
            init_addr_o <= 13'h1fff;
        end
        INIT_MRS: begin                                             // ģʽ�Ĵ�������ָ��
            init_cmd_o <= `Load_Mode_Register;
            init_ba_o <= 2'b00;
            init_addr_o <= {                                        // ��ַ��������ģʽ�Ĵ���,������ͬ,���õ�ģʽ��ͬ
            3'b000,                                                 // A12-A10:Ԥ��
            1'b0,                                                   // A9=0:��д��ʽ,0:ͻ����&ͻ��д,1:ͻ����&��д
            2'b00,                                                  // {A8,A7}=00:��׼ģʽ,Ĭ��
            3'b011,                                                 // {A6,A5,A4}=011:CAS Ǳ����,010:2,011:3,����:����
            1'b0,                                                   // A3=0:ͻ�����䷽ʽ,0:˳��,1:����
            3'b111                                                  // {A2,A1,A0}=111:ͻ������,000:���ֽ�,001:2 �ֽ�,010:4 �ֽ�,011:8 �ֽ�,111:��ҳ,����:����
            };
        end
        default: begin
            init_cmd_o <= `No_operation;
            init_ba_o <= 2'b11;
            init_addr_o <= 13'h1fff;
        end
    endcase
end

assign init_end_o = (cur_state == INIT_END);
endmodule