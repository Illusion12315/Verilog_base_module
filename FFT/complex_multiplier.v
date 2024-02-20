
module complex_multiplier (
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,

    input              [  31: 0]        data1_real_i               ,
    input              [  31: 0]        data1_imag_i               ,
    input              [  31: 0]        data2_real_i               ,
    input              [  31: 0]        data2_imag_i               ,

    output             [  33: 0]        data_out_real_o            ,
    output             [  33: 0]        data_out_imag_o             
);
    
endmodule