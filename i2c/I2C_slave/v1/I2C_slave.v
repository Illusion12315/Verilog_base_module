`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             I2C_slave
// Create Date:           2024/05/23 22:42:22
// Version:               V1.0
// PATH:                  E:\FPGA\module_base\i2c\I2C_slave\I2C_slave.v
// Descriptions:          
// 
// ********************************************************************************** // 

// Please define one of these before starting synthesis
`define Xilinx
//`define Altera

`timescale 1ns / 1ps

module I2C_slave #(
    // The 7-bits address that we want for our I2C slave
    parameter                           I2C_ADR                   = 7'h27 
) (
    input                               SCL                        ,
    inout                               SDA                        ,
    output             [   7: 0]        IOout                       
    );
// ********************************************************************************** // 
//---------------------------------------------------------------------
// I2C start and stop conditions detection logic
//---------------------------------------------------------------------
    wire                                SDA_shadow                 ;
    wire                                start_or_stop              ;// 检测开始和结束

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
// 开始后进入I2C有效状态
always @(negedge SCL or posedge start_or_stop)begin
    if(start_or_stop)
        incycle <= 1'b0;
    else if(~SDA)
        incycle <= 1'b1;
end
        
// Now we are ready to count the I2C bits coming in
// reg [3:0] bitcnt;  
// counts the I2C bits from 7 downto 0, plus an ACK bit
    reg                [   3: 0]        bitcnt                   =4'h0;//for simulation MBL
    wire                                bit_DATA                   ;
    wire                                bit_ACK                    ;
// 为高时,代表当前正在DATA计数
    assign                              bit_DATA                  = ~bitcnt[3];// the DATA bits are the first 8 bits sent
// 为高时,代表data计数完成
    assign                              bit_ACK                   = bitcnt[3];// the ACK bit is the 9th bit sent
// reg data_phase;
    reg                                 data_phase               =1'b0;//for simulation MBL
// bit计数器,由7->0(counts the I2C bits from 7 downto 0, plus an ACK bit)
always@(negedge SCL or negedge incycle)begin
    if(!incycle)
        bitcnt <= 4'h7;                                             // the bit 7 is received first
    else if(bit_ACK)
        bitcnt <= 4'h7;
    else
        bitcnt <= bitcnt - 4'h1;
end
// 第一个8bit数据后面都是数据阶段
always@(negedge SCL or negedge incycle)begin
    if(!incycle)
        data_phase <= 1'b0;
    else if(bit_ACK)
        data_phase <= 1'b1;
    else
        data_phase <= data_phase;
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// and detect if the I2C address matches our own
//---------------------------------------------------------------------
    wire                                adr_phase                  ;
// reg adr_match, op_read, got_ACK;
    reg                                 adr_match                =1'b0;
    reg                                 op_read                  =1'b0;
    reg                                 got_ACK                  =1'b0;//for simulation MBL
// reg SDA_r1;
    reg                                 SDA_r1                   =1'b0;//for simulation MBL

// reg [7:0] mem;           
    reg                [   7: 0]        mem                      =8'hFF;//for initial read access to slave and simulation MBL
    wire                                op_write                   ;
// 不是数据阶段就是器件地址阶段
    assign                              adr_phase                 = ~data_phase;
// 不是读操作就是写操作
    assign                              op_write                  = ~op_read;
// 打一拍
always @(posedge SCL)begin                                          // sample SDA on posedge since the I2C spec specifies as low as 0s hold-time on negedge
    SDA_r1 <= SDA;
end
// 得到应答位
always@(negedge SCL or negedge incycle)begin
    if(!incycle)
        got_ACK <= 'd0;
    else if(bit_ACK)
        got_ACK <= ~SDA_r1;                                         // we monitor the ACK to be able to free the bus when the master doesn't ACK during a read operation
end
// 读写位bit[0]为低代表当前为读操作
always@(negedge SCL or negedge incycle)begin
    if(!incycle)
        op_read <= 'd0;
    else if(adr_phase & bitcnt==0)
        op_read <= SDA_r1;
end
// 写操作时,若地址匹配,应答完成,数据阶段,将接受的数据写到mem中
always@(negedge SCL or negedge incycle)begin
    if(!incycle)
        mem[bitcnt] <= mem[bitcnt];
    else if(adr_match & bit_DATA & data_phase & op_write)
        mem[bitcnt] <= SDA_r1;
end
// 判断地址是否匹配
always@(negedge SCL or negedge incycle)begin
    if(!incycle)
        adr_match <= 'd1;
    else case (bitcnt)
        1,2,3,4,5,6,7:
            if(adr_phase & SDA_r1 != I2C_ADR[bitcnt-1])
                adr_match <= 1'b0;
        default: adr_match <= adr_match;
    endcase
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// drive the SDA line when necessary.
//---------------------------------------------------------------------
    wire                                mem_bit_low                ;
    wire                                SDA_assert_low             ;
    wire                                SDA_assert_ACK             ;
    wire                                SDA_low                    ;

    assign                              mem_bit_low               = ~mem[bitcnt[2:0]];
// 地址匹配,数据位,数据阶段,读操作,存储低bit,得到应答
    assign                              SDA_assert_low            = adr_match & bit_DATA & data_phase & op_read & mem_bit_low & got_ACK;
// 在地址阶段或写操作时,若地址匹配,应答完成,将SDA置0
    assign                              SDA_assert_ACK            = adr_match & bit_ACK & (adr_phase | op_write);
    assign                              SDA_low                   = SDA_assert_low | SDA_assert_ACK;
    assign                              SDA                       = SDA_low ? 1'b0 : 1'bz;
    
    assign                              IOout                     = mem;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// debug
//---------------------------------------------------------------------
    
endmodule
