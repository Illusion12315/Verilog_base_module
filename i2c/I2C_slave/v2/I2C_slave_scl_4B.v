`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             I2C_slave_scl_4B
// Create Date:           2024/06/06 15:07:39
// Version:               V1.0
// PATH:                  C:\Users\Administrator\Desktop\project\module base\i2c\I2C_for_sim\I2C_for_sim.srcs\sources_1\I2C_slave_scl_4B.v
// Descriptions:          
// 
// ********************************************************************************** // 


// Please define one of these before starting synthesis
`define Xilinx
// `define Altera
// `default_nettype none

module I2C_slave_scl_4B #(
    // The 7-bits address that we want for our I2C slave
    parameter                           I2C_ADR                   = 7'h27 
) (
    input  wire                         sys_clk_i                  ,
    input  wire                         rst_n_i                    ,

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
// I2C start and stop conditions detection logic
//---------------------------------------------------------------------
// this module is used to get a singal when sda is changed while scl is high.
    wire                                SDA_shadow                 ;
    wire                                start_or_stop              ;// ��⿪ʼ�ͽ���

// this is very important!!!
`ifdef Xilinx
BUF mybuf(
    .O                                  (SDA_shadow                ),
    .I                                  ((~SCL | start_or_stop) ? SDA : SDA_shadow) 
);
BUF SOS_BUF(
    .O                                  (start_or_stop             ),
    .I                                  (~SCL ? 1'b0 : (SDA ^ SDA_shadow)) 
);
`else
    assign SDA_shadow = (~SCL | start_or_stop) ? SDA : SDA_shadow ;/* synthesis keep = 1 */
    assign start_or_stop = ~SCL ? 1'b0 : (SDA ^ SDA_shadow) ;/* synthesis keep = 1 */
`endif

// reg incycle;
    reg                                 incycle                  =1'b0;//for simulation MBL
// ��ʼ�����I2C��Ч״̬
always @(negedge SCL or posedge start_or_stop)begin
    if(start_or_stop)
        incycle <= 1'b0;
    else if(~SDA)
        incycle <= 1'b1;
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// main code
//---------------------------------------------------------------------
    wire                                bit_DATA                   ;
    wire                                bit_ACK                    ;
    wire                                op_write                   ;
    wire               [   7: 0]        read_data           [0:3]  ;
    reg                                 SDA_en                   =1'd0;
    reg                                 SDA_data                 =1'd0;
    reg                                 SDA_r1                   =1'b0;//for simulation MBL
    reg                                 op_read                  =1'd0;
    reg                [   7: 0]        op_addr                  =8'd0;
    reg                [   7: 0]        write_data          [0:3]  ;
    reg                                 adr_match                =1'b0;
    reg                [   3: 0]        bytecnt                  =4'd0;
    reg                [   3: 0]        bitcnt                   =4'h0;//for simulation MBL
    integer                             i                          ;
// for simulation
initial begin
    for (i = 0; i<4; i=i+1) begin
        write_data[i] = 'd0;
    end
end
// ����SDA��̬��
    assign                              SDA                       = SDA_en ? SDA_data : 1'bz;
// д����
    assign                              op_write                  = ~op_read;
// Ϊ��ʱ,����data�������
    assign                              bit_ACK                   = bitcnt[3];// the ACK bit is the 9th bit sent
// Ϊ��ʱ,����ǰ����DATA����
    assign                              bit_DATA                  = ~bitcnt[3];// the DATA bits are the first 8 bits sent
// ��һ��
always @(posedge SCL)begin                                          // sample SDA on posedge since the I2C spec specifies as low as 0s hold-time on negedge
    SDA_r1 <= SDA;
end
// bit������,��7->0(counts the I2C bits from 7 downto 0, plus an ACK bit)
always@(negedge SCL or negedge incycle)begin
    if(!incycle)
        bitcnt <= 4'h7;                                             // the bit 7 is received first
    else if(bit_ACK)
        bitcnt <= 4'h7;
    else
        bitcnt <= bitcnt - 4'h1;
end
// byte������,1byteΪ�豸ID,2byteΪ��ַ,3,4,5,6byteΪ����
always@(negedge SCL or negedge incycle)begin
    if(!incycle)
        bytecnt <= 'd0;
    else if(bit_ACK)
        bytecnt <= bytecnt + 'd1;
    else
        bytecnt <= bytecnt;
end
// �жϵ�ַ�Ƿ�ƥ��
always@(negedge SCL or negedge incycle)begin
    if(!incycle)
        adr_match <= 'd1;
    else case (bitcnt)
        1,2,3,4,5,6,7:
            if((bytecnt == 'd0) & SDA_r1 != I2C_ADR[bitcnt-1])
                adr_match <= 1'b0;
        default: adr_match <= adr_match;
    endcase
end
// ��дλbit[0]Ϊ�ʹ���ǰΪ������
always@(negedge SCL or negedge incycle)begin
    if(!incycle)
        op_read <= 'd0;
    else if((bytecnt == 'd0) & bitcnt==0)
        op_read <= SDA_r1;
end
// ��ȡ������ַ
always@(negedge SCL or negedge incycle)begin
    if(!incycle)
        op_addr[bitcnt] <= op_addr[bitcnt];
    else if(adr_match && (bytecnt == 'd1) && bit_DATA)
        op_addr[bitcnt] <= SDA_r1;
end
// ��ȡд��������
always@(negedge SCL or negedge incycle)begin
    if(!incycle)
        write_data[bytecnt-2][bitcnt] <= write_data[bytecnt-2][bitcnt];
    else if(adr_match && bit_DATA && op_write)
        case (bytecnt)
            2,3,4,5: write_data[bytecnt-2][bitcnt] <= SDA_r1;
            default: write_data[bytecnt-2][bitcnt] <= write_data[bytecnt-2][bitcnt];
        endcase
end
// ���SDA��̬��ʹ��
always@(posedge sys_clk_i)begin
    case (bytecnt)
        0,1:
            if(bitcnt == 4'hf)                                      //MдSӦ��
                SDA_en <= 1;
            else
                SDA_en <= 0;
        2,3,4,5:
            case (bitcnt)
                7,6,5,4,3,2,1,0:
                    if(op_read)                                     //S��ӦMӦ��
                        SDA_en <= 1;
                    else
                        SDA_en <= 0;
                4'hf:
                    if(op_write)                                    //MдSӦ��
                        SDA_en <= 1;
                    else
                        SDA_en <= 0;
                default: SDA_en <= 0;                               //Ĭ�Ϲر���̬��
            endcase
        default: SDA_en <= 0;                                       //Ĭ�Ϲر���̬��
    endcase
end
// ���SDA,����Ӧ��Ͷ�����
always@(posedge sys_clk_i)begin
    case (bytecnt)
        0,1:
            if(bitcnt == 4'hf)                                      //MдSӦ��
                SDA_data <= 0;
            else
                SDA_data <= 1;
        2,3,4,5:
            case (bitcnt)
                7,6,5,4,3,2,1,0:                                    //S��ӦMӦ��
                    if(op_read)
                        SDA_data <= read_data[bytecnt-2][bitcnt[2:0]];
                    else
                        SDA_data <= 1;
                4'hf:                                               //MдSӦ��
                    if(op_write)
                        SDA_data <= 0;
                    else
                        SDA_data <= 1;
                default: SDA_data <= 1;                             //Ĭ������
            endcase
        default: SDA_data <= 1;                                     //Ĭ������
    endcase
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// ���
//---------------------------------------------------------------------
    wire                                i2c_wr_valid               ;
    wire                                i2c_rd_valid               ;

    reg                                 i2c_wr_valid_r1,i2c_wr_valid_r2,i2c_wr_valid_r3  ;
    reg                                 i2c_rd_valid_r1,i2c_rd_valid_r2,i2c_rd_valid_r3  ;

    assign                              i2c_wr_valid              = (bitcnt == 4'h7) && (bytecnt == 4'h6) && op_write && adr_match;
    assign                              i2c_rd_valid              = (bitcnt == 4'h7) && (bytecnt == 4'h2) && op_read && adr_match;

always@(posedge sys_clk_i)begin
    i2c_wr_valid_r1 <= i2c_wr_valid;
    i2c_wr_valid_r2 <= i2c_wr_valid_r1;
    i2c_wr_valid_r3 <= i2c_wr_valid_r2;

    i2c_rd_valid_r1 <= i2c_rd_valid;
    i2c_rd_valid_r2 <= i2c_rd_valid_r1;
    i2c_rd_valid_r3 <= i2c_rd_valid_r2;
end

    assign                              ram_wr_en_o               = i2c_wr_valid_r2 & ~i2c_wr_valid_r3;

    assign                              ram_rd_en_o               = i2c_rd_valid_r2 & ~i2c_rd_valid_r3;

    assign                              ram_wr_addr_o             = op_addr;

    assign                              ram_rd_addr_o             = op_addr;

    assign                              ram_wr_data_o             = {write_data[3],write_data[2],write_data[1],write_data[0]};

    assign                              {read_data[3],read_data[2],read_data[1],read_data[0]}= ram_rd_data_i;

endmodule