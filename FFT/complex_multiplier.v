
module complex_multiplier #(
    parameter                           DATA1_WIDTH               = 32,
    parameter                           DATA2_WIDTH               = 8
) (
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,

    input       signed [DATA1_WIDTH-1: 0]data1_real_i              ,
    input       signed [DATA1_WIDTH-1: 0]data1_imag_i              ,
    input       signed [DATA2_WIDTH-1: 0]data2_real_i              ,// i
    input       signed [DATA2_WIDTH-1: 0]data2_imag_i              ,// q

    output reg  signed [DATA1_WIDTH+DATA2_WIDTH: 0]data_out_real_o ,
    output reg  signed [DATA1_WIDTH+DATA2_WIDTH: 0]data_out_imag_o  // data1_width + data2_width + 1
);
    reg      signed    [DATA1_WIDTH+DATA2_WIDTH: 0]data_cache    ='d0;
    
always@(*)begin
    // cache = a_i * (b_i + b_q)
    data_cache = data1_real_i * (data2_real_i + data2_imag_i);
end

always@(posedge sys_clk_i)begin
    // result_i = a_i * (b_i + b_q) - b_q * (a_i + a_q) 
    data_out_real_o <= data_cache - data2_imag_i * (data1_real_i + data1_imag_i);
    // result_q = a_i * (b_i + b_q) - b_i * (a_i - a_q)
    data_out_imag_o <= data_cache - data2_real_i * (data1_real_i - data1_imag_i);
end

endmodule