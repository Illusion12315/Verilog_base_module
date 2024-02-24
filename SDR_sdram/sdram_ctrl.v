
module sdram_ctrl (
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,

    input                               sdram_wr_req_i             ,// ask for write
    input              [  23:0]         sdram_wr_addr_i            ,// wr addr, it can be refreshed when ack is high.
    input              [  15:0]         sdram_wr_data_i            ,// wr data, it can be refreshed when ack is hign.
    input              [   9:0]         sdram_wr_length_i          ,
    output                              sdram_wr_ack_o             ,// ack signal.

    input                               sdram_rd_req_i             ,// ask for read
    input              [  23:0]         sdram_rd_addr_i            ,// rd addr, it can be refreshed when ack is high.
    output             [  15:0]         sdram_rd_data_o            ,// rd data, it can be refreshed when ack is hign.
    input              [   9:0]         sdram_rd_length_i          ,
    output                              sdram_rd_ack_o             ,// ack signal.

    output                              sdram_init_end_o           ,
    // sdram ctrl interface
    output             [   1:0]         sdram_ba_o                 ,
    output             [  12:0]         sdram_addr_o               ,
    inout              [  15:0]         sdram_dq_io                ,
    output                              sdram_cke_o                ,
    output                              sdram_cs_n_o               ,
    output                              sdram_ras_n_o              ,
    output                              sdram_cas_n_o              ,
    output                              sdram_we_n_o                
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// wires
//---------------------------------------------------------------------
wire                                    init_end                   ;

wire                   [   3:0]         init_cmd                   ;
wire                   [   1:0]         init_ba                    ;
wire                   [  12:0]         init_addr                  ;

wire                   [   3:0]         auto_refresh_cmd           ;
wire                   [   1:0]         auto_refresh_ba            ;
wire                   [  12:0]         auto_refresh_addr          ;

wire                   [   3:0]         write_cmd                  ;
wire                   [   1:0]         write_ba                   ;
wire                   [  12:0]         write_addr                 ;

wire                   [   3:0]         read_cmd                   ;
wire                   [   1:0]         read_ba                    ;
wire                   [  12:0]         read_addr                  ;

wire                                    auto_refresh_en            ;
wire                                    auto_refresh_req           ;
wire                                    auto_refresh_end           ;

wire                                    wr_en                      ;
wire                                    wr_end                     ;
wire                                    wr_sdram_en                ;
wire                   [  15:0]         wr_sdram_data              ;

wire                                    rd_en                      ;
wire                                    rd_end                     ;
wire                   [  15:0]         rd_data                    ;

wire                                    sdram_dq_en_o              ;
wire                   [  15:0]         sdram_dq_o                 ;
wire                   [  15:0]         sdram_dq_i                 ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// assign
//---------------------------------------------------------------------
assign sdram_init_end_o = init_end;
assign sdram_dq_i = sdram_dq_io;
assign sdram_dq_io = (sdram_dq_en_o)? sdram_dq_o:16'hz;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// init
//---------------------------------------------------------------------
sdram_init  sdram_init_inst (
    .sys_clk_i                         (sys_clk_i                 ),
    .rst_n_i                           (rst_n_i                   ),

    .init_cmd_o                        (init_cmd                  ),
    .init_ba_o                         (init_ba                   ),
    .init_addr_o                       (init_addr                 ),

    .init_end_o                        (init_end                  ) 
  );
// ********************************************************************************** // 
//---------------------------------------------------------------------
// auto refresh
//---------------------------------------------------------------------
sdram_auto_refresh  sdram_auto_refresh_inst (
    .sys_clk_i                         (sys_clk_i                 ),
    .rst_n_i                           (rst_n_i                   ),

    .init_end_i                        (init_end                  ),

    .auto_refresh_en_i                 (auto_refresh_en           ),
    .auto_refresh_req_o                (auto_refresh_req          ),
    .auto_refresh_end_o                (auto_refresh_end          ),

    .auto_refresh_cmd_o                (auto_refresh_cmd          ),
    .auto_refresh_ba_o                 (auto_refresh_ba           ),
    .auto_refresh_addr_o               (auto_refresh_addr         ) 
  );
// ********************************************************************************** // 
//---------------------------------------------------------------------
// write
//---------------------------------------------------------------------
sdram_write  sdram_write_inst (
    .sys_clk_i                         (sys_clk_i                 ),
    .rst_n_i                           (rst_n_i                   ),

    .init_end_i                        (init_end                  ),

    .wr_en_i                           (wr_en                     ),
    .wr_addr_i                         (sdram_wr_addr_i           ),
    .wr_data_i                         (sdram_wr_data_i           ),
    .wr_burst_lenth_i                  (sdram_wr_length_i         ),
    .wr_ack_o                          (sdram_wr_ack_o            ),
    .wr_end_o                          (wr_end                    ),

    .write_cmd_o                       (write_cmd                 ),
    .write_ba_o                        (write_ba                  ),
    .write_addr_o                      (write_addr                ),

    .wr_sdram_en_o                     (wr_sdram_en               ),
    .wr_sdram_data_o                   (wr_sdram_data             ) 
  );
// ********************************************************************************** // 
//---------------------------------------------------------------------
// read
//---------------------------------------------------------------------
sdram_read  sdram_read_inst (
    .sys_clk_i                         (sys_clk_i                 ),
    .rst_n_i                           (rst_n_i                   ),

    .init_end_i                        (init_end                  ),

    .rd_en_i                           (rd_en                     ),
    .rd_addr_i                         (sdram_rd_addr_i           ),
    .rd_data_i                         (rd_data                   ),
    .rd_burst_lenth_i                  (sdram_rd_length_i         ),
    .rd_ack_o                          (sdram_rd_ack_o            ),
    .rd_end_o                          (rd_end                    ),

    .read_cmd_o                        (read_cmd                  ),
    .read_ba_o                         (read_ba                   ),
    .read_addr_o                       (read_addr                 ),

    .rd_sdram_data_o                   (sdram_rd_data_o           ) 
  );
// ********************************************************************************** // 
//---------------------------------------------------------------------
// arbit
//---------------------------------------------------------------------
  sdram_arbit  sdram_arbit_inst (
    .sys_clk_i                         (sys_clk_i                 ),
    .rst_n_i                           (rst_n_i                   ),
    // assign with init
    .init_cmd_i                        (init_cmd                  ),
    .init_ba_i                         (init_ba                   ),
    .init_addr_i                       (init_addr                 ),
    .init_end_i                        (init_end                  ),
    // assign with auto refresh
    .auto_refresh_req_i                (auto_refresh_req          ),
    .auto_refresh_end_i                (auto_refresh_end          ),
    .auto_refresh_cmd_i                (auto_refresh_cmd          ),
    .auto_refresh_ba_i                 (auto_refresh_ba           ),
    .auto_refresh_addr_i               (auto_refresh_addr         ),
    .auto_refresh_en_o                 (auto_refresh_en           ),
    // assign with write
    .wr_req_i                          (sdram_wr_req_i            ),
    .write_cmd_i                       (write_cmd                 ),
    .write_ba_i                        (write_ba                  ),
    .write_addr_i                      (write_addr                ),
    .wr_en_o                           (wr_en                     ),
    .wr_end_i                          (wr_end                    ),
    .wr_sdram_en_i                     (wr_sdram_en               ),
    .wr_sdram_data_i                   (wr_sdram_data             ),
    // assign with read
    .rd_req_i                          (sdram_rd_req_i            ),
    .read_cmd_i                        (read_cmd                  ),
    .read_ba_i                         (read_ba                   ),
    .read_addr_i                       (read_addr                 ),
    .rd_en_o                           (rd_en                     ),
    .rd_end_i                          (rd_end                    ),
    .rd_data_o                         (rd_data                   ),
    // assign with top sdram interface
    .sdram_ba_o                        (sdram_ba_o                ),
    .sdram_addr_o                      (sdram_addr_o              ),
    .sdram_dq_en_o                     (sdram_dq_en_o             ),
    .sdram_dq_o                        (sdram_dq_o                ),
    .sdram_dq_i                        (sdram_dq_i                ),
    .sdram_cke_o                       (sdram_cke_o               ),
    .sdram_cs_n_o                      (sdram_cs_n_o              ),
    .sdram_ras_n_o                     (sdram_ras_n_o             ),
    .sdram_cas_n_o                     (sdram_cas_n_o             ),
    .sdram_we_n_o                      (sdram_we_n_o              ) 
  );
endmodule