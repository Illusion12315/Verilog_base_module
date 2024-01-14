//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: chen xiongzhi
// 
// Create Date: 2023/10/08
// Design Name: 
// Module Name: ad9516_spi_warpper
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

module ad9516_spi_warpper (
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,

    output                              CS                         ,
    output                              SCLK                       ,
    output                              SDIO                       ,
    input                               SDO                        ,

    output                              REFSEL                     ,
    output                              RESET_B                    ,

    input                               spi_write_start             //整个spi模块开始信号    
);

wire                                    spi_busy                   ;
wire                                    spi_1byte_write_start      ;
wire                   [  15:0]         ctrl_data                  ;
wire                   [   7:0]         write_data                 ;

wire                                    spi_write_start_flag       ;

assign RESET_B = rst_n_i ;
assign REFSEL = 'd0 ;

signle_pluse  signle_pluse_inst (
    .clk                               (sys_clk_i                 ),
    .signal_in                         (spi_write_start           ),
    .pluse_out                         (spi_write_start_flag      ) 
);

spi_ctrl  ad9516_spi_ctrl (
    .sys_clk_i                         (sys_clk_i                 ),
    .rst_n_i                           (rst_n_i                   ),

    .spi_write_start_i                 (spi_write_start_flag      ),
    .spi_busy_i                        (spi_busy                  ),
    .spi_1byte_write_start_o           (spi_1byte_write_start     ),
    .ctrl_data_o                       (ctrl_data                 ),
    .write_data_o                      (write_data                ) 
);

spi_logic  ad9516_spi_driver (
    .sys_clk_i                         (sys_clk_i                 ),
    .rst_n_i                           (rst_n_i                   ),

    .SCLK_O                            (SCLK                      ),//SPI时钟
    .CS_O                              (CS                        ),//SPI片选
    .MOSI_O                            (SDIO                      ),//SPI主发送，从接收
    .MISO_I                            (SDO                       ),//SPI从发送，主接收

    .start_flag_i                      (spi_1byte_write_start     ),//开始信号
    .control_data_i                    (ctrl_data                 ),//控制位寄存器值，16位
    .write_data_i                      (write_data                ),//寄存器值，8位
    .read_data_o                       (                          ),//读出的寄存器值，8位
    .spi_busy_o                        (spi_busy                  ) //系统繁忙信号    
);
endmodule

/*
//调用AD9516模块
ad9516_spi_warpper  ad9516_spi_warpper_inst (
    .sys_clk_i                         (sys_clk_i                 ),
    .rst_n_i                           (rst_n_i                   ),

    .CS                                (CS                        ),
    .SCLK                              (SCLK                      ),
    .SDIO                              (SDIO                      ),
    .SDO                               (SDO                       ),

    .REFSEL                            (REFSEL                    ),
    .RESET_B                           (RESET_B                   ),

    .spi_write_start                   (spi_write_start           ) 
);

//约束
###########################################################################
## AD9516
###########################################################################
set_property PACKAGE_PIN AU17 [get_ports SCLK]
set_property IOSTANDARD LVCMOS18 [get_ports SCLK]
set_property PACKAGE_PIN AR17 [get_ports SDIO]
set_property IOSTANDARD LVCMOS18 [get_ports SDIO]
set_property PACKAGE_PIN AM18 [get_ports SDO]
set_property IOSTANDARD LVCMOS18 [get_ports SDO]
set_property PACKAGE_PIN AT15 [get_ports CS]
set_property IOSTANDARD LVCMOS18 [get_ports CS]

set_property PACKAGE_PIN AP16 [get_ports RESET_B]
set_property IOSTANDARD LVCMOS18 [get_ports RESET_B]
set_property PACKAGE_PIN AT16 [get_ports REFSEL]
set_property IOSTANDARD LVCMOS18 [get_ports REFSEL]
*/