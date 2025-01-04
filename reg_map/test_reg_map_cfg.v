
/*
* @Author       : Luma
* @Date         : 2022-08-16 08:39:00
* @LastEditTime : 2025-01-04 13:41:28
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
    output     [32-1:0] cxz                  ,//output tmplreg000 cxz [32-1:0]
    input               fld_wsrc_sgl         ,//input tmplreg001 fld_wsrc_sgl [ 1-1:0]
    output              fld_wsrc_sgl_clr     ,
    output              fld_wsrc_sgl_clr_val ,
    output              fld_wsrc_sgl_set     ,
    output              fld_wsrc_sgl_set_val ,
    input      [ 3-1:0] fld_wsrc_bus         ,//input tmplreg001 fld_wsrc_bus [ 3-1:0]
    output              fld_wsrc_bus_clr     ,
    output     [ 3-1:0] fld_wsrc_bus_clr_val ,
    output              fld_wsrc_bus_set     ,
    output     [ 3-1:0] fld_wsrc_bus_set_val ,
    input               fld_wcrs_sgl         ,//input tmplreg001 fld_wcrs_sgl [ 1-1:0]
    output              fld_wcrs_sgl_set     ,
    output              fld_wcrs_sgl_set_val ,
    output              fld_wcrs_sgl_clr     ,
    output              fld_wcrs_sgl_clr_val ,
    input      [27-1:0] fld_wcrs_bus         ,//input tmplreg001 fld_wcrs_bus [27-1:0]
    output              fld_wcrs_bus_set     ,
    output     [27-1:0] fld_wcrs_bus_set_val ,
    output              fld_wcrs_bus_clr     ,
    output     [27-1:0] fld_wcrs_bus_clr_val ,
    output     [32-1:0] cxz1                 ,//output tmplreg002 cxz1 [32-1:0]
    input               fld_wsrc_sgl1        ,//input tmplreg003 fld_wsrc_sgl1 [ 1-1:0]
    output              fld_wsrc_sgl1_clr    ,
    output              fld_wsrc_sgl1_clr_val,
    output              fld_wsrc_sgl1_set    ,
    output              fld_wsrc_sgl1_set_val,
    input      [ 3-1:0] fld_wsrc_bus1        ,//input tmplreg003 fld_wsrc_bus1 [ 3-1:0]
    output              fld_wsrc_bus1_clr    ,
    output     [ 3-1:0] fld_wsrc_bus1_clr_val,
    output              fld_wsrc_bus1_set    ,
    output     [ 3-1:0] fld_wsrc_bus1_set_val,
    input               fld_wcrs_sgl1        ,//input tmplreg003 fld_wcrs_sgl1 [ 1-1:0]
    output              fld_wcrs_sgl1_set    ,
    output              fld_wcrs_sgl1_set_val,
    output              fld_wcrs_sgl1_clr    ,
    output              fld_wcrs_sgl1_clr_val,
    input      [27-1:0] fld_wcrs_bus1        ,//input tmplreg003 fld_wcrs_bus1 [27-1:0]
    output              fld_wcrs_bus1_set    ,
    output     [27-1:0] fld_wcrs_bus1_set_val,
    output              fld_wcrs_bus1_clr    ,
    output     [27-1:0] fld_wcrs_bus1_clr_val,
);

//----------------------------local parameter---------------------------------------------
localparam TMPLREG000 = 32'h0 + 32'h0;
localparam TMPLREG001 = 32'h0 + 32'h4;
localparam TMPLREG002 = 32'h0 + 32'h8;
localparam TMPLREG003 = 32'h0 + 32'hc;

//----------------------------local wire/reg declaration------------------------------------------

//tmplreg000
reg  [32-1:0] tmplreg000_reg;//wr
wire [32-1:0] tmplreg000    ;//rd

//tmplreg001
wire [32-1:0] tmplreg001    ;//rd

//tmplreg002
reg  [32-1:0] tmplreg002_reg;//wr
wire [32-1:0] tmplreg002    ;//rd

//tmplreg003
wire [32-1:0] tmplreg003    ;//rd

//----------------------------control logic---------------------------------------------
wire ram_wr_en     = ram_wr_en_i                                   ;
wire ram_rd_en     = ram_rd_en_i                                   ;

//tmplreg000
wire tmplreg000_wr = ( ram_wr_addr_i == TMPLREG000 ) && ram_wr_en  ;

//tmplreg001
wire tmplreg001_rd = ( ram_wr_addr_i == TMPLREG001 ) && ram_rd_en  ;
wire tmplreg001_wr = ( ram_wr_addr_i == TMPLREG001 ) && ram_wr_en  ;

//tmplreg002
wire tmplreg002_wr = ( ram_wr_addr_i == TMPLREG002 ) && ram_wr_en  ;

//tmplreg003
wire tmplreg003_rd = ( ram_wr_addr_i == TMPLREG003 ) && ram_rd_en  ;
wire tmplreg003_wr = ( ram_wr_addr_i == TMPLREG003 ) && ram_wr_en  ;

//--------------------------------processing------------------------------------------------

//tmplreg000
assign cxz                       = tmplreg000_reg[31:0] ;
assign tmplreg000[31:0]          = cxz                  ;
always @ ( posedge sys_clk_i )
begin
    if( ~rst_n_i )
        tmplreg000_reg <= 'h0;
    else if( tmplreg000_wr )
        tmplreg000_reg <= ram_wr_data_i;
end


//tmplreg001
assign tmplreg001[31]              = fld_wsrc_sgl;
assign fld_wsrc_sgl_clr            = tmplreg001_rd;
assign fld_wsrc_sgl_clr_val        = 1'h0        ;
assign fld_wsrc_sgl_set            = tmplreg001_wr;
assign fld_wsrc_sgl_set_val        = 1'h1        ;
assign tmplreg001[30:28]           = fld_wsrc_bus;
assign fld_wsrc_bus_clr            = tmplreg001_rd;
assign fld_wsrc_bus_clr_val        = 3'h0        ;
assign fld_wsrc_bus_set            = tmplreg001_wr;
assign fld_wsrc_bus_set_val        = 3'h7        ;
assign tmplreg001[27]              = fld_wcrs_sgl;
assign fld_wcrs_sgl_set            = tmplreg001_rd;
assign fld_wcrs_sgl_set_val        = 1'h1        ;
assign fld_wcrs_sgl_clr            = tmplreg001_wr;
assign fld_wcrs_sgl_clr_val        = 1'h0        ;
assign tmplreg001[26:0]            = fld_wcrs_bus;
assign fld_wcrs_bus_set            = tmplreg001_rd;
assign fld_wcrs_bus_set_val        = 27'h7ffffff ;
assign fld_wcrs_bus_clr            = tmplreg001_wr;
assign fld_wcrs_bus_clr_val        = 27'h0       ;

//tmplreg002
assign cxz1                      = tmplreg002_reg[31:0] ;
assign tmplreg002[31:0]          = cxz1                 ;
always @ ( posedge sys_clk_i )
begin
    if( ~rst_n_i )
        tmplreg002_reg <= 'h0;
    else if( tmplreg002_wr )
        tmplreg002_reg <= ram_wr_data_i;
end


//tmplreg003
assign tmplreg003[31]               = fld_wsrc_sgl1;
assign fld_wsrc_sgl1_clr            = tmplreg003_rd;
assign fld_wsrc_sgl1_clr_val        = 1'h0         ;
assign fld_wsrc_sgl1_set            = tmplreg003_wr;
assign fld_wsrc_sgl1_set_val        = 1'h1         ;
assign tmplreg003[30:28]            = fld_wsrc_bus1;
assign fld_wsrc_bus1_clr            = tmplreg003_rd;
assign fld_wsrc_bus1_clr_val        = 3'h0         ;
assign fld_wsrc_bus1_set            = tmplreg003_wr;
assign fld_wsrc_bus1_set_val        = 3'h7         ;
assign tmplreg003[27]               = fld_wcrs_sgl1;
assign fld_wcrs_sgl1_set            = tmplreg003_rd;
assign fld_wcrs_sgl1_set_val        = 1'h1         ;
assign fld_wcrs_sgl1_clr            = tmplreg003_wr;
assign fld_wcrs_sgl1_clr_val        = 1'h0         ;
assign tmplreg003[26:0]             = fld_wcrs_bus1;
assign fld_wcrs_bus1_set            = tmplreg003_rd;
assign fld_wcrs_bus1_set_val        = 27'h7ffffff  ;
assign fld_wcrs_bus1_clr            = tmplreg003_wr;
assign fld_wcrs_bus1_clr_val        = 27'h0        ;

//reg map read
always @ ( * )
begin
    case( ram_rd_addr_i )
        TMPLREG000:
            ram_rd_data_o <= tmplreg000;
        TMPLREG001:
            ram_rd_data_o <= tmplreg001;
        TMPLREG002:
            ram_rd_data_o <= tmplreg002;
        TMPLREG003:
            ram_rd_data_o <= tmplreg003;
        default:
            ram_rd_data_o <= 'h5555_AAAA;
    endcase
end


endmodule
