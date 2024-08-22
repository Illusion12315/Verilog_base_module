`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             I2C_slave_standard
// Create Date:           2024/08/15 19:17:52
// Version:               V1.0
// PATH:                  E:\FPGA\module_base\i2c\I2C_slave\v3\I2C_slave_standard.v
// Descriptions:          
// 
// ********************************************************************************** // 
`default_nettype none


module I2C_slave_standard (
    input  wire                         sys_clk_i                  ,
    input  wire                         rst_n_i                    ,

    input  wire        [   6: 0]        I2C_ADR                    ,

    output wire                         ram_wr_en_o                ,
    output wire        [   7: 0]        ram_wr_addr_o              ,
    output wire        [  31: 0]        ram_wr_data_o              ,

    output wire                         ram_rd_en_o                ,
    output wire        [   7: 0]        ram_rd_addr_o              ,
    input  wire        [  31: 0]        ram_rd_data_i              ,

    input  wire                         SCL                        ,
    inout  wire                         SDA                         
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// ����SCL��SDA�ź�
//---------------------------------------------------------------------
    wire                                SCL_pe                     ;// SCL������
    wire                                SCL_ne                     ;// SCL�½���
    wire                                SDA_pe                     ;// SDA������
    wire                                SDA_ne                     ;// SDA�½���
// ����I2C��ʼ�ͽ����ź�
    wire                                i2c_start                  ;
    wire                                i2c_stop                   ;
// ����SCL��SDA�������Ĵ��������ڱ�Ե���
    reg                                 SCL_r1='d1,SCL_r2='d1,SCL_r3='d1  ;
    reg                                 SDA_r1='d1,SDA_r2='d1,SDA_r3='d1  ;
// ����SCL��SDA�������غ��½����ź�
    assign                              SCL_pe                    = SCL_r2 & ~SCL_r3;// SCL������
    assign                              SCL_ne                    = ~SCL_r2 & SCL_r3;// SCL�½���
    assign                              SDA_pe                    = SDA_r2 & ~SDA_r3;// SDA������
    assign                              SDA_ne                    = ~SDA_r2 & SDA_r3;// SDA�½���
// ����I2C��ʼ�ͽ�������
    assign                              i2c_start                 = SCL_r2 & SDA_ne;
    assign                              i2c_stop                  = SCL_r2 & SDA_pe;
// ��ϵͳʱ�ӵ������ز���SDA�ź�
always@(posedge sys_clk_i)begin
    SCL_r1 <= SCL;
    SCL_r2 <= SCL_r1;
    SCL_r3 <= SCL_r2;

    SDA_r1 <= SDA;
    SDA_r2 <= SDA_r1;
    SDA_r3 <= SDA_r2;
end
// ״̬����ʼ
//---------------------------------------------------------------------
// state machine
//---------------------------------------------------------------------
    localparam                          S_SLAVE_IDLE              = 0     ; // �ӻ�����״̬
    localparam                          S_MASTER_WRITE_DEVICE_ADR = 1     ; // ����д�豸��ַ״̬
    localparam                          S_MASTER_WRITE_WORD_ADR   = 2     ; // ����д���ֵ�ַ״̬
    localparam                          S_MASTER_WRITE_DATA       = 3     ; // ����д����״̬
    localparam                          S_SLAVE_WAIT_INCYCLE      = 4     ; // �ӻ��ȴ�����״̬
    localparam                          S_MASTER_READ_DEVICE_ADR  = 5     ; // �������豸��ַ״̬
    localparam                          S_SLAVE_SEND_READ_DATA    = 6     ; // �ӻ����Ͷ�����״̬
    localparam                          S_SLAVE_STOP              = 7     ; // �ӻ�ֹͣ״̬
// ����
    wire                                bit_ack                    ;
    wire                                bit_data                   ;
    wire               [   7: 0]        read_data           [0:3]  ;
    reg                [   7: 0]        write_data          [0:3]  ;
// �Ƿ�Ϊ��Ч����
    reg                                 incycle                  ='d0;
// ����״̬��״̬�����ͼ�����
    reg                [   2: 0]        state                    =3'd0;
    reg                [   3: 0]        bytecnt                  =4'd0;// �ֽڼ�����
    reg                [   3: 0]        bitcnt                   =4'h0;// λ������
    reg                                 SDA_delay                =1'd1;// SDA��ʱ�ź�
    reg                                 adr_match                =1'b1;// ��ַƥ���ź�
    reg                [   7: 0]        op_addr                  =8'd0;
    reg                                 SDA_en                   =1'd0;
    reg                                 SDA_data                 =1'd0;
// Ӧ��״̬������״̬
    assign                              bit_ack                   = bitcnt[3];// the ACK bit is the 9th bit sent
    assign                              bit_data                  = ~bitcnt[3];// the DATA bits are the first 8 bits sent
// SDA��̬��
    assign                              SDA                       = SDA_en ? SDA_data : 1'bz;
// I2C״̬���߼�
always@(posedge sys_clk_i)begin
    if(!rst_n_i)
        state <= S_SLAVE_IDLE;
    else case(state)
        S_SLAVE_IDLE:
            if(incycle)
                state <= S_MASTER_WRITE_DEVICE_ADR;
        S_MASTER_WRITE_DEVICE_ADR:
            if(~incycle)
                state <= S_SLAVE_IDLE;
            else if(SCL_ne && bit_ack)
                state <= S_MASTER_WRITE_WORD_ADR;
        S_MASTER_WRITE_WORD_ADR:
            if(~incycle)
                state <= S_SLAVE_IDLE;
            else if(SCL_ne && bit_ack)
                state <= S_MASTER_WRITE_DATA;
        S_MASTER_WRITE_DATA:
            if(i2c_start)
                state <= S_SLAVE_WAIT_INCYCLE;
            else if(i2c_stop)
                state <= S_SLAVE_IDLE;
        S_SLAVE_WAIT_INCYCLE:
            if(incycle)
                state <= S_MASTER_READ_DEVICE_ADR;
        S_MASTER_READ_DEVICE_ADR:
            if(~incycle)
                state <= S_SLAVE_IDLE;
            else if(SCL_ne && bit_ack)
                state <= S_SLAVE_SEND_READ_DATA;
        S_SLAVE_SEND_READ_DATA:
            if(~incycle)
                state <= S_SLAVE_IDLE;
            else if(SCL_ne && bit_ack && SDA_r2)
                state <= S_SLAVE_STOP;
        S_SLAVE_STOP:
            if(i2c_stop)
                state <= S_SLAVE_IDLE;
        default:state <= S_SLAVE_IDLE;
    endcase
end
// ���ڼ������߼�
always@(posedge sys_clk_i)begin
    if(i2c_start | i2c_stop)
        incycle <= 1'b0;
    else if(SCL_ne && ~SDA_r2)
        incycle <= 1'b1;
end
// ��һ�ģ�����SDA�ź�
always @(posedge sys_clk_i)begin                                    // ��ϵͳʱ�ӵ������ز���SDA�ź�
    if(SCL_pe)
        SDA_delay <= SDA;
    else
        SDA_delay <= SDA_delay;
end
// λ�������߼�
always@(posedge sys_clk_i)begin
    case (state)
        S_MASTER_WRITE_DEVICE_ADR,
        S_MASTER_WRITE_WORD_ADR,
        S_MASTER_WRITE_DATA,
        S_MASTER_READ_DEVICE_ADR,
        S_SLAVE_SEND_READ_DATA:
            if(SCL_ne && bit_ack)
                bitcnt <= 4'h7;
            else if(SCL_ne)
                bitcnt <= bitcnt - 4'h1;
            else
                bitcnt <= bitcnt;
        default: bitcnt <= 4'h7;                                    // λ7���ȱ�����
    endcase
end
// �ֽڼ������߼�
always@(posedge sys_clk_i)begin
    case (state)
        S_SLAVE_IDLE: bytecnt <= 'd0;
        S_MASTER_WRITE_DATA,S_SLAVE_SEND_READ_DATA:
            if(SCL_ne && bit_ack)
                bytecnt <= bytecnt + 'd1;
            else
                bytecnt <= bytecnt;
        default:bytecnt <= bytecnt;
    endcase
end
// �жϵ�ַ�Ƿ�ƥ��
always@(posedge sys_clk_i)begin
    case (state)
        S_SLAVE_IDLE: adr_match <= 'd1;
        S_MASTER_WRITE_DEVICE_ADR,S_MASTER_READ_DEVICE_ADR:
            case (bitcnt)
                1,2,3,4,5,6,7:
                    if((SDA_delay != I2C_ADR[bitcnt-1]) & SCL_ne)
                        adr_match <= 1'b0;
                default:adr_match <= adr_match;
            endcase
        default:adr_match <= adr_match;
    endcase
end
// ��ȡ������ַ
always@(posedge sys_clk_i)begin
    if(adr_match && (state == S_MASTER_WRITE_WORD_ADR) && bit_data && SCL_ne)
        op_addr[bitcnt] <= SDA_delay;
end
// ��ȡд��������
always@(posedge sys_clk_i)begin
    if(adr_match && (state == S_MASTER_WRITE_DATA) && bit_data && SCL_ne)
        case (bytecnt)
            0,1,2,3: write_data[bytecnt][bitcnt] <= SDA_delay;
            default: write_data[bytecnt][bitcnt] <= write_data[bytecnt][bitcnt];
        endcase
end
// ���SDA��̬��ʹ��
always@(posedge sys_clk_i)begin
    case (state)
        S_MASTER_WRITE_DEVICE_ADR,S_MASTER_WRITE_WORD_ADR,S_MASTER_WRITE_DATA,S_MASTER_READ_DEVICE_ADR:
            if(bit_ack && adr_match)
                SDA_en <= 'd1;
            else
                SDA_en <= 'd0;
        S_SLAVE_SEND_READ_DATA:
            if(bit_data && adr_match)
                SDA_en <= 'd1;
            else
                SDA_en <= 'd0;
        default:SDA_en <= 'd0;
    endcase
end
// ���SDA,����Ӧ��Ͷ�����
always@(posedge sys_clk_i)begin
    case (state)
        S_MASTER_WRITE_DEVICE_ADR,S_MASTER_WRITE_WORD_ADR,S_MASTER_WRITE_DATA,S_MASTER_READ_DEVICE_ADR:
            if(bit_ack && adr_match)
                SDA_data <= 'd0;
            else
                SDA_data <= 'd1;
        S_SLAVE_SEND_READ_DATA:
            if(bit_data && adr_match)
                SDA_data <= read_data[bytecnt][bitcnt[2:0]];
            else
                SDA_data <= 'd1;
        default:SDA_data <= 'd1;
    endcase
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// ���
//---------------------------------------------------------------------
    reg                                 i2c_wr_valid_r1,i2c_wr_valid_r2  ;
    reg                                 i2c_rd_valid_r1,i2c_rd_valid_r2  ;

always@(posedge sys_clk_i)begin
    if((state == S_MASTER_WRITE_DATA) && (i2c_stop) && adr_match)
        i2c_wr_valid_r1 <= 'd1;
    else
        i2c_wr_valid_r1 <= 'd0;
end

always@(posedge sys_clk_i)begin
    if((state == S_MASTER_READ_DEVICE_ADR) && (SCL_ne && bit_ack) && adr_match)
        i2c_rd_valid_r1 <= 'd1;
    else
        i2c_rd_valid_r1 <= 'd0;
end

always@(posedge sys_clk_i)begin
    i2c_wr_valid_r2 <= i2c_wr_valid_r1;
    i2c_rd_valid_r2 <= i2c_rd_valid_r1;
end

    assign                              ram_wr_en_o               = i2c_wr_valid_r1 & ~i2c_wr_valid_r2;

    assign                              ram_rd_en_o               = i2c_rd_valid_r1 & ~i2c_rd_valid_r2;

    assign                              ram_wr_addr_o             = op_addr;

    assign                              ram_rd_addr_o             = op_addr;

    assign                              ram_wr_data_o             = {write_data[0],write_data[1],write_data[2],write_data[3]};

    assign                              {read_data[0],read_data[1],read_data[2],read_data[3]}= ram_rd_data_i;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// debug
//---------------------------------------------------------------------













endmodule

`default_nettype wire