
module sync_fifo #(
    parameter                           FIFO_DEEP                 = 1024,
    parameter                           DATA_WIDTH                = 8,
    parameter                           PROG_FULL_NUM             = 1000,
    parameter                           PROG_EMPTY_NUM            = 4
) (
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,

    input                               wr_en                      ,
    input              [DATA_WIDTH-1: 0]din                        ,
    output                              prog_full                  ,
    output                              full                       ,

    input                               rd_en                      ,
    output             [DATA_WIDTH-1: 0]dout                       ,
    output                              prog_empty                 ,
    output                              empty                      ,

    output             [clogb2(FIFO_DEEP): 0]fifo_num               
);
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
    wire               [clogb2(FIFO_DEEP)-1: 0]wr_addr             ;
    wire               [clogb2(FIFO_DEEP)-1: 0]rd_addr             ;
    reg                [clogb2(FIFO_DEEP): 0]wr_addr_extension     ;
    reg                [clogb2(FIFO_DEEP): 0]rd_addr_extension     ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// assigns
//---------------------------------------------------------------------
    assign                              wr_addr                   = wr_addr_extension[clogb2(FIFO_DEEP)-1: 0];
    assign                              rd_addr                   = rd_addr_extension[clogb2(FIFO_DEEP)-1: 0];

    assign                              fifo_num                  = wr_addr_extension - rd_addr_extension;

    assign                              full                      = (fifo_num == FIFO_DEEP) | ((fifo_num == FIFO_DEEP - 1) & wr_en & ~rd_en);
    assign                              empty                     = (fifo_num == 0) | ((fifo_num == 1) & rd_en & ~wr_en);

    assign                              prog_full                 = (fifo_num >= PROG_FULL_NUM) | ((fifo_num == PROG_FULL_NUM - 1) & wr_en & ~rd_en);
    assign                              prog_empty                = (fifo_num <= PROG_EMPTY_NUM) | ((fifo_num == PROG_EMPTY_NUM + 1) & rd_en & ~wr_en);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// logic
//---------------------------------------------------------------------
// wr addr should add 1 when wr_en is valid
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i)
        wr_addr_extension <= 'd0;
    else if (wr_en)
        wr_addr_extension <= wr_addr_extension + 'd1;
    else
        wr_addr_extension <= wr_addr_extension;
end
// rd addr should add 1 when rd_en is valid
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i)
        rd_addr_extension <= 'd0;
    else if (rd_en)
        rd_addr_extension <= rd_addr_extension + 'd1;
    else
        rd_addr_extension <= rd_addr_extension;
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// double port ram
//---------------------------------------------------------------------
simple_double_port_ram # (
    .DATA_WIDTH                         (DATA_WIDTH                ),
    .RAM_DEEPTH                         (FIFO_DEEP                 ) 
  )
  simple_double_port_ram_inst (
    .wr_clk_i                           (sys_clk_i                 ),
    .wr_rst_i                           (rst_n_i                   ),

    .wr_en_i                            (wr_en                     ),
    .wr_addr_i                          (wr_addr                   ),
    .wr_data_i                          (din                       ),

    .rd_clk_i                           (sys_clk_i                 ),
    .rd_rst_i                           (rst_n_i                   ),

    .rd_en_i                            (rd_en                     ),
    .rd_addr_i                          (rd_addr                   ),
    .rd_data_o                          (dout                      ) 
  );
endmodule