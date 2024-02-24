`include "sdram_defines.v"

module sdram_write (
    input                               sys_clk_i                  ,// clk 100 mhz
    input                               rst_n_i                    ,// low active

    input                               init_end_i                 ,// ��ʼ�������ź�

    input                               wr_en_i                    ,// ����дʹ���ź�
    input              [  23:0]         wr_addr_i                  ,// ����д�׶ε�ַ���� Row address: A0~A12 Column address: A0~A8 [addr] = {bank[23:22],row[21:9],column[8:0]}
    input              [  15:0]         wr_data_i                  ,// ����д�׶���������
    input              [   9:0]         wr_burst_lenth_i           ,// дͻ������,������ֵ�ɸ���ʵ������趨�������ܳ��� SDRAM оƬһ�а����洢��Ԫ�ĸ���

    output                              wr_ack_o                   ,// ����д������Ӧ ���߲��ܸ�������
    output                              wr_end_o                   ,// һ��ͻ��д����

    output reg         [   3:0]         write_cmd_o                ,// ����д�׶�ָ��
    output reg         [   1:0]         write_ba_o                 ,// ����д�׶��߼� Bank ��ַ
    output reg         [  12:0]         write_addr_o               ,// ����д�׶ε�ַ���

    output                              wr_sdram_en_o              ,// ����д�׶��������ʹ��
    output             [  15:0]         wr_sdram_data_o             // ����д�׶��������
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// parameter
//---------------------------------------------------------------------
localparam                              WR_IDLE = 0                ;// ��ʼ��״̬
localparam                              WR_ACTIVE = 1              ;// ����״̬
localparam                              WR_TRCD = 2                ;// ����ȴ�״̬,��Ҫ�ȴ�һ��ʱ��
localparam                              WR_WRITE = 3               ;// дָ��״̬
localparam                              WR_DATA = 4                ;// д����״̬
localparam                              WR_PRE = 5                 ;// Ԥ���״̬
localparam                              WR_TRP = 6                 ;// Ԥ���ȴ�״̬
localparam                              WR_END = 7                 ;// д����״̬

localparam                              TRCD_CLK_CNT_MAX = 2       ;// ����ȴ�������
localparam                              TRP_CLK_CNT_MAX = 2        ;// Ԥ���ȴ�������
// ********************************************************************************** // 
//---------------------------------------------------------------------
// wires and regs
//---------------------------------------------------------------------
wire                                    trcd_end                   ;
wire                                    twrite_end                 ;
wire                                    trp_end                    ;

reg                    [   2:0]         next_state                 ;
reg                    [   2:0]         cur_state                  ;
reg                    [   9:0]         cnt_clk                    ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// main code
//---------------------------------------------------------------------
//��һ��,״̬��ת,ʱ���߼�
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cur_state<=WR_IDLE;
    else
        cur_state<=next_state;
end

//�ڶ���,��ת����,����߼�
always@(*)begin
    case(cur_state)
        WR_IDLE:
            if (wr_en_i && init_end_i)
                next_state <= WR_ACTIVE;
            else
                next_state <= WR_IDLE;
        WR_ACTIVE: next_state <= WR_TRCD;
        WR_TRCD:
            if (trcd_end)
                next_state <= WR_WRITE;
            else
                next_state <= WR_TRCD;
        WR_WRITE: next_state <= WR_DATA;
        WR_DATA:
            if (twrite_end)
                next_state <= WR_PRE;
            else
                next_state <= WR_DATA;
        WR_PRE: next_state <= WR_TRP;
        WR_TRP:
            if (trp_end)
                next_state <= WR_END;
            else
                next_state <= WR_TRP;
        WR_END: next_state <= WR_IDLE;
        default: next_state <= WR_IDLE;
    endcase
end
//���ڼ�����
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cnt_clk <= 'd0;
    else case (cur_state)
        WR_TRCD:
            if (trcd_end)
                cnt_clk <= 'd0;
            else
                cnt_clk <= cnt_clk + 'd1;
        WR_DATA:
            if (twrite_end)
                cnt_clk <= 'd0;
            else
                cnt_clk <= cnt_clk + 'd1;
        WR_TRP:
            if (trp_end)
                cnt_clk <= 'd0;
            else
                cnt_clk <= cnt_clk + 'd1;
        default: cnt_clk <= 'd0;
    endcase
end

assign trcd_end = (cur_state == WR_TRCD && cnt_clk == TRCD_CLK_CNT_MAX - 1);

assign twrite_end = (cur_state == WR_DATA && cnt_clk == wr_burst_lenth_i - 1);

assign trp_end = (cur_state == WR_TRP && cnt_clk == TRP_CLK_CNT_MAX - 1);

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        write_cmd_o <= `No_operation;
        write_ba_o <= 2'b11;
        write_addr_o <= 13'h1FFF;
    end
    else case (cur_state)
        WR_ACTIVE: begin
            write_cmd_o <= `Bank_Active;
            write_ba_o <= wr_addr_i[23:22];                         // bank
            write_addr_o <= wr_addr_i[21:9];                        // row
        end
        WR_WRITE: begin
            write_cmd_o <= `Write;
            write_ba_o <= wr_addr_i[23:22];                         // bank
            write_addr_o <= {4'b0000,wr_addr_i[8:0]};               // Column
        end
        WR_DATA: begin
            if (twrite_end) begin
                write_cmd_o <= `Burst_Terminate;
                write_ba_o <= 2'b11;
                write_addr_o <= 13'h1FFF;
            end
            else begin
                write_cmd_o <= `No_operation;
                write_ba_o <= 2'b11;
                write_addr_o <= 13'h1FFF;
            end
        end
        WR_PRE: begin
            write_cmd_o <= `Precharge;
            write_ba_o <= wr_addr_i[23:22];
            write_addr_o <= 13'h0400;
        end
        default: begin
            write_cmd_o <= `No_operation;
            write_ba_o <= 2'b11;
            write_addr_o <= 13'h1FFF;
        end
    endcase
end

assign wr_ack_o = (cur_state == WR_DATA);

assign wr_end_o = (cur_state == WR_END);

assign wr_sdram_en_o = (cur_state == WR_DATA);

assign wr_sdram_data_o = (cur_state == WR_DATA)? wr_data_i:'d0;

endmodule