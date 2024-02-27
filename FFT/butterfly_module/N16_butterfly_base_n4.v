//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: chen xiongzhi
// 
// Create Date: 2024/2/25
// Design Name: 
// Module Name: N16_butterfly_base_n4
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
module N16_butterfly_base_n4 #(
    parameter                           Wn_WIDTH                  = 8,
    parameter                           DATA_WIDTH                = 8,
    parameter                           N_POINT                   = 16// N_DIV = N/4, for example N_DIV should be 4 when need to calculate 16 fft
) (
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,

    input       signed [DATA_WIDTH*N_POINT-1: 0]xn_real_i          ,// xn11 = [31:0] xn12 = [63:32]
    input       signed [DATA_WIDTH*N_POINT-1: 0]xn_imag_i          ,

    output reg  signed [(DATA_WIDTH+Wn_WIDTH+1)*N_POINT-1: 0]xk_real_o,
    output reg  signed [(DATA_WIDTH+Wn_WIDTH+1)*N_POINT-1: 0]xk_imag_o 
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// localparam and regs
//---------------------------------------------------------------------
    integer i;

    localparam                          N_DIV                     = N_POINT/4;

    reg      signed    [DATA_WIDTH-1: 0]xn1_real            [0:N_DIV-1]  ;
    reg      signed    [DATA_WIDTH-1: 0]xn2_real            [0:N_DIV-1]  ;
    reg      signed    [DATA_WIDTH-1: 0]xn3_real            [0:N_DIV-1]  ;
    reg      signed    [DATA_WIDTH-1: 0]xn4_real            [0:N_DIV-1]  ;

    reg      signed    [DATA_WIDTH-1: 0]xn1_imag            [0:N_DIV-1]  ;
    reg      signed    [DATA_WIDTH-1: 0]xn2_imag            [0:N_DIV-1]  ;
    reg      signed    [DATA_WIDTH-1: 0]xn3_imag            [0:N_DIV-1]  ;
    reg      signed    [DATA_WIDTH-1: 0]xn4_imag            [0:N_DIV-1]  ;

    reg      signed    [DATA_WIDTH: 0]  dataA_real          [0:N_DIV-1]  ;
    reg      signed    [DATA_WIDTH: 0]  dataB_real          [0:N_DIV-1]  ;
    reg      signed    [DATA_WIDTH: 0]  dataC_real          [0:N_DIV-1]  ;
    reg      signed    [DATA_WIDTH: 0]  dataD_real          [0:N_DIV-1]  ;

    reg      signed    [DATA_WIDTH: 0]  dataA_imag          [0:N_DIV-1]  ;
    reg      signed    [DATA_WIDTH: 0]  dataB_imag          [0:N_DIV-1]  ;
    reg      signed    [DATA_WIDTH: 0]  dataC_imag          [0:N_DIV-1]  ;
    reg      signed    [DATA_WIDTH: 0]  dataD_imag          [0:N_DIV-1]  ;

    reg      signed    [DATA_WIDTH+1: 0]dataA1_real         [0:N_DIV-1]  ;
    reg      signed    [DATA_WIDTH+1: 0]dataB1_real         [0:N_DIV-1]  ;
    reg      signed    [DATA_WIDTH+1: 0]dataC1_real         [0:N_DIV-1]  ;
    reg      signed    [DATA_WIDTH+1: 0]dataD1_real         [0:N_DIV-1]  ;

    reg      signed    [DATA_WIDTH+1: 0]dataA1_imag         [0:N_DIV-1]  ;
    reg      signed    [DATA_WIDTH+1: 0]dataB1_imag         [0:N_DIV-1]  ;
    reg      signed    [DATA_WIDTH+1: 0]dataC1_imag         [0:N_DIV-1]  ;
    reg      signed    [DATA_WIDTH+1: 0]dataD1_imag         [0:N_DIV-1]  ;

    wire     signed    [DATA_WIDTH+Wn_WIDTH: 0]dataA2_real         [0:N_DIV-1]  ;
    wire     signed    [DATA_WIDTH+Wn_WIDTH: 0]dataB2_real         [0:N_DIV-1]  ;
    wire     signed    [DATA_WIDTH+Wn_WIDTH: 0]dataC2_real         [0:N_DIV-1]  ;
    wire     signed    [DATA_WIDTH+Wn_WIDTH: 0]dataD2_real         [0:N_DIV-1]  ;

    wire     signed    [DATA_WIDTH+Wn_WIDTH: 0]dataA2_imag         [0:N_DIV-1]  ;
    wire     signed    [DATA_WIDTH+Wn_WIDTH: 0]dataB2_imag         [0:N_DIV-1]  ;
    wire     signed    [DATA_WIDTH+Wn_WIDTH: 0]dataC2_imag         [0:N_DIV-1]  ;
    wire     signed    [DATA_WIDTH+Wn_WIDTH: 0]dataD2_imag         [0:N_DIV-1]  ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// Wn mult with 64
//---------------------------------------------------------------------
    reg      signed    [Wn_WIDTH-1: 0]  WnA_real            [0:N_DIV-1]  ;
    reg      signed    [Wn_WIDTH-1: 0]  WnA_imag            [0:N_DIV-1]  ;
    reg      signed    [Wn_WIDTH-1: 0]  WnB_real            [0:N_DIV-1]  ;
    reg      signed    [Wn_WIDTH-1: 0]  WnB_imag            [0:N_DIV-1]  ;
    reg      signed    [Wn_WIDTH-1: 0]  WnC_real            [0:N_DIV-1]  ;
    reg      signed    [Wn_WIDTH-1: 0]  WnC_imag            [0:N_DIV-1]  ;
    reg      signed    [Wn_WIDTH-1: 0]  WnD_real            [0:N_DIV-1]  ;
    reg      signed    [Wn_WIDTH-1: 0]  WnD_imag            [0:N_DIV-1]  ;

initial begin
    for (i = 0; i < N_DIV; i = i + 1) begin
        WnA_real[i] = 64;
        WnA_imag[i] = 0;
    end
    WnB_real[0] = 64;
    WnB_imag[0] = 0;
    WnB_real[1] = 45;
    WnB_imag[1] = -45;
    WnB_real[2] = 0;
    WnB_imag[2] = -64;
    WnB_real[3] = -45;
    WnB_imag[3] = -45;

    WnC_real[0] = 64;
    WnC_imag[0] = 0;
    WnC_real[1] = 59;
    WnC_imag[1] = -24;
    WnC_real[2] = 45;
    WnC_imag[2] = -45;
    WnC_real[3] = 24;
    WnC_imag[3] = -59;

    WnD_real[0] = 64;
    WnD_imag[0] = 0;
    WnD_real[1] = 24;
    WnD_imag[1] = -59;
    WnD_real[2] = -45;
    WnD_imag[2] = -45;
    WnD_real[3] = -59;
    WnD_imag[3] = 24;
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// calculate
//---------------------------------------------------------------------
generate
    begin
        genvar i;
        for (i = 0; i < N_DIV; i = i + 1) begin
            // distribute bit to ram
            always@(*)begin
                xn1_real[i] = xn_real_i[DATA_WIDTH -1 + DATA_WIDTH*i: DATA_WIDTH*i];
                xn2_real[i] = xn_real_i[DATA_WIDTH -1 + DATA_WIDTH*(i + N_DIV): DATA_WIDTH*(i + N_DIV)];
                xn3_real[i] = xn_real_i[DATA_WIDTH -1 + DATA_WIDTH*(i + 2*N_DIV): DATA_WIDTH*(i + 2*N_DIV)];
                xn4_real[i] = xn_real_i[DATA_WIDTH -1 + DATA_WIDTH*(i + 3*N_DIV): DATA_WIDTH*(i + 3*N_DIV)];

                xn1_imag[i] = xn_imag_i[DATA_WIDTH -1 + DATA_WIDTH*i: DATA_WIDTH*i];
                xn2_imag[i] = xn_imag_i[DATA_WIDTH -1 + DATA_WIDTH*(i + N_DIV): DATA_WIDTH*(i + N_DIV)];
                xn3_imag[i] = xn_imag_i[DATA_WIDTH -1 + DATA_WIDTH*(i + 2*N_DIV): DATA_WIDTH*(i + 2*N_DIV)];
                xn4_imag[i] = xn_imag_i[DATA_WIDTH -1 + DATA_WIDTH*(i + 3*N_DIV): DATA_WIDTH*(i + 3*N_DIV)];
            end
            // first add
            always@(*)begin
                dataA_real[i] = xn1_real[i] + xn3_real[i];
                dataA_imag[i] = xn1_imag[i] + xn3_imag[i];
            
                dataB_real[i] = xn2_real[i] + xn4_real[i];
                dataB_imag[i] = xn2_imag[i] + xn4_imag[i];
            
                dataC_real[i] = xn1_real[i] - xn3_real[i];
                dataC_imag[i] = xn1_imag[i] - xn3_imag[i];
            
                dataD_real[i] = xn2_real[i] - xn4_real[i];
                dataD_imag[i] = xn2_imag[i] - xn4_imag[i];
            end
            // second add
            always@(posedge sys_clk_i)begin
                dataA1_real[i] <= dataA_real[i] + dataB_real[i];
                dataA1_imag[i] <= dataA_imag[i] + dataB_imag[i];
            
                dataB1_real[i] <= dataA_real[i] - dataB_real[i];
                dataB1_imag[i] <= dataA_imag[i] - dataB_imag[i];
            
                dataC1_real[i] <= dataC_real[i] + dataD_imag[i];
                dataC1_imag[i] <= dataC_imag[i] - dataD_real[i];
            
                dataD1_real[i] <= dataC_real[i] - dataD_imag[i];
                dataD1_imag[i] <= dataC_imag[i] + dataD_real[i];
            end
            // complex multiplicate
            complex_multiplier #(
                .DATA1_WIDTH                        (DATA_WIDTH                ),
                .DATA2_WIDTH                        (Wn_WIDTH                  ) 
                )
                A_multiply_Wn (
                .sys_clk_i                          (sys_clk_i                 ),
                .rst_n_i                            (rst_n_i                   ),
                .data1_real_i                       (dataA1_real[i]            ),
                .data1_imag_i                       (dataA1_imag[i]            ),
                .data2_real_i                       (WnA_real[i]               ),
                .data2_imag_i                       (WnA_imag[i]               ),
                .data_out_real_o                    (dataA2_real[i]            ),// data1_width + data2_width + 1
                .data_out_imag_o                    (dataA2_imag[i]            ) 
            );
            complex_multiplier #(
                .DATA1_WIDTH                        (DATA_WIDTH                ),
                .DATA2_WIDTH                        (Wn_WIDTH                  ) 
                )
                B_multiply_Wn (
                .sys_clk_i                          (sys_clk_i                 ),
                .rst_n_i                            (rst_n_i                   ),
                .data1_real_i                       (dataB1_real[i]            ),
                .data1_imag_i                       (dataB1_imag[i]            ),
                .data2_real_i                       (WnB_real[i]               ),
                .data2_imag_i                       (WnB_imag[i]               ),
                .data_out_real_o                    (dataB2_real[i]            ),// data1_width + data2_width + 1
                .data_out_imag_o                    (dataB2_imag[i]            ) 
            );
            complex_multiplier #(
                .DATA1_WIDTH                        (DATA_WIDTH                ),
                .DATA2_WIDTH                        (Wn_WIDTH                  ) 
                )
                C_multiply_Wn (
                .sys_clk_i                          (sys_clk_i                 ),
                .rst_n_i                            (rst_n_i                   ),
                .data1_real_i                       (dataC1_real[i]            ),
                .data1_imag_i                       (dataC1_imag[i]            ),
                .data2_real_i                       (WnC_real[i]               ),
                .data2_imag_i                       (WnC_imag[i]               ),
                .data_out_real_o                    (dataC2_real[i]            ),
                .data_out_imag_o                    (dataC2_imag[i]            ) 
            );
            complex_multiplier #(
                .DATA1_WIDTH                        (DATA_WIDTH                ),
                .DATA2_WIDTH                        (Wn_WIDTH                  ) 
                )
                D_multiply_Wn (
                .sys_clk_i                          (sys_clk_i                 ),
                .rst_n_i                            (rst_n_i                   ),
                .data1_real_i                       (dataD1_real[i]            ),
                .data1_imag_i                       (dataD1_imag[i]            ),
                .data2_real_i                       (WnD_real[i]               ),
                .data2_imag_i                       (WnD_imag[i]               ),
                .data_out_real_o                    (dataD2_real[i]            ),
                .data_out_imag_o                    (dataD2_imag[i]            ) 
            );
            //
            always@(*)begin
                xk_real_o[(DATA_WIDTH+Wn_WIDTH+1) + (DATA_WIDTH+Wn_WIDTH+1)*i -1: (DATA_WIDTH+Wn_WIDTH+1)*i] = dataA2_real[i];
                xk_real_o[(DATA_WIDTH+Wn_WIDTH+1) + (DATA_WIDTH+Wn_WIDTH+1)*(i + N_DIV) -1: (DATA_WIDTH+Wn_WIDTH+1)*(i + N_DIV)] = dataB2_real[i];
                xk_real_o[(DATA_WIDTH+Wn_WIDTH+1) + (DATA_WIDTH+Wn_WIDTH+1)*(i + 2*N_DIV) -1: (DATA_WIDTH+Wn_WIDTH+1)*(i + 2*N_DIV)] = dataC2_real[i];
                xk_real_o[(DATA_WIDTH+Wn_WIDTH+1) + (DATA_WIDTH+Wn_WIDTH+1)*(i + 3*N_DIV) -1: (DATA_WIDTH+Wn_WIDTH+1)*(i + 3*N_DIV)] = dataD2_real[i];

                xk_imag_o[(DATA_WIDTH+Wn_WIDTH+1) + (DATA_WIDTH+Wn_WIDTH+1)*i -1: (DATA_WIDTH+Wn_WIDTH+1)*i] = dataA2_imag[i];
                xk_imag_o[(DATA_WIDTH+Wn_WIDTH+1) + (DATA_WIDTH+Wn_WIDTH+1)*(i + N_DIV) -1: (DATA_WIDTH+Wn_WIDTH+1)*(i + N_DIV)] = dataB2_imag[i];
                xk_imag_o[(DATA_WIDTH+Wn_WIDTH+1) + (DATA_WIDTH+Wn_WIDTH+1)*(i + 2*N_DIV) -1: (DATA_WIDTH+Wn_WIDTH+1)*(i + 2*N_DIV)] = dataC2_imag[i];
                xk_imag_o[(DATA_WIDTH+Wn_WIDTH+1) + (DATA_WIDTH+Wn_WIDTH+1)*(i + 3*N_DIV) -1: (DATA_WIDTH+Wn_WIDTH+1)*(i + 3*N_DIV)] = dataD2_imag[i];
            end
        end
    end
endgenerate

endmodule