module fft_n64_base_n4 #(
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
// ********************************************************************************** // 
//---------------------------------------------------------------------
// localparam and regs
//---------------------------------------------------------------------
    reg      signed    [DATA_WIDTH-1: 0]xn_ram_real         [0:63]  ;
    reg      signed    [DATA_WIDTH-1: 0]xn_ram_imag         [0:63]  ;

    reg      signed    [DATA_WIDTH-1: 0]dataA_real          [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataB_real          [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataC_real          [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataD_real          [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataA1_real         [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataB1_real         [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataC1_real         [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataD1_real         [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataA2_real         [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataB2_real         [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataC2_real         [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataD2_real         [0:15]  ;

    reg      signed    [DATA_WIDTH-1: 0]dataA_imag          [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataB_imag          [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataC_imag          [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataD_imag          [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataA1_imag         [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataB1_imag         [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataC1_imag         [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataD1_imag         [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataA2_imag         [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataB2_imag         [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataC2_imag         [0:15]  ;
    reg      signed    [DATA_WIDTH-1: 0]dataD2_imag         [0:15]  ;

    integer i;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// stage 1
//---------------------------------------------------------------------
// x(1:16) + x(33:48) + x(17:32) + x(49:64)
generate
    begin
        genvar i;
        for (i = 0; i <= 15; i = i+1) begin:add1
            // add1
            always@(*)begin
                // x(1:16) + x(33:48)
                dataA_real[i] = xn_ram_real[i] + xn_ram_real[i+32];
                dataA_imag[i] = xn_ram_imag[i] + xn_ram_imag[i+32];
                // x(17:32) + x(49:64)
                dataB_real[i] = xn_ram_real[i+16] + xn_ram_real[i+48];
                dataB_imag[i] = xn_ram_imag[i+16] + xn_ram_imag[i+48];
                // x(1:16) - x(33:48)
                dataC_real[i] = xn_ram_real[i] - xn_ram_real[i+32];
                dataC_imag[i] = xn_ram_imag[i] - xn_ram_imag[i+32];
                // x(17:32) - x(49:64)
                dataD_real[i] = xn_ram_real[i+16] - xn_ram_real[i+48];
                dataD_imag[i] = xn_ram_imag[i+16] - xn_ram_imag[i+48];
            end
            // add2
            always@(posedge sys_clk_i)begin
                // x(1:16) + x(33:48) + x(17:32) + x(49:64)
                dataA1_real[i] <= dataA_real[i] + dataB_real[i];
                dataA1_imag[i] <= dataA_imag[i] + dataB_imag[i];
                // x(1:16) + x(33:48) - (x(17:32) + x(49:64))
                dataB1_real[i] <= dataA_real[i] - dataB_real[i];
                dataB1_imag[i] <= dataA_imag[i] - dataB_imag[i];
                // (x(1:16) - x(33:48)) - j*(x(17:32) - x(49:64))
                dataC1_real[i] <= dataC_real[i] + dataD_imag[i];
                dataC1_imag[i] <= dataC_imag[i] - dataD_real[i];
                // (x(1:16) - x(33:48)) + j*(x(17:32) - x(49:64))
                dataD1_real[i] <= dataC_real[i] - dataD_imag[i];
                dataD1_imag[i] <= dataC_imag[i] + dataD_real[i];
            end
            // complex multiplicate
            always@(posedge sys_clk_i)begin
                
            end
            // 
        end
    end
endgenerate

endmodule