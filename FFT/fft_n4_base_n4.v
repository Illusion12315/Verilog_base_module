module fft_n4_base_n4 #(
    parameter                           DATA_WIDTH                = 32
) (
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,

    input                               data_in_valid_i            ,// first word
    input       signed [DATA_WIDTH-1: 0]xn_real_i                  ,
    input       signed [DATA_WIDTH-1: 0]xn_imag_i                  ,

    output                              data_out_valid_o           ,
    output reg  signed [DATA_WIDTH: 0]  xk_real_o                  ,
    output reg  signed [DATA_WIDTH: 0]  xk_imag_o                   
);

endmodule