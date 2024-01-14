module my_fft_n2 (
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,

    input                               data_in_flag_i             ,
    input              [  31:0]         data1_real_i               ,
    input              [  31:0]         data1_imag_i               ,
    input              [  31:0]         data2_real_i               ,
    input              [  31:0]         data2_imag_i               ,

    output                              data_out_flag_o            ,
    output             [  31:0]         data1_real_o               ,
    output             [  31:0]         data1_imag_o               ,
    output             [  31:0]         data2_real_o               ,
    output             [  31:0]         data2_imag_o                
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// 
//---------------------------------------------------------------------


// ********************************************************************************** // 
//---------------------------------------------------------------------
// rader
//---------------------------------------------------------------------
function rader;
    input                               integer data_in            ;
    input                               integer N                  ;
    if ($clog(data_in)%2 == 1) begin
        
    end
endfunction
endmodule