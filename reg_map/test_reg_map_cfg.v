
/*
* @Author       : Luma
* @Date         : 2022-08-16 08:39:00
* @LastEditTime : 2025-01-04 11:48:46
* @LastEditors  : Luma
* @Description  : test reg map cfg
* @FilePath     : e:\FPGA_code\Verilog_base_module\reg_map\test_reg_map_cfg.v
*/

module test_reg_map_cfg
(
    //System
    input               sys_clk_i            ,
    input               rst_n_i              ,

    //Ram interface
    input               ram_wr_en_i          ,
    input      [32-1:0] ram_wr_addr_i        ,
    input      [32-1:0] ram_wr_data_i        ,
    input               ram_rd_en_i          ,
    input      [32-1:0] ram_rd_addr_i        ,
    output reg [32-1:0] ram_rd_data_o        ,

    //reg map
    output     [32-1:0] cxz                  ,//output tmplreg1 cxz [32-1:0]
    input               fld_wsrc_sgl         ,//input tmplreg2 fld_wsrc_sgl [ 1-1:0]
    output              fld_wsrc_sgl_clr     ,
    output              fld_wsrc_sgl_clr_val ,
    output              fld_wsrc_sgl_set     ,
    output              fld_wsrc_sgl_set_val ,
    input      [ 3-1:0] fld_wsrc_bus         ,//input tmplreg2 fld_wsrc_bus [ 3-1:0]
    output              fld_wsrc_bus_clr     ,
    output     [ 3-1:0] fld_wsrc_bus_clr_val ,
    output              fld_wsrc_bus_set     ,
    output     [ 3-1:0] fld_wsrc_bus_set_val ,
    input               fld_wcrs_sgl         ,//input tmplreg2 fld_wcrs_sgl [ 1-1:0]
    output              fld_wcrs_sgl_set     ,
    output              fld_wcrs_sgl_set_val ,
    output              fld_wcrs_sgl_clr     ,
    output              fld_wcrs_sgl_clr_val ,
    input      [27-1:0] fld_wcrs_bus         ,//input tmplreg2 fld_wcrs_bus [27-1:0]
    output              fld_wcrs_bus_set     ,
    output     [27-1:0] fld_wcrs_bus_set_val ,
    output              fld_wcrs_bus_clr     ,
    output     [27-1:0] fld_wcrs_bus_clr_val ,
);

//----------------------------local parameter---------------------------------------------
localparam TMPLREG1 = 32'h4030 + 32'h0;
localparam TMPLREG2 = 32'h4030 + 32'h4;

//----------------------------local wire/reg declaration------------------------------------------

//tmplreg1
reg  [32-1:0] tmplreg1_reg;//wr
wire [32-1:0] tmplreg1    ;//rd

//tmplreg2
wire [32-1:0] tmplreg2    ;//rd

//----------------------------control logic---------------------------------------------
wire ram_wr_en   = ram_wr_en_i                                   ;
wire ram_rd_en   = ram_rd_en_i                                   ;

//tmplreg1
wire tmplreg1_wr = ( ram_wr_addr_i == TMPLREG1 ) && ram_wr_en    ;

//tmplreg2
wire tmplreg2_rd = ( ram_wr_addr_i == TMPLREG2 ) && ram_rd_en    ;
wire tmplreg2_wr = ( ram_wr_addr_i == TMPLREG2 ) && ram_wr_en    ;

//--------------------------------processing------------------------------------------------

//tmplreg1
assign cxz                     = tmplreg1_reg[31:0] ;
assign tmplreg1[31:0]          = cxz                ;
always @ ( posedge sys_clk_i )
begin
    if( ~rst_n_i )
        tmplreg1_reg <= 'h0;
    else if( tmplreg1_wr )
        tmplreg1_reg <= ram_wr_data_i;
end


//tmplreg2
assign tmplreg2[31]                = fld_wsrc_sgl;
assign fld_wsrc_sgl_clr            = tmplreg2_rd ;
assign fld_wsrc_sgl_clr_val        = 1'h0        ;
assign fld_wsrc_sgl_set            = tmplreg2_wr ;
assign fld_wsrc_sgl_set_val        = 1'h1        ;
assign tmplreg2[30:28]             = fld_wsrc_bus;
assign fld_wsrc_bus_clr            = tmplreg2_rd ;
assign fld_wsrc_bus_clr_val        = 3'h0        ;
assign fld_wsrc_bus_set            = tmplreg2_wr ;
assign fld_wsrc_bus_set_val        = 3'h7        ;
assign tmplreg2[27]                = fld_wcrs_sgl;
assign fld_wcrs_sgl_set            = tmplreg2_rd ;
assign fld_wcrs_sgl_set_val        = 1'h1        ;
assign fld_wcrs_sgl_clr            = tmplreg2_wr ;
assign fld_wcrs_sgl_clr_val        = 1'h0        ;
assign tmplreg2[26:0]              = fld_wcrs_bus;
assign fld_wcrs_bus_set            = tmplreg2_rd ;
assign fld_wcrs_bus_set_val        = 27'h7ffffff ;
assign fld_wcrs_bus_clr            = tmplreg2_wr ;
assign fld_wcrs_bus_clr_val        = 27'h0       ;

//reg map read
always @ ( * )
begin
    case( ram_rd_addr_i )
        TMPLREG1:
            ram_rd_data_o <= tmplreg1;
        TMPLREG2:
            ram_rd_data_o <= tmplreg2;
        default:
            ram_rd_data_o <= 'h5555_AAAA;
    endcase
end


endmodule
