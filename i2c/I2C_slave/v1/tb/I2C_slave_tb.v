`timescale 1ns/1ps


module I2C_slave_tb;

  // Parameters
    localparam                          I2C_ADR                   = 7'h41 ;

  //Ports
    // reg                                 SCL                        ;
    wire                                SDA                        ;
    wire               [   7: 0]        IOout                      ;
    reg                                 sys_clk_i                  ;
    reg                                 rst_n_i                    ;
    reg                [   7: 0]        word_addr_i                ;
    reg                                 wr_start_flag_i            ;
    reg                [   7: 0]        wr_data_i                  ;
    reg                                 rd_start_flag_i            ;
    wire               [   7: 0]        rd_data_o                  ;
    wire                                scl_o                      ;
    wire                                sda_i                      ;
    wire                                sda_out_o                  ;
    wire                                sda_en_o                   ;

    wire                                i2c_busy_o                 ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// initial
//---------------------------------------------------------------------
initial begin
    sys_clk_i = 0;
    rst_n_i = 0 ;
    wr_start_flag_i = 0;
    word_addr_i = 0;
    wr_data_i = 0;
    rd_start_flag_i = 0;
    #100
    rst_n_i = 1 ;
    #100
    test_wr1byte(8'h0f,8'hf0);
    // test_rd1byte(8'h0f);
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// DUT
//---------------------------------------------------------------------
  I2C_slave # (
    .I2C_ADR                            (I2C_ADR                   ) 
  )
  I2C_slave_inst (
    .SCL                                (scl_o                     ),
    .SDA                                (SDA                       ),
    .IOout                              (IOout                     ) 
  );

hei_inout hei_inout_inst(
    .sda                                (SDA                       ),

    .sda_o                              (sda_i                     ),
    .sda_out_i                          (sda_out_o                 ),
    .sda_en_i                           (sda_en_o                  ) 
);

always #5  sys_clk_i = ! sys_clk_i ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// 
//---------------------------------------------------------------------
iic_1byte_wr_or_rd # (
    .SOLID_ADDR                         (I2C_ADR[6:3]              ) 
  )
  iic_1byte_wr_or_rd_inst (
    .sys_clk_i                          (sys_clk_i                 ),
    .rst_n_i                            (rst_n_i                   ),
    .device_addr_i                      (I2C_ADR[2:0]              ),
    .word_addr_i                        (word_addr_i               ),
    .wr_start_flag_i                    (wr_start_flag_i           ),
    .wr_data_i                          (wr_data_i                 ),
    .rd_start_flag_i                    (rd_start_flag_i           ),
    .rd_data_o                          (rd_data_o                 ),
    .i2c_busy_o                         (i2c_busy_o                ),
    .scl_o                              (scl_o                     ),
    .sda_i                              (sda_i                     ),
    .sda_out_o                          (sda_out_o                 ),
    .sda_en_o                           (sda_en_o                  ) 
  );
// ********************************************************************************** // 
//---------------------------------------------------------------------
// task
//---------------------------------------------------------------------
task test_wr1byte;
    input              [   7: 0]        word_addr                  ;
    input              [   7: 0]        wr_data                    ;
    begin
        rd_start_flag_i = 0;
        wr_start_flag_i = 0;
        #50
        word_addr_i = word_addr;
        wr_data_i = wr_data;
        wr_start_flag_i = 1;
    end
endtask

task test_rd1byte;
    input              [   7: 0]        word_addr                  ;
    begin
        rd_start_flag_i = 0;
        wr_start_flag_i = 0;
        #50
        word_addr_i = word_addr;
        rd_start_flag_i = 1;
    end
endtask

endmodule

`timescale 1ns / 1ps
//****************************************VSCODE PLUG-IN**********************************//
//----------------------------------------------------------------------------------------
// IDE :                   VSCODE     
// VSCODE plug-in version: Verilog-Hdl-Format-2.4.20240526
// VSCODE plug-in author : Jiang Percy
//----------------------------------------------------------------------------------------
//****************************************Copyright (c)***********************************//
// Copyright(C)            Please Write Company name
// All rights reserved     
// File name:              
// Last modified Date:     2024/05/27 09:23:14
// Last Version:           V1.0
// Descriptions:           
//----------------------------------------------------------------------------------------
// Created by:             Please Write You Name 
// Created date:           2024/05/27 09:23:14
// mail      :             Please Write mail 
// Version:                V1.0
// TEXT NAME:              I2C_slave_tb.v
// PATH:                   G:\FPGA\Verilog_base_module\i2c\I2C_slave\tb\I2C_slave_tb.v
// Descriptions:           
//                         
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module hei_inout(
    inout                               sda                        ,

    output                              sda_o                      ,
    input                               sda_out_i                  ,
    input                               sda_en_i                    
);
    assign                              sda                       = (sda_en_i)?sda_out_i:'hz;
    assign                              sda_o                     = sda;
endmodule