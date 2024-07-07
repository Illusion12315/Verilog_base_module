`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             i2c_regs_space
// Create Date:           2024/06/14 15:37:02
// Version:               V1.0
// PATH:                  C:\Users\Administrator\Desktop\project\module base\i2c\I2C_for_sim\I2C_for_sim.srcs\sources_1\i2c_regs_space.v
// Descriptions:          
// 
// ********************************************************************************** // 
// `default_nettype none


module i2c_regs_space #(
    parameter                           I2C_ADR                   = 7'h27 ,
    parameter                           I2C_REG_NUM               = 48    
) (
    input  wire                         sys_clk_i                  ,
    input  wire                         hw_reset_n_i               ,// hardware reset_b

    input  wire                         acq_en_i                   ,
    input  wire                         pcie_link_up               ,
    input  wire                         ddr_link_up                ,
    input  wire                         srio_link_up               ,

    output wire                         sw_areset_o                ,// software reset, drive clk: sys_clk_i
    output wire                         sim_en_o                   ,

    input  wire                         SCL                        ,// assign to top
    inout  wire                         SDA                         // assign to top
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// declarations
//---------------------------------------------------------------------
    wire                                ram_wr_en                  ;
    wire               [   7: 0]        ram_wr_addr                ;
    wire               [  31: 0]        ram_wr_data                ;

    wire                                ram_rd_en                  ;
    wire               [   7: 0]        ram_rd_addr                ;
    reg                [  31: 0]        ram_rd_data              ='d0;
    
    reg                [  31: 0]        i2c_wr_regs      [0:I2C_REG_NUM-1]  ;
    reg                [  31: 0]        i2c_rd_regs      [0:I2C_REG_NUM-1]  ;

    integer                             i                          ;

    reg                                 pcie_link_up_r1='d0,pcie_link_up_r2='d0  ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// I/O Connections assignments
//---------------------------------------------------------------------
always@(posedge sys_clk_i)begin
    pcie_link_up_r1 <= pcie_link_up;
    pcie_link_up_r2 <= pcie_link_up_r1;
end

// for simulation
initial begin
    for (i = 0; i<I2C_REG_NUM; i=i+1) begin
        i2c_rd_regs[i] = 32'd0;
        i2c_wr_regs[i] = 32'd0;
    end
end
// assign a value to wr regs
generate
    begin : reg_ctrl
        genvar  i;
        for(i = 0; i <= I2C_REG_NUM - 1; i = i + 1)
            begin : num
                always@(posedge sys_clk_i)
                    begin
                        if(ram_wr_en && (ram_wr_addr == i))begin
                            i2c_wr_regs[i] <=  ram_wr_data;
                        end
                        else begin
                            i2c_wr_regs[i] <=  i2c_wr_regs[i];
                        end
                    end
            end
    end
endgenerate
// assign a value to rd regs
always@(posedge sys_clk_i)begin
    if(ram_rd_addr < I2C_REG_NUM)
        case (ram_rd_addr)
            // u should declare which are the rd regs.
            8'h01: ram_rd_data <= i2c_rd_regs[1];





            default: ram_rd_data <= i2c_wr_regs[ram_rd_addr];
        endcase
    else
        ram_rd_data <= 32'hAAAA_5555;
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// reg space
//---------------------------------------------------------------------
// 0x00(address)
    assign                              sw_areset_o               = ~ i2c_wr_regs[0][0];
    assign                              sim_en_o                  = i2c_wr_regs[0][1];
// 0x01(address)
always@(posedge sys_clk_i)begin
    i2c_rd_regs[1][0] <= acq_en_i;
end
// 0x02(address)
// 0x03(address)
// 0x04(address)
always@(posedge sys_clk_i)begin
    i2c_rd_regs[4][0] <= pcie_link_up_r2;
    i2c_rd_regs[4][1] <= ddr_link_up;
end
// 0x05(address)
always@(posedge sys_clk_i)begin
    i2c_rd_regs[5][0] <= srio_link_up;
end
// 0x06(address)
// 0x07(address)
// 0x08(address)
// 0x09(address)
// 0x0a(address)
// 0x0b(address)
// 0x0c(address)
// 0x0d(address)
// 0x0e(address)
// 0x0f(address)
// 0x10(address)
// 0x11(address)
// 0x12(address)
// 0x13(address)
// 0x14(address)
// 0x15(address)
// 0x16(address)
// 0x17(address)
// 0x18(address)
// 0x19(address)
// 0x1a(address)
// 0x1b(address)
// 0x1c(address)
// 0x1d(address)
// 0x1e(address)
// 0x1f(address)
// 0x20(address)
// 0x21(address)
// 0x22(address)
// 0x23(address)
// 0x24(address)
// 0x25(address)
// 0x26(address)
// 0x27(address)
// 0x28(address)
// 0x29(address)
// 0x2a(address)
// 0x2b(address)
// 0x2c(address)
// 0x2d(address)
// 0x2e(address)
// 0x2f(address)



// ********************************************************************************** // 
//---------------------------------------------------------------------
// i2c driver
//---------------------------------------------------------------------
I2C_slave_sysclk_4B # (
    .I2C_ADR                            (I2C_ADR                   ) 
)
I2C_slave_sysclk_4B_inst (
    .sys_clk_i                          (sys_clk_i                 ),
    .rst_n_i                            (hw_reset_n_i              ),

    .ram_wr_en_o                        (ram_wr_en                 ),
    .ram_wr_addr_o                      (ram_wr_addr               ),
    .ram_wr_data_o                      (ram_wr_data               ),

    .ram_rd_en_o                        (ram_rd_en                 ),
    .ram_rd_addr_o                      (ram_rd_addr               ),
    .ram_rd_data_i                      (ram_rd_data               ),

    .SCL                                (SCL                       ),
    .SDA                                (SDA                       ) 
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// debug
//---------------------------------------------------------------------





endmodule