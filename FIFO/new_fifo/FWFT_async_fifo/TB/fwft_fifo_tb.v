`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             fwft_fifo_tb
// Create Date:           2024/04/13 14:32:11
// Version:               V1.0
// PATH:                  E:\FPGA\module_base\FIFO\new_fifo\FWFT_async_fifo\TB\fwft_fifo_tb.v
// Descriptions:          
// 
// ********************************************************************************** // 


module fwft_async_fifo_tb;

  // Parameters
    localparam                          FIFO_DEEP                 = 1024  ;
    localparam                          DATA_WIDTH                = 32    ;
    localparam                          PROG_FULL_NUM             = 1000  ;
    localparam                          PROG_EMPTY_NUM            = 4     ;

  //Ports
    reg                                 wr_clk_i                   ;
    reg                                 wr_rst_n_i                 ;
    reg                                 wr_en_i                    ;
    reg                [DATA_WIDTH-1: 0]din                        ;
    wire                                prog_full                  ;
    wire                                full                       ;
    wire               [clogb2(FIFO_DEEP): 0]wr_fifo_num           ;


    reg                                 rd_clk_i                   ;
    reg                                 rd_rst_n_i                 ;
    reg                                 rd_en_i                    ;
    wire               [DATA_WIDTH-1: 0]dout                       ;
    wire                                prog_empty                 ;
    wire                                empty                      ;
    wire               [clogb2(FIFO_DEEP): 0]rd_fifo_num           ;
    
    reg                [DATA_WIDTH-1: 0]dout_sim                   ;
    reg                                 error                      ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// 
//---------------------------------------------------------------------
initial begin
    wr_clk_i   = 0;
    wr_rst_n_i = 0;
    rd_clk_i   = 0;
    rd_rst_n_i = 0;
    wr_en_i = 0;
    rd_en_i = 0;
    #100
    test_fwft_fifo();
end

always@(posedge wr_clk_i or negedge wr_rst_n_i)begin
    if (!wr_rst_n_i) begin
        din <= 'd0;
    end
    else if (wr_en_i) begin
        din <= din + 'd1;
    end
end

always@(posedge rd_clk_i or negedge rd_rst_n_i)begin
    if (!rd_rst_n_i) begin
        dout_sim <= 'd0;
    end
    else if (rd_en_i) begin
        dout_sim <= #1 dout_sim + 'd1;
    end
end

always@(posedge rd_clk_i or negedge rd_rst_n_i)begin
    rd_en_i = #1 !empty;
end

always@(posedge rd_clk_i)begin
    if (rd_en_i) begin
        if (dout_sim != dout) begin
            error = 1;
        end
        else
            error = 0;
    end
    else
        error = 0;
end

// ********************************************************************************** // 
//---------------------------------------------------------------------
// task
//---------------------------------------------------------------------
task test_fwft_fifo;
    begin
        wr_rst_n_i = 1;
        rd_rst_n_i = 1;
        #50
        wr_en_i = #1 !full;
        #1000
        wr_en_i = 0;
    end
endtask

// ********************************************************************************** // 
//---------------------------------------------------------------------
// DUT
//---------------------------------------------------------------------
fwft_async_fifo # (
    .FIFO_DEEP                          (FIFO_DEEP                 ),
    .DATA_WIDTH                         (DATA_WIDTH                ),
    .PROG_FULL_NUM                      (PROG_FULL_NUM             ),
    .PROG_EMPTY_NUM                     (PROG_EMPTY_NUM            ) 
  )
  fwft_async_fifo_inst (
    .wr_clk_i                           (wr_clk_i                  ),
    .wr_rst_n_i                         (wr_rst_n_i                ),
    .wr_en_i                            (wr_en_i                   ),
    .din                                (din                       ),
    .prog_full                          (prog_full                 ),
    .full                               (full                      ),
    .wr_fifo_num                        (wr_fifo_num               ),
    .rd_clk_i                           (rd_clk_i                  ),
    .rd_rst_n_i                         (rd_rst_n_i                ),
    .rd_en_i                            (rd_en_i                   ),
    .dout                               (dout                      ),
    .prog_empty                         (prog_empty                ),
    .empty                              (empty                     ),
    .rd_fifo_num                        (rd_fifo_num               ) 
  );

always #7.5 wr_clk_i = ! wr_clk_i ;
always #5 rd_clk_i = ! rd_clk_i ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// ±ê×¼²Î¿¼
//---------------------------------------------------------------------
//     wire                                xilinx_full                ;

// fifo_generator_0 xilinx_fifo_inst (
//     .wr_clk                             (wr_clk_i                  ),// input wire wr_clk
//     .wr_en                              (wr_en                     ),// input wire wr_en
//     .din                                (din                       ),// input wire [7 : 0] din
//     .prog_full                          (                          ),// output wire prog_full
//     .full                               (xilinx_full               ),// output wire full

//     .rd_clk                             (rd_clk_i                  ),// input wire rd_clk
//     .rd_en                              (rd_en                     ),// input wire rd_en
//     .dout                               (dout                      ),// output wire [7 : 0] dout
//     .empty                              (empty                     ),// output wire empty
//     .prog_empty                         (prog_empty                ) // output wire prog_empty
// );
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
endmodule