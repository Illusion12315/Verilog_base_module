`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: chen xiongzhi
// 
// Create Date: 2023/10/08
// Design Name: 
// Module Name: spi_ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module spi_ctrl(
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,

    input                               spi_write_start_i          ,
    input                               spi_busy_i                 ,
    output reg                          spi_1byte_write_start_o    ,
    output reg         [  15:0]         ctrl_data_o                ,
    output reg         [   7:0]         write_data_o                
    );

reg                    [   1:0]         state                      ;
reg                    [   6:0]         cnt_write                  ;

    parameter                           IDLE = 'd0                 ;
    parameter                           WRITE = 'd1                ;
    parameter                           WRITE_CNT = 'd71           ;

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        state<='d0;
    else case(state)
        IDLE:
            if(spi_write_start_i)
                state<=WRITE;
            else
                state<=state;
        WRITE:
            if(cnt_write==WRITE_CNT&&~spi_busy_i)
                state<=IDLE;
            else
                state<=state;
        default:state<=IDLE;
    endcase
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
         spi_1byte_write_start_o<='d0;
    else if((state==WRITE)&&~spi_busy_i)
         spi_1byte_write_start_o<='d1;
    else
         spi_1byte_write_start_o<='d0;
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cnt_write<='d0;
    else if(state==IDLE)
        cnt_write<='d0;
    else if((state==WRITE)&& spi_1byte_write_start_o=='d1&&!spi_busy_i)
        cnt_write<=cnt_write+'d1;
    else
        cnt_write<=cnt_write;
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)begin
        ctrl_data_o<='d0;
        write_data_o<='d0;
    end
    else if (state==WRITE&&~spi_busy_i) begin
        case (cnt_write)
            'd0 : begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h000};  write_data_o = {8'h18}; end
            'd1 : begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h001};  write_data_o = {8'h00}; end
            'd2 : begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h002};  write_data_o = {8'h10}; end
            'd3 : begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h003};  write_data_o = {8'h43}; end
            'd4 : begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h004};  write_data_o = {8'h00}; end
            'd5 : begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h010};  write_data_o = {8'h7C}; end
            'd6 : begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h011};  write_data_o = {8'h01}; end
            'd7 : begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h012};  write_data_o = {8'h00}; end
            'd8 : begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h013};  write_data_o = {8'h08}; end
            'd9 : begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h014};  write_data_o = {8'h0C}; end
            'd10: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h015};  write_data_o = {8'h00}; end
            'd11: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h016};  write_data_o = {8'h05}; end
            'd12: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h017};  write_data_o = {8'h00}; end
            'd13: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h018};  write_data_o = {8'h07}; end
            'd14: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h019};  write_data_o = {8'h00}; end
            'd15: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h01A};  write_data_o = {8'h00}; end
            'd16: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h01B};  write_data_o = {8'h00}; end
            'd17: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h01C};  write_data_o = {8'h06}; end
            'd18: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h01D};  write_data_o = {8'h00}; end
            'd19: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h01E};  write_data_o = {8'h00}; end
            'd20: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h01F};  write_data_o = {8'h0E}; end
            'd21: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h0A0};  write_data_o = {8'h01}; end
            'd22: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h0A1};  write_data_o = {8'h00}; end
            'd23: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h0A2};  write_data_o = {8'h00}; end
            'd24: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h0A3};  write_data_o = {8'h01}; end
            'd25: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h0A4};  write_data_o = {8'h00}; end
            'd26: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h0A5};  write_data_o = {8'h00}; end
            'd27: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h0A6};  write_data_o = {8'h01}; end
            'd28: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h0A7};  write_data_o = {8'h00}; end
            'd29: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h0A8};  write_data_o = {8'h00}; end
            'd30: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h0A9};  write_data_o = {8'h01}; end
            'd31: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h0AA};  write_data_o = {8'h00}; end
            'd32: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h0AB};  write_data_o = {8'h00}; end
            'd33: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h0F0};  write_data_o = {8'h0A}; end
            'd34: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h0F1};  write_data_o = {8'h08}; end
            'd35: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h0F2};  write_data_o = {8'h0A}; end
            'd36: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h0F3};  write_data_o = {8'h0A}; end
            'd37: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h0F4};  write_data_o = {8'h08}; end
            'd38: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h0F5};  write_data_o = {8'h08}; end
            'd39: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h140};  write_data_o = {8'h42}; end
            'd40: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h141};  write_data_o = {8'h42}; end
            'd41: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h142};  write_data_o = {8'h43}; end
            'd42: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h143};  write_data_o = {8'h43}; end
            'd43: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h190};  write_data_o = {8'h00}; end
            'd44: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h191};  write_data_o = {8'h00}; end
            'd45: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h192};  write_data_o = {8'h00}; end
            'd46: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h193};  write_data_o = {8'h00}; end
            'd47: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h194};  write_data_o = {8'h00}; end
            'd48: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h195};  write_data_o = {8'h00}; end
            'd49: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h196};  write_data_o = {8'h11}; end
            'd50: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h197};  write_data_o = {8'h00}; end
            'd51: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h198};  write_data_o = {8'h00}; end
            'd52: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h199};  write_data_o = {8'h00}; end
            'd53: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h19A};  write_data_o = {8'h00}; end
            'd54: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h19B};  write_data_o = {8'h00}; end
            'd55: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h19C};  write_data_o = {8'h00}; end
            'd56: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h19D};  write_data_o = {8'h00}; end
            'd57: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h19E};  write_data_o = {8'h44}; end
            'd58: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h19F};  write_data_o = {8'h00}; end
            'd59: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h1A0};  write_data_o = {8'h33}; end
            'd60: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h1A1};  write_data_o = {8'h00}; end
            'd61: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h1A2};  write_data_o = {8'h00}; end
            'd62: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h1A3};  write_data_o = {8'h00}; end
            'd63: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h1E0};  write_data_o = {8'h03}; end
            'd64: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h1E1};  write_data_o = {8'h02}; end
            'd65: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h230};  write_data_o = {8'h00}; end
            'd66: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h231};  write_data_o = {8'h00}; end
            'd67: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h232};  write_data_o = {8'h00}; end
            //У׼
            'd68: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h018};  write_data_o = {8'h06}; end
            'd69: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h232};  write_data_o = {8'h01}; end
            'd70: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h018};  write_data_o = {8'h07}; end
            'd71: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h232};  write_data_o = {8'h01}; end
            default: begin ctrl_data_o = {1'b0,2'b00,3'b000,10'h000}; write_data_o = {8'h18}; end
        endcase
    end
end
endmodule