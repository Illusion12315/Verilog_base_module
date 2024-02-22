
module async_fifo #(
    parameter                           FIFO_DEEP                 = 1024,
    parameter                           DATA_WIDTH                = 8,
    parameter                           PROG_FULL_NUM             = 1000,
    parameter                           PROG_EMPTY_NUM            = 4
) (
    input                               wr_clk_i                   ,
    input                               wr_rst_n_i                 ,
    input                               wr_en_i                    ,
    input              [DATA_WIDTH-1: 0]din                        ,
    output                              prog_full                  ,
    output                              full                       ,
    output             [clogb2(FIFO_DEEP): 0]wr_fifo_num           ,

    input                               rd_clk_i                   ,
    input                               rd_rst_n_i                 ,
    input                               rd_en_i                    ,
    output             [DATA_WIDTH-1: 0]dout                       ,
    output                              prog_empty                 ,
    output                              empty                      ,
    output             [clogb2(FIFO_DEEP): 0]rd_fifo_num            
);
integer i;
//-----------------------------------------
//--function customrize
//-----------------------------------------
// clacluate the logarithm of base two
// for example, b = 8, a = clogb2(b) = 4
function integer clogb2;
    input                               integer number             ;
    begin
        for (clogb2 = 0; number>1; clogb2=clogb2+1) begin
            number = number >> 1;
        end
    end
endfunction
// ********************************************************************************** // 
//---------------------------------------------------------------------
// wires and regs
//---------------------------------------------------------------------
    localparam                          FIFO_DEEP_WIDTH           = clogb2(FIFO_DEEP);

    wire               [FIFO_DEEP_WIDTH-1: 0]wr_addr               ;
    wire               [FIFO_DEEP_WIDTH-1: 0]rd_addr               ;

    reg                [FIFO_DEEP_WIDTH: 0]wr_addr_extension       ;
    wire               [FIFO_DEEP_WIDTH: 0]wr_addr_extension_gray_sync_rd_clk;
    wire               [FIFO_DEEP_WIDTH: 0]wr_addr_extension_sync_rd;

    reg                [FIFO_DEEP_WIDTH: 0]rd_addr_extension       ;
    wire               [FIFO_DEEP_WIDTH: 0]rd_addr_extension_gray_sync_wr_clk;
    wire               [FIFO_DEEP_WIDTH: 0]rd_addr_extension_sync_wr;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// assigns
//---------------------------------------------------------------------
    assign                              wr_addr                   = wr_addr_extension[FIFO_DEEP_WIDTH-1: 0];
    assign                              rd_addr                   = rd_addr_extension[FIFO_DEEP_WIDTH-1: 0];

    assign                              wr_addr_extension_sync_rd = gray2bin(wr_addr_extension_gray_sync_rd_clk);
    assign                              rd_addr_extension_sync_wr = gray2bin(rd_addr_extension_gray_sync_wr_clk);

    assign                              wr_fifo_num               = wr_addr_extension - rd_addr_extension_sync_wr;
    assign                              rd_fifo_num               = wr_addr_extension_sync_rd - rd_addr_extension;

    assign                              full                      = (wr_fifo_num == FIFO_DEEP) | ((wr_fifo_num == FIFO_DEEP - 1) & wr_en_i);
    assign                              empty                     = (rd_fifo_num == 0) | ((rd_fifo_num == 1) & rd_en_i);

    assign                              prog_full                 = (wr_fifo_num >= PROG_FULL_NUM) | ((wr_fifo_num == PROG_FULL_NUM - 1) & wr_en_i);
    assign                              prog_empty                = (rd_fifo_num <= PROG_EMPTY_NUM) | ((rd_fifo_num == PROG_EMPTY_NUM + 1) & rd_en_i);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// beat_it_twice
//---------------------------------------------------------------------
beat_it_twice # (
    .DATA_WIDTH                         (FIFO_DEEP_WIDTH           ) 
  )
  sync_wr_addr2rd_clk (
    .signal_i                           (bin2gray(wr_addr_extension)),
    .sys_clk_i                          (rd_clk_i                  ),
    .signal_o                           (wr_addr_extension_gray_sync_rd_clk) 
  );
beat_it_twice # (
    .DATA_WIDTH                         (FIFO_DEEP_WIDTH           ) 
  )
  sync_rd_addr2wr_clk (
    .signal_i                           (bin2gray(rd_addr_extension)),
    .sys_clk_i                          (wr_clk_i                  ),
    .signal_o                           (rd_addr_extension_gray_sync_wr_clk) 
  );
// ********************************************************************************** // 
//---------------------------------------------------------------------
// addr customrize
//---------------------------------------------------------------------
// wr addr should add 1 when wr_en_i is valid
always@(posedge wr_clk_i or negedge wr_rst_n_i)begin
    if (!wr_rst_n_i)
        wr_addr_extension <= 'd0;
    else if (wr_en_i)
        wr_addr_extension <= wr_addr_extension + 'd1;
    else
        wr_addr_extension <= wr_addr_extension;
end
// rd addr should add 1 when rd_en_i is valid
always@(posedge rd_clk_i or negedge rd_rst_n_i)begin
    if (!rd_rst_n_i)
        rd_addr_extension <= 'd0;
    else if (rd_en_i)
        rd_addr_extension <= rd_addr_extension + 'd1;
    else
        rd_addr_extension <= rd_addr_extension;
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// simple double port ram
//---------------------------------------------------------------------
simple_double_port_ram # (
    .DATA_WIDTH                         (DATA_WIDTH                ),
    .RAM_DEEPTH                         (FIFO_DEEP                 ) 
  )
  simple_double_port_ram_inst (
    .wr_clk_i                           (wr_clk_i                  ),
    .wr_rst_i                           (wr_rst_n_i                ),
    .wr_en_i                            (wr_en_i                   ),
    .wr_addr_i                          (wr_addr                   ),
    .wr_data_i                          (din                       ),

    .rd_clk_i                           (rd_clk_i                  ),
    .rd_rst_i                           (rd_rst_n_i                ),
    .rd_en_i                            (rd_en_i                   ),
    .rd_addr_i                          (rd_addr                   ),
    .rd_data_o                          (dout                      ) 
  );
// ********************************************************************************** // 
//---------------------------------------------------------------------
// bin2gray and gray2bin function
//---------------------------------------------------------------------
// bin to gray code
function [FIFO_DEEP_WIDTH: 0] bin2gray;
    input              [FIFO_DEEP_WIDTH: 0]bin_in                  ;
    bin2gray = (bin_in >> 1) ^ bin_in;
endfunction
// gray to bin code
function [FIFO_DEEP_WIDTH: 0] gray2bin;
    input              [FIFO_DEEP_WIDTH: 0]gray_in                 ;
    begin
        gray2bin[FIFO_DEEP_WIDTH] = gray_in[FIFO_DEEP_WIDTH];
            for (i = 0; i < FIFO_DEEP_WIDTH; i = i + 1) begin
                gray2bin[i] = gray_in[i] ^ gray2bin[i+1];
            end
    end
endfunction
endmodule