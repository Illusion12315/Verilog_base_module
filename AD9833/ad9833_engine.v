`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             ad9833_engine
// Create Date:           2024/07/20 18:29:48
// Version:               V1.0
// PATH:                  
// Descriptions:          
// 
// ********************************************************************************** // 
`default_nettype none


module ad9833_engine (
    input  wire                         sys_clk_i                  ,// clk100m
    input  wire                         rst_n_i                    ,

    input  wire                         start_pluse_i              ,

    input  wire        [  15: 0]        ad9833_cfg_data_i          ,// 3k hz . sin(x)

    output reg                          SCLK                       ,// max clk40m
    output reg                          FSYNC                      ,
    output reg                          SDATA                      ,

    output wire                         ad9833_bus_busy_o           
);

    localparam                          S_IDLE                    = 0     ;
    localparam                          S_FSYNC                   = 1     ;
    localparam                          S_OPERATE                 = 2     ;

    reg                [   1: 0]        state                      ;

    reg                [   1: 0]        clk_cnt                    ;
    reg                [   3: 0]        data_cnt                   ;

    assign                              ad9833_bus_busy_o         = ~(state == S_IDLE);

always@(posedge sys_clk_i)begin
    if (!rst_n_i)
        state <= S_IDLE;
    else case (state)
        S_IDLE:
            if(start_pluse_i)
                state <= S_FSYNC;
        S_FSYNC:
            if(clk_cnt == 'd3)
                state <= S_OPERATE;
        S_OPERATE:
            if(clk_cnt == 'd2 && data_cnt == 'd15)
                state <= S_IDLE;
        default:state <= S_IDLE;
    endcase
end

always@(posedge sys_clk_i)begin
    case (state)
        S_FSYNC: clk_cnt <= clk_cnt + 'd1;
        S_OPERATE: clk_cnt <= clk_cnt + 'd1;
        default: clk_cnt <= 'd0;
    endcase
end

always@(posedge sys_clk_i)begin
    case (state)
        S_OPERATE:
            if(clk_cnt == 'd3)
                data_cnt <= data_cnt + 'd1;
        default: data_cnt <= 'd0;
    endcase
end

always@(posedge sys_clk_i)begin
    case (state)
        S_FSYNC: SCLK <= 'd1;
        S_OPERATE:
            case (clk_cnt)
                0: SCLK <= 'd1;
                1: SCLK <= 'd1;
                2: SCLK <= 'd0;
                3: SCLK <= 'd0;
                default: SCLK <= 'd1;
            endcase
        default: SCLK <= 'd0;
    endcase
end

always@(posedge sys_clk_i)begin
    case (state)
        S_FSYNC:
            case (clk_cnt)
                2,3: FSYNC <= 'd0;
                default: FSYNC <= 'd1;
            endcase
        S_OPERATE: FSYNC <= 'd0;
        default: FSYNC <= 'd1;
    endcase
end

always@(posedge sys_clk_i)begin
    case (state)
        S_OPERATE: SDATA <= ad9833_cfg_data_i[15-data_cnt];
        default: SDATA <= 'd1;
    endcase
end
endmodule


`default_nettype wire