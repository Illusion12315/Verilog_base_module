`include "sdram_defines.v"

module sdram_read (
    input                               sys_clk_i                  ,// clk 100 mhz
    input                               rst_n_i                    ,// low active

    input                               init_end_i                 ,// ��ʼ�������ź�

    input                               rd_en_i                    ,// ���ݶ�ʹ���ź�
    input              [  23:0]         rd_addr_i                  ,// ���ݶ��׶ε�ַ����
    input              [  15:0]         rd_data_i                  ,// ���ݶ��׶���������
    input              [   9:0]         rd_burst_lenth_i           ,// ��ͻ������,������ֵ�ɸ���ʵ������趨�������ܳ��� SDRAM оƬһ�а����洢��Ԫ�ĸ���

    output                              rd_ack_o                   ,// ���ݶ�������Ӧ
    output                              rd_end_o                   ,// һ��ͻ��������

    output reg         [   3:0]         read_cmd_o                 ,// ���ݶ��׶�ָ��
    output reg         [   1:0]         read_ba_o                  ,// ���ݶ��׶��߼� Bank ��ַ
    output reg         [  12:0]         read_addr_o                ,// ���ݶ��׶ε�ַ���

    output             [  15:0]         rd_sdram_data_o             // ���ݶ��׶��������
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// parameter
//---------------------------------------------------------------------
localparam                              RD_IDLE = 0                ;// ��ʼ��״̬
localparam                              RD_ACTIVE = 1              ;// ����״̬
localparam                              RD_TRCD = 2                ;// ����ȴ�״̬,��Ҫ�ȴ�һ��ʱ��
localparam                              RD_READ = 3                ;// ��ָ��״̬
localparam                              RD_CL = 4                  ;// Ǳ��״̬
localparam                              RD_DATA = 5                ;// ������״̬
localparam                              RD_PRE = 6                 ;// Ԥ���״̬
localparam                              RD_TRP = 7                 ;// Ԥ���ȴ�״̬
localparam                              RD_END = 8                 ;// д����״̬

localparam                              CL_CLK_CNT_MAX = 3         ;// Ǳ���ȴ�������
localparam                              TRCD_CLK_CNT_MAX = 2       ;// ����ȴ�������
localparam                              TRP_CLK_CNT_MAX = 2        ;// Ԥ���ȴ�������
// ********************************************************************************** // 
//---------------------------------------------------------------------
// wires and regs
//---------------------------------------------------------------------
wire                                    trcd_end                   ;
wire                                    tcl_end                    ;
wire                                    tread_end                  ;
wire                                    trp_end                    ;
wire                                    rdburst_end                ;

reg                    [   3:0]         next_state                 ;
reg                    [   3:0]         cur_state                  ;
reg                    [   9:0]         cnt_clk                    ;
reg                    [  15:0]         rd_data_reg                ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// main code
//---------------------------------------------------------------------
//��һ��,״̬��ת,ʱ���߼�
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cur_state<=RD_IDLE;
    else
        cur_state<=next_state;
end

//�ڶ���,��ת����,����߼�
always@(*)begin
    case(cur_state)
        RD_IDLE:
            if (rd_en_i && init_end_i)
                next_state <= RD_ACTIVE;
            else
                next_state <= RD_IDLE;
        RD_ACTIVE: next_state <= RD_TRCD;
        RD_TRCD:
            if (trcd_end)
                next_state <= RD_READ;
            else
                next_state <= RD_TRCD;
        RD_READ: next_state <= RD_CL;
        RD_CL:
            if (tcl_end)
                next_state <= RD_DATA;
            else
                next_state <= RD_CL;
        RD_DATA:
            if (tread_end)
                next_state <= RD_PRE;
            else
                next_state <= RD_DATA;
        RD_PRE: next_state <= RD_TRP;
        RD_TRP:
            if (trp_end)
                next_state <= RD_END;
            else
                next_state <= RD_TRP;
        RD_END: next_state <= RD_IDLE;
        default: next_state <= RD_IDLE;
    endcase
end
//���ڼ�����
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cnt_clk <= 'd0;
    else case (cur_state)
        RD_TRCD:
            if (trcd_end)
                cnt_clk <= 'd0;
            else
                cnt_clk <= cnt_clk + 'd1;
        RD_CL:
            if (tcl_end)
                cnt_clk <= 'd0;
            else
                cnt_clk <= cnt_clk + 'd1;
        RD_DATA:
            if (tread_end)
                cnt_clk <= 'd0;
            else
                cnt_clk <= cnt_clk + 'd1;
        RD_TRP:
            if (trp_end)
                cnt_clk <= 'd0;
            else
                cnt_clk <= cnt_clk + 'd1;
        default: cnt_clk <= 'd0;
    endcase
end

assign trcd_end = (cur_state == RD_TRCD && cnt_clk == TRCD_CLK_CNT_MAX - 1);

assign tcl_end = (cur_state == RD_CL && cnt_clk == CL_CLK_CNT_MAX - 1);

assign tread_end = (cur_state == RD_DATA && cnt_clk == rd_burst_lenth_i + CL_CLK_CNT_MAX - 1);

assign trp_end = (cur_state == RD_TRP && cnt_clk == TRP_CLK_CNT_MAX - 1);
//��Ϊ SDRAM ��ҳͻ�����ݶ������ڶ�ָ��д��󣬵���һ����Ч�������������Ǳ���ڣ���һ��ͻ����Ҫ��ȡ N �����ݣ�����Ҫ�����ݶ�ָ��д���ĵ� N ��ʱ������д��ͻ����ָֹ�
assign rdburst_end = (cur_state == RD_DATA && cnt_clk == rd_burst_lenth_i - CL_CLK_CNT_MAX - 1);

assign rd_ack_o = (cur_state == RD_DATA && (cnt_clk <= rd_burst_lenth_i - 1));

assign rd_end_o = (cur_state == RD_END);

always@(*)begin
    case (cur_state)
        RD_ACTIVE: begin
            read_cmd_o <= `Bank_Active;
            read_ba_o <= rd_addr_i[23:22];
            read_addr_o <= rd_addr_i[21:9];
        end
        RD_READ: begin
            read_cmd_o <= `Read;
            read_ba_o <= rd_addr_i[23:22];
            read_addr_o <= {4'b0000,rd_addr_i[8:0]};
        end
        RD_DATA: begin
            if (rdburst_end) begin
                read_cmd_o <= `Burst_Terminate;
                read_ba_o <= 2'b11;
                read_addr_o <= 13'h1FFF;
            end
            else begin
                read_cmd_o <= `No_operation;
                read_ba_o <= 2'b11;
                read_addr_o <= 13'h1FFF;
            end
        end
        RD_PRE: begin
            read_cmd_o <= `Precharge;
            read_ba_o <= rd_addr_i[23:22];
            read_addr_o <= 13'h0400;
        end
        default: begin
            read_cmd_o <= `No_operation;
            read_ba_o <= 2'b11;
            read_addr_o <= 13'h1FFF;
        end
    endcase
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        rd_data_reg <= 16'd0;
    else
        rd_data_reg <= rd_data_i;
end

assign rd_sdram_data_o = (rd_ack_o)? rd_data_reg : 16'd0;
endmodule