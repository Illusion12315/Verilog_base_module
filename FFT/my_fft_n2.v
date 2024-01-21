module my_fft_n2 #(
    parameter                           DATA_WIDTH = 32             
) (
    input                               sys_clk_i                  ,

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
localparam                              W04 = 1                    ;
reg                                     data_in_flag_r1 = 'd0      ;
reg                                     data_in_flag_r2 = 'd0      ;
reg             signed [DATA_WIDTH-1:0] xn1_real_r1 = 'd0          ;
reg             signed [DATA_WIDTH-1:0] xn1_imag_r1 = 'd0          ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// logic
//---------------------------------------------------------------------
always@(posedge sys_clk_i)begin
    data_in_flag_r1 <= data_in_flag_i;
    data_in_flag_r2 <= data_in_flag_r1;
end

always@(posedge sys_clk_i)begin
    xn1_real_r1 <= xn_real_i;
    xn1_imag_r1 <= xn_imag_i;
end

always@(posedge sys_clk_i)begin
    if (data_in_flag_r1) begin                                      // x(k) = x(n) + x(n+N/2)
        xk_real_o <= {xn1_real_r1[DATA_WIDTH-1],xn1_real_r1} + {xn_real_i[DATA_WIDTH-1],xn_real_i};
        xk_imag_o <= {xn1_imag_r1[DATA_WIDTH-1],xn1_imag_r1} + {xn_imag_i[DATA_WIDTH-1],xn_imag_i};
    end
    else if (data_in_flag_r2) begin                                 // x(k+N/2) = x(n) - x(n+N/2)
        xk_real_o <= {xn1_real_r1[DATA_WIDTH-1],xn1_real_r1} - {xn_real_i[DATA_WIDTH-1],xn_real_i};
        xk_imag_o <= {xn1_imag_r1[DATA_WIDTH-1],xn1_imag_r1} - {xn_imag_i[DATA_WIDTH-1],xn_imag_i};
    end
    else begin
        xk_real_o <= 'd0;
        xk_imag_o <= 'd0;
    end
end

assign data_out_flag_o = data_in_flag_r1;

endmodule