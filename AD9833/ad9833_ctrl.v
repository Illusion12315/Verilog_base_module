`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             ad9833_ctrl
// Create Date:           2024/07/20 18:29:48
// Version:               V1.0
// PATH:                  
// Descriptions:          
// 
// ********************************************************************************** // 
`default_nettype none


module ad9833_ctrl (
    input  wire                         sys_clk_i                  ,// clk100m
    input  wire                         rst_n_i                    ,

    input  wire                         start_cfg_pluse_i          ,

    output reg                          start_pluse_o              ,
    output reg         [  15: 0]        ad9833_cfg_data_o          ,// 3k hz . sin(x)

    output reg                          ad9833_cfg_done_o          ,
    input  wire                         ad9833_bus_busy_i           
);


    localparam                          S_IDLE                    = 0     ;
    localparam                          S_CONFIG                  = 1     ;

    localparam                          SEND_NUM                  = 3     ;

    localparam                          EXPECTED_FREQ             = 3_000 ;// output 3khz
    // localparam                          FREQREG                   = (1<<28) / 25_000_000 * EXPECTED_FREQ; 
    localparam                          FREQREG                   = 32_212;

    wire                                busy_neg                   ;
    wire               [  27: 0]        freq_reg                   ;

    reg                [   2: 0]        state                      ;
    reg                [   7: 0]        cfg_cnt                    ;

    reg                                 ad9833_bus_busy_r1         ;

    assign                              busy_neg                  = ~ad9833_bus_busy_i & ad9833_bus_busy_r1;

    assign                              freq_reg                  = FREQREG;

always@(posedge sys_clk_i)begin
    if(!rst_n_i)
        state <= S_IDLE;
    else case(state)
        S_IDLE:
            if(start_cfg_pluse_i)
                state <= S_CONFIG;
        S_CONFIG:
            if(busy_neg && cfg_cnt == SEND_NUM - 1)
                state <= S_IDLE;
        default:state <= S_IDLE;
    endcase
end

always@(posedge sys_clk_i)begin
    case(state)
        S_CONFIG:
            if(~ad9833_bus_busy_i && ~busy_neg)
                start_pluse_o <= 'd1;
            else
                start_pluse_o <= 'd0;
        default:start_pluse_o <= 'd0;
    endcase
end

always@(posedge sys_clk_i)begin
    case(state)
        S_CONFIG:
            if(busy_neg)
                cfg_cnt <= cfg_cnt + 'd1;
        default: cfg_cnt <= 'd0;
    endcase
end

always@(posedge sys_clk_i)begin
    case(state)
        S_CONFIG:
            case (cfg_cnt)
                // write control WORD
                // 28bit freq_word. FREQ0. External MCLK en. Sin wave. 
                0: ad9833_cfg_data_o <= {
                                            2'b00,                  // DB15, DB14
                                            1'b1,                   // B28
                                            1'b0,                   // HLB
                                            1'b0,                   // FSELECT
                                            1'b0,                   // PSELECT
                                            1'b0,                   // Reserved
                                            1'b0,                   // Reset
                                            1'b0,                   // SLEEP1
                                            1'b0,                   // SLEEP12
                                            1'b0,                   // OPBITEN
                                            1'b0,                   // Reserved
                                            1'b0,                   // DIV2
                                            1'b0,                   // Reserved
                                            1'b0,                   // Mode
                                            1'b0                    // Reserved
                                        };
                1: ad9833_cfg_data_o <= {2'b01,freq_reg[13:0]};     // reg0 LSB
                2: ad9833_cfg_data_o <= {2'b01,freq_reg[27:14]};    // reg0 MSB
                3: ad9833_cfg_data_o <= 'd3;
                4: ad9833_cfg_data_o <= 'd4;
                default: ad9833_cfg_data_o <= ad9833_cfg_data_o;
            endcase
        default: ad9833_cfg_data_o <= 'd0;
    endcase
end

always@(posedge sys_clk_i)begin
    if (busy_neg && cfg_cnt == SEND_NUM - 1)
        ad9833_cfg_done_o <= 'd1;
    else
        ad9833_cfg_done_o <= 'd0;
end

always@(posedge sys_clk_i)begin
    ad9833_bus_busy_r1 <= ad9833_bus_busy_i;
end

endmodule


`default_nettype wire