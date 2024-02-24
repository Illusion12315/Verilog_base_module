
module sdram2fifo (
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,
    
    output reg                          sdram_wr_req_o             ,// ask for write
    output             [  23:0]         sdram_wr_addr_o            ,// wr addr, it can be refreshed when ack is high.
    output             [  15:0]         sdram_wr_data_o            ,// wr data, it can be refreshed when ack is hign.
    output             [   9:0]         sdram_wr_length_o          ,
    input                               sdram_wr_ack_i             ,// ack signal.

    output reg                          sdram_rd_req_o             ,// ask for read
    output             [  23:0]         sdram_rd_addr_o            ,// rd addr, it can be refreshed when ack is high.
    input              [  15:0]         sdram_rd_data_i            ,// rd data, it can be refreshed when ack is hign.
    output             [   9:0]         sdram_rd_length_o          ,
    input                               sdram_rd_ack_i             ,// ack signal.

    input                               wr_en_i                    ,
    input              [  15:0]         wr_data_i                  ,
    output                              full                       ,

    input                               rd_en_i                    ,
    output             [  15:0]         rd_data_o                  ,
    output                              empty                       

);

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        sdram_wr_req_o <= 'd0;
    end
    else if (elements_rd > sdram_wr_length_o) begin
        sdram_wr_req_o <= 'd1;
    end
    else
        sdram_wr_req_o <= 'd0;
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        sdram_rd_req_o <= 'd0;
    end
    else if (elements_wr < sdram_wr_length_o) begin
        sdram_rd_req_o <= 'd1;
    end
    else
        sdram_rd_req_o <= 'd0;
end

standard_fifo # (
    .RD_DATA_WIDTH                     (16                        ),
    .WR_DATA_WIDTH                     (16                        ),
    .RAM_DATA_WIDTH                    (16                        ),
    .WR_DEPTH                          (64                        ) 
  )
  standard_fifo_inst_wr (
    .global_rst                        (~rst_n_i                  ),

    .wr_clk                            (sys_clk_i                 ),
    .wr_en                             (wr_en_i                   ),
    .din                               (wr_data_i                 ),
    .full                              (full                      ),

    .rd_clk                            (sys_clk_i                 ),
    .rd_en                             (sdram_wr_ack_i            ),
    .dout                              (sdram_wr_data_o           ),
    .elements_rd                       (elements_rd               ),
    .empty                             (empty                     ) 
  );

standard_fifo # (
    .RD_DATA_WIDTH                     (16                        ),
    .WR_DATA_WIDTH                     (16                        ),
    .RAM_DATA_WIDTH                    (16                        ),
    .WR_DEPTH                          (64                        ) 
  )
  standard_fifo_inst_rd (
    .global_rst                        (~rst_n_i                  ),

    .wr_clk                            (sys_clk_i                 ),
    .wr_en                             (wr_en_i                   ),
    .din                               (wr_data_i                 ),
    .elements_wr                       (elements_wr               ),
    .full                              (full                      ),

    .rd_clk                            (sys_clk_i                 ),
    .rd_en                             (sdram_wr_ack_i            ),
    .dout                              (sdram_wr_data_o           ),
    .elements_rd                       (elements_rd               ),
    .empty                             (empty                     ) 
  );
endmodule