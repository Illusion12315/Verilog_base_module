`timescale 1 ns / 1 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: chen xiongzhi
// 
// Create Date: 2024/3/3
// Design Name: 
// Module Name: ddr3_4g_4ch_fsm
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
module ddr3_4g_4ch_fsm #(
    parameter                           CHANNEL_NUM               = 4,
    parameter                           C_M_AXI_BURST_LEN         = 16,// Burst Length. Supports 1, 2, 4, 8, 16, 32, 64, 128, 256 burst lengths
    parameter                           C_M_AXI_ADDR_WIDTH        = 31,// Width of Address Bus
    parameter                           C_M_AXI_DATA_WIDTH        = 512// Width of Data Bus
) (
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,

    input                               phy_init_done              ,
    output reg         [CHANNEL_NUM*C_M_AXI_ADDR_WIDTH-1: 0]ddr3_fifo_usedw,
    //-------------------------ram interface---------------------------//
    output                              wr_start_o                 ,
    output reg         [C_M_AXI_ADDR_WIDTH-1: 0]wr_addr_o          ,
    output             [C_M_AXI_DATA_WIDTH-1: 0]wr_data_o          ,
    input                               wr_data_respond_i          ,
    input                               wr_burst_done_i            ,

    output                              rd_start_o                 ,
    output reg         [C_M_AXI_ADDR_WIDTH-1: 0]rd_addr_o          ,
    input              [C_M_AXI_DATA_WIDTH-1: 0]rd_data_i          ,
    input                               rd_data_valid_i            ,
    input                               rd_burst_done_i            ,
    //---------------------------------------------------------------------
    // FIFO Interface for DDR3 SDRAM Upstream
    output reg         [CHANNEL_NUM-1: 0]fifo_rdreq_ddr3_us        ,
    input              [CHANNEL_NUM*C_M_AXI_DATA_WIDTH-1: 0]fifo_q_ddr3_us,
    input              [CHANNEL_NUM-1: 0]fifo_prog_empty_ddr3_us   ,
    //---------------------------------------------------------------------        
    // FIFO Interface for DDR3 SDRAM Downstream 
    output reg         [CHANNEL_NUM-1: 0]fifo_wrreq_ddr3_ds        ,
    output reg         [CHANNEL_NUM*C_M_AXI_DATA_WIDTH-1: 0]fifo_data_ddr3_ds,
    input              [CHANNEL_NUM-1: 0]fifo_prog_full_ddr3_ds     
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// function called clogb2 that returns an integer which has the value of the ceiling of the log base 2
// for example, b = 8, a = clogb2(b) = 4
//---------------------------------------------------------------------
function integer clogb2;
    input                               integer bit_depth          ;
    for (clogb2 = 0; bit_depth>0; clogb2=clogb2+1) begin
        bit_depth = bit_depth >> 1;
    end
endfunction
// ********************************************************************************** // 
//---------------------------------------------------------------------
// global regs and wires and localparams
//---------------------------------------------------------------------
    localparam                          integer burst_size_bytes  = clogb2(C_M_AXI_BURST_LEN-1) * C_M_AXI_DATA_WIDTH/8;//Burst size in bytes
    integer i;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// wr operation
//---------------------------------------------------------------------
    localparam                          WR_INIT                   = 0;
    localparam                          WR_IDLE                   = 1;
    localparam                          WR_ARBIT                  = 2;
    localparam                          WR_DATA                   = 3;
    reg                [   1: 0]        wr_cur_state               ;
    reg                [   1: 0]        wr_next_state              ;
    reg                [   1: 0]        wr_cur_winner              ;
    reg                [   1: 0]        wr_last_winner             ;
    reg                                 wr_addr_extension          ;

// last winner
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        wr_last_winner <= 0;
    else if(wr_cur_state == WR_ARBIT)
        wr_last_winner <= wr_cur_winner;
    else
        wr_last_winner <= wr_last_winner;
end

// current winner
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        wr_cur_winner <= 'd0;
    else if (wr_cur_state == WR_ARBIT) begin
        case(wr_last_winner)
            0:begin
                if (~fifo_prog_empty_ddr3_us[1])
                    wr_cur_winner <= 'd1;
                else if (~fifo_prog_empty_ddr3_us[2])
                    wr_cur_winner <= 'd2;
                else if (~fifo_prog_empty_ddr3_us[3])
                    wr_cur_winner <= 'd3;
                else
                    wr_cur_winner <= 'd0;
            end
            1:begin
                if (~fifo_prog_empty_ddr3_us[2])
                    wr_cur_winner <= 'd2;
                else if (~fifo_prog_empty_ddr3_us[3])
                    wr_cur_winner <= 'd3;
                else if (~fifo_prog_empty_ddr3_us[0])
                    wr_cur_winner <= 'd0;
                else
                    wr_cur_winner <= 'd1;
            end
            2:begin
                if (~fifo_prog_empty_ddr3_us[3])
                    wr_cur_winner <= 'd3;
                else if (~fifo_prog_empty_ddr3_us[0])
                    wr_cur_winner <= 'd0;
                else if (~fifo_prog_empty_ddr3_us[1])
                    wr_cur_winner <= 'd1;
                else
                    wr_cur_winner <= 'd2;
            end
            3:begin
                if (~fifo_prog_empty_ddr3_us[0])
                    wr_cur_winner <= 'd0;
                else if (~fifo_prog_empty_ddr3_us[1])
                    wr_cur_winner <= 'd1;
                else if (~fifo_prog_empty_ddr3_us[2])
                    wr_cur_winner <= 'd2;
                else
                    wr_cur_winner <= 'd3;
            end
            default:wr_cur_winner <= 'd0;
        endcase
    end
    else
        wr_cur_winner <= wr_cur_winner;
end

//第一段,状态跳转,时序逻辑
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        wr_cur_state <= WR_INIT;
    else
        wr_cur_state <= wr_next_state;
end

//第二段,跳转条件,组合逻辑
always@(*)begin
    case(wr_cur_state)
        WR_INIT:
            if (phy_init_done)
                wr_next_state <= WR_IDLE;
            else
                wr_next_state <= WR_INIT;
        WR_IDLE:
            if (|(~fifo_prog_empty_ddr3_us))
                wr_next_state <= WR_ARBIT;
            else
                wr_next_state <= WR_IDLE;
        WR_ARBIT: wr_next_state <= WR_DATA;
        WR_DATA:
            if (wr_burst_done_i)
                wr_next_state <= WR_IDLE;
            else
                wr_next_state <= WR_DATA;
        default:wr_next_state <= WR_IDLE;
    endcase
end
//---------------------------------------------------------------------
// wr operation logic
//---------------------------------------------------------------------
    assign                              wr_start_o                = (wr_cur_state == WR_ARBIT);

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i)
        {wr_addr_extension,wr_addr_o} <= 'd0;
    else if (wr_burst_done_i)
        {wr_addr_extension,wr_addr_o} <= {wr_addr_extension,wr_addr_o} + burst_size_bytes;
    else
        {wr_addr_extension,wr_addr_o} <= {wr_addr_extension,wr_addr_o};
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i)
        fifo_rdreq_ddr3_us <= 'd0;
    else if (wr_cur_state == WR_DATA)
        fifo_rdreq_ddr3_us[wr_cur_winner] <= wr_data_respond_i;
    else
        fifo_rdreq_ddr3_us <= 'd0;
end

    assign                              wr_data_o                 = fifo_q_ddr3_us[C_M_AXI_DATA_WIDTH*(wr_cur_winner+1)-1 -: C_M_AXI_DATA_WIDTH];
// ********************************************************************************** // 
//---------------------------------------------------------------------
// rd operation
//---------------------------------------------------------------------
    localparam                          RD_INIT                   = 0;
    localparam                          RD_IDLE                   = 1;
    localparam                          RD_ARBIT                  = 2;
    localparam                          RD_DATA                   = 3;
    reg                [   1: 0]        rd_cur_state               ;
    reg                [   1: 0]        rd_next_state              ;
    reg                [   1: 0]        rd_cur_winner              ;
    reg                [   1: 0]        rd_last_winner             ;
    reg                                 rd_addr_extension          ;

// last winner
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        rd_last_winner <= 'd0;
    else if(rd_cur_state == RD_ARBIT)
        rd_last_winner <= rd_cur_winner;
    else
        rd_last_winner <= rd_last_winner;
end

// current winner
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        rd_cur_winner <= 'd0;
    else if (rd_cur_state == RD_ARBIT) begin
        case(rd_last_winner)
            0:begin
                if (~fifo_prog_full_ddr3_ds[1])
                    rd_cur_winner <= 'd1;
                else if (~fifo_prog_full_ddr3_ds[2])
                    rd_cur_winner <= 'd2;
                else if (~fifo_prog_full_ddr3_ds[3])
                    rd_cur_winner <= 'd3;
                else
                    rd_cur_winner <= 'd0;
            end
            1:begin
                if (~fifo_prog_full_ddr3_ds[2])
                    rd_cur_winner <= 'd2;
                else if (~fifo_prog_full_ddr3_ds[3])
                    rd_cur_winner <= 'd3;
                else if (~fifo_prog_full_ddr3_ds[0])
                    rd_cur_winner <= 'd0;
                else
                    rd_cur_winner <= 'd1;
            end
            2:begin
                if (~fifo_prog_full_ddr3_ds[3])
                    rd_cur_winner <= 'd3;
                else if (~fifo_prog_full_ddr3_ds[0])
                    rd_cur_winner <= 'd0;
                else if (~fifo_prog_full_ddr3_ds[1])
                    rd_cur_winner <= 'd1;
                else
                    rd_cur_winner <= 'd2;
            end
            3:begin
                if (~fifo_prog_full_ddr3_ds[0])
                    rd_cur_winner <= 'd0;
                else if (~fifo_prog_full_ddr3_ds[1])
                    rd_cur_winner <= 'd1;
                else if (~fifo_prog_full_ddr3_ds[2])
                    rd_cur_winner <= 'd2;
                else
                    rd_cur_winner <= 'd3;
            end
            default:rd_cur_winner <= 'd0;
        endcase
    end
    else
        rd_cur_winner <= rd_cur_winner;
end

//第一段,状态跳转,时序逻辑
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        rd_cur_state <= RD_INIT;
    else
        rd_cur_state <= rd_next_state;
end

//第二段,跳转条件,组合逻辑
always@(*)begin
    case(rd_cur_state)
        RD_INIT:
            if (phy_init_done)
                rd_next_state <= RD_IDLE;
            else
                rd_next_state <= RD_INIT;
        RD_IDLE:
            if (|(~fifo_prog_full_ddr3_ds))
                rd_next_state <= RD_ARBIT;
            else
                rd_next_state <= RD_IDLE;
        RD_ARBIT: rd_next_state <= RD_DATA;
        RD_DATA:
            if (rd_burst_done_i)
                rd_next_state <= RD_IDLE;
            else
                rd_next_state <= RD_DATA;
        default:rd_next_state <= RD_IDLE;
    endcase
end
//---------------------------------------------------------------------
// rd operation 
//---------------------------------------------------------------------
    assign                              rd_start_o                = (rd_cur_state == RD_ARBIT);

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i)
        {rd_addr_extension,rd_addr_o} <= 'd0;
    else if (rd_burst_done_i)
        {rd_addr_extension,rd_addr_o} <= {rd_addr_extension,rd_addr_o} + burst_size_bytes;
    else
        {rd_addr_extension,rd_addr_o} <= {rd_addr_extension,rd_addr_o};
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i)
        fifo_data_ddr3_ds <= 'd0;
    else if (rd_cur_state == RD_DATA)
        fifo_data_ddr3_ds[C_M_AXI_DATA_WIDTH*(rd_cur_winner+1)-1 -: C_M_AXI_DATA_WIDTH] <= rd_data_i;
    else
        fifo_data_ddr3_ds <= fifo_data_ddr3_ds;
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i)
        fifo_wrreq_ddr3_ds <= 'd0;
    else if (rd_cur_state == RD_DATA)
        fifo_wrreq_ddr3_ds[rd_cur_winner] <= rd_data_valid_i;
    else
        fifo_wrreq_ddr3_ds <= 'd0;
end

// ********************************************************************************** // 
//---------------------------------------------------------------------
// fifo memory now
//---------------------------------------------------------------------
generate
    begin
        genvar i;
        for (i = 0; i < CHANNEL_NUM; i = i + 1) begin
            always@(posedge sys_clk_i or negedge rst_n_i)begin
                if (!rst_n_i)
                    ddr3_fifo_usedw <= 'd0;
                else
                    ddr3_fifo_usedw[C_M_AXI_ADDR_WIDTH*(i+1) - 1 -:C_M_AXI_ADDR_WIDTH*i] <=
                        {wr_addr_extension,wr_addr_o} - {rd_addr_extension,rd_addr_o};
            end
        end
    end
endgenerate

endmodule