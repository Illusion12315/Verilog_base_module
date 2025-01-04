module instance();

//------------------------------Instantiated module: test_reg_map_cfg_U0 ------------------------------



wire          sys_clk_i           ;
wire          rst_n_i             ;

//Ram interface
wire          ram_wr_en_i         ;
wire [32-1:0] ram_wr_addr_i       ;
wire [32-1:0] ram_wr_data_i       ;
wire          ram_rd_en_i         ;
wire [32-1:0] ram_rd_addr_i       ;
reg  [32-1:0] ram_rd_data_o       ;

//reg map
wire [32-1:0] cxz                 ;//output tmplreg1 cxz [32-1:0]
wire          fld_wsrc_sgl        ;//input tmplreg2 fld_wsrc_sgl [ 1-1:0]
wire          fld_wsrc_sgl_clr    ;
wire          fld_wsrc_sgl_clr_val;
wire          fld_wsrc_sgl_set    ;
wire          fld_wsrc_sgl_set_val;
wire [ 3-1:0] fld_wsrc_bus        ;//input tmplreg2 fld_wsrc_bus [ 3-1:0]
wire          fld_wsrc_bus_clr    ;
wire [ 3-1:0] fld_wsrc_bus_clr_val;
wire          fld_wsrc_bus_set    ;
wire [ 3-1:0] fld_wsrc_bus_set_val;
wire          fld_wcrs_sgl        ;//input tmplreg2 fld_wcrs_sgl [ 1-1:0]
wire          fld_wcrs_sgl_set    ;
wire          fld_wcrs_sgl_set_val;
wire          fld_wcrs_sgl_clr    ;
wire          fld_wcrs_sgl_clr_val;
wire [27-1:0] fld_wcrs_bus        ;//input tmplreg2 fld_wcrs_bus [27-1:0]
wire          fld_wcrs_bus_set    ;
wire [27-1:0] fld_wcrs_bus_set_val;
wire          fld_wcrs_bus_clr    ;
wire [27-1:0] fld_wcrs_bus_clr_val;


test_reg_map_cfg test_reg_map_cfg_U0
(
.sys_clk_i                      ( sys_clk_i                      ),
.rst_n_i                        ( rst_n_i                        ),

//Ram interface
.ram_wr_en_i                    ( ram_wr_en_i                    ),
.ram_wr_addr_i                  ( ram_wr_addr_i                  ),
.ram_wr_data_i                  ( ram_wr_data_i                  ),
.ram_rd_en_i                    ( ram_rd_en_i                    ),
.ram_rd_addr_i                  ( ram_rd_addr_i                  ),
.ram_rd_data_o                  ( ram_rd_data_o                  ),

//reg map
.cxz                            ( cxz                            ),//output tmplreg1 cxz [32-1:0]
.fld_wsrc_sgl                   ( fld_wsrc_sgl                   ),//input tmplreg2 fld_wsrc_sgl [ 1-1:0]
.fld_wsrc_sgl_clr               ( fld_wsrc_sgl_clr               ),
.fld_wsrc_sgl_clr_val           ( fld_wsrc_sgl_clr_val           ),
.fld_wsrc_sgl_set               ( fld_wsrc_sgl_set               ),
.fld_wsrc_sgl_set_val           ( fld_wsrc_sgl_set_val           ),
.fld_wsrc_bus                   ( fld_wsrc_bus                   ),//input tmplreg2 fld_wsrc_bus [ 3-1:0]
.fld_wsrc_bus_clr               ( fld_wsrc_bus_clr               ),
.fld_wsrc_bus_clr_val           ( fld_wsrc_bus_clr_val           ),
.fld_wsrc_bus_set               ( fld_wsrc_bus_set               ),
.fld_wsrc_bus_set_val           ( fld_wsrc_bus_set_val           ),
.fld_wcrs_sgl                   ( fld_wcrs_sgl                   ),//input tmplreg2 fld_wcrs_sgl [ 1-1:0]
.fld_wcrs_sgl_set               ( fld_wcrs_sgl_set               ),
.fld_wcrs_sgl_set_val           ( fld_wcrs_sgl_set_val           ),
.fld_wcrs_sgl_clr               ( fld_wcrs_sgl_clr               ),
.fld_wcrs_sgl_clr_val           ( fld_wcrs_sgl_clr_val           ),
.fld_wcrs_bus                   ( fld_wcrs_bus                   ),//input tmplreg2 fld_wcrs_bus [27-1:0]
.fld_wcrs_bus_set               ( fld_wcrs_bus_set               ),
.fld_wcrs_bus_set_val           ( fld_wcrs_bus_set_val           ),
.fld_wcrs_bus_clr               ( fld_wcrs_bus_clr               ),
.fld_wcrs_bus_clr_val           ( fld_wcrs_bus_clr_val           )
);

endmodule

