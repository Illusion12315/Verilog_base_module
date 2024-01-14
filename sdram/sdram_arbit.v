`include "sdram_defines.v"

module sdram_arbit (
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,
    // init
    input  wire        [   3:0]         init_cmd_i                 ,// ��ʼ���׶�д�� sdram ��ָ��
    input  wire        [   1:0]         init_ba_i                  ,// ��ʼ���׶� Bank ��ַ
    input  wire        [  12:0]         init_addr_i                ,// ��ʼ���׶ε�ַ����,����Ԥ��������ģʽ�Ĵ�������,A12-A0
    input  wire                         init_end_i                 ,// ��ʼ�������ź�
    // auto refresh
    input                               auto_refresh_req_i         ,// �Զ�ˢ������
    input                               auto_refresh_end_i         ,// �Զ�ˢ�½�����־
    input  wire        [   3:0]         auto_refresh_cmd_i         ,// �Զ�ˢ�½׶�д�� sdram ��ָ��
    input              [   1:0]         auto_refresh_ba_i          ,// �Զ�ˢ�½׶� Bank ��ַ
    input              [  12:0]         auto_refresh_addr_i        ,// ��ַ����,����Ԥ������,A12-A0
    output                              auto_refresh_en_o          ,// �Զ�ˢ��ʹ��
    // write
    input                               wr_req_i                   ,// д���� �����ⲿ
    input                               wr_end_i                   ,// һ��ͻ��д����

    input  wire        [   3:0]         write_cmd_i                ,// ����д�׶�ָ��
    input  wire        [   1:0]         write_ba_i                 ,// ����д�׶��߼� Bank ��ַ
    input  wire        [  12:0]         write_addr_i               ,// ����д�׶ε�ַ���

    input                               wr_sdram_en_i              ,// ����д�׶��������ʹ��
    input              [  15:0]         wr_sdram_data_i            ,// ����д�׶��������
    
    output                              wr_en_o                    ,// ����дʹ���ź�
    // read
    input                               rd_req_i                   ,
    input                               rd_end_i                   ,// һ��ͻ��������

    input  wire        [   3:0]         read_cmd_i                 ,// ���ݶ��׶�ָ��
    input  wire        [   1:0]         read_ba_i                  ,// ���ݶ��׶��߼� Bank ��ַ
    input  wire        [  12:0]         read_addr_i                ,// ���ݶ��׶ε�ַ���
    
    output                              rd_en_o                    ,// ���ݶ�ʹ���ź�
    output             [  15:0]         rd_data_o                  ,// ���ݶ��׶���������
    // sdram ctrl interface
    output reg         [   1:0]         sdram_ba_o                 ,
    output reg         [  12:0]         sdram_addr_o               ,
    output                              sdram_dq_en_o              ,
    output             [  15:0]         sdram_dq_o                 ,
    input              [  15:0]         sdram_dq_i                 ,
    output                              sdram_cke_o                ,
    output                              sdram_cs_n_o               ,
    output                              sdram_ras_n_o              ,
    output                              sdram_cas_n_o              ,
    output                              sdram_we_n_o                

);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// localparam
//---------------------------------------------------------------------
localparam                              ARBIT_IDLE = 0             ;
localparam                              ARBIT_ARBIT = 1            ;
localparam                              ARBIT_AUTO_REFRESH = 2     ;
localparam                              ARBIT_WRITE = 3            ;
localparam                              ARBIT_READ = 4             ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// regs
//---------------------------------------------------------------------
reg                    [   2:0]         next_state                 ;
reg                    [   2:0]         cur_state                  ;
reg                    [   3:0]         sdram_cmd                  ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// main code
//---------------------------------------------------------------------
//��һ��,״̬��ת,ʱ���߼�
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cur_state<=ARBIT_IDLE;
    else
        cur_state<=next_state;
end

//�ڶ���,��ת����,����߼�
always@(*)begin
    case(cur_state)
        ARBIT_IDLE:
            if (init_end_i)
                next_state <= ARBIT_ARBIT;
            else
                next_state <= ARBIT_IDLE;
        ARBIT_ARBIT:
            if (auto_refresh_req_i)
                next_state <= ARBIT_AUTO_REFRESH;
            else if (wr_req_i)
                next_state <= ARBIT_WRITE;
            else if (rd_req_i)
                next_state <= ARBIT_READ;
            else
                next_state <= ARBIT_ARBIT;
        ARBIT_AUTO_REFRESH:
            if (auto_refresh_end_i)
                next_state <= ARBIT_ARBIT;
            else
                next_state <= ARBIT_AUTO_REFRESH;
        ARBIT_WRITE:
            if (wr_end_i)
                next_state <= ARBIT_ARBIT;
            else
                next_state <= ARBIT_WRITE;
        ARBIT_READ:
            if (rd_end_i)
                next_state <= ARBIT_ARBIT;
            else
                next_state <= ARBIT_READ;
        default: next_state <= ARBIT_IDLE;
    endcase
end

// auto refresh
assign auto_refresh_en_o = (cur_state == ARBIT_AUTO_REFRESH);
// write
assign wr_en_o = (cur_state == ARBIT_WRITE);
// read
assign rd_en_o = (cur_state == ARBIT_READ);

assign {sdram_cs_n_o,sdram_ras_n_o,sdram_cas_n_o,sdram_we_n_o} = sdram_cmd;

always@(*)begin
    case (cur_state)
        ARBIT_IDLE: begin
            sdram_cmd <= init_cmd_i;
            sdram_ba_o <= init_ba_i;
            sdram_addr_o <= init_addr_i;
        end
        ARBIT_ARBIT: begin
            sdram_cmd <= `No_operation;
            sdram_ba_o <= 2'b11;
            sdram_addr_o <= 13'h1FFF;
        end
        ARBIT_AUTO_REFRESH: begin
            sdram_cmd <= auto_refresh_cmd_i;
            sdram_ba_o <= auto_refresh_ba_i;
            sdram_addr_o <= auto_refresh_addr_i;
        end
        ARBIT_WRITE: begin
            sdram_cmd <= write_cmd_i;
            sdram_ba_o <= write_ba_i;
            sdram_addr_o <= write_addr_i;
        end
        ARBIT_READ: begin
            sdram_cmd <= read_cmd_i;
            sdram_ba_o <= read_ba_i;
            sdram_addr_o <= read_addr_i;
        end
        default: begin
            sdram_cmd <= `No_operation;
            sdram_ba_o <= 2'b11;
            sdram_addr_o <= 13'h1FFF;
        end
    endcase
end

assign sdram_dq_en_o = wr_sdram_en_i;

assign sdram_dq_o = (wr_sdram_en_i)? wr_sdram_data_i:'d0;

assign rd_data_o = sdram_dq_i;
endmodule