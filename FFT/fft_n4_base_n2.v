module fft_n4_base_n2 #(
    parameter                           DATA_WIDTH = 32             
) (
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,

    input                               data_in_flag_i             ,// first word
    input       signed [DATA_WIDTH-1:0] xn_real_i                  ,
    input       signed [DATA_WIDTH-1:0] xn_imag_i                  ,

    output                              data_out_flag_o            ,
    output reg  signed [DATA_WIDTH:0]   xk_real_o                  ,
    output reg  signed [DATA_WIDTH:0]   xk_imag_o                   
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// localparam and regs
//---------------------------------------------------------------------
// localparam                              W04 = 1                    ;
// localparam                              W14 = -j                    ;
reg                                     data_in_flag_r1 = 'd0      ;
reg                                     data_in_flag_r2 = 'd0      ;
reg             signed [DATA_WIDTH-1:0] xn_real_r1 = 'd0           ;
reg             signed [DATA_WIDTH-1:0] xn_real_r2 = 'd0           ;
reg             signed [DATA_WIDTH-1:0] xn_real_r3 = 'd0           ;
reg             signed [DATA_WIDTH-1:0] xn_real_r4 = 'd0           ;
reg             signed [DATA_WIDTH-1:0] xn_imag_r1 = 'd0           ;
reg             signed [DATA_WIDTH-1:0] xn_imag_r2 = 'd0           ;
reg             signed [DATA_WIDTH-1:0] xn_imag_r3 = 'd0           ;
reg             signed [DATA_WIDTH-1:0] xn_imag_r4 = 'd0           ;
reg                    [   1:0]         period_cnt                 ;
reg                                     cnt_en                     ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// logic
//---------------------------------------------------------------------
always@(posedge sys_clk_i)begin

end

assign data_out_flag_o = (period_cnt == 'd1);

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        cnt_en <= 'd0;
    end
    else if (data_out_flag_o) begin
        cnt_en <= 'd0;
    end
    else if (data_in_flag_i) begin
        cnt_en <= 'd1;
    end
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        period_cnt <= 'd0;
    end
    else if (data_out_flag_o) begin
        period_cnt <= 'd0;
    end
    else if (cnt_en || data_in_flag_i) begin
        period_cnt <= period_cnt + 'd1;
    end
end



endmodule