
module butterfly_n16_base_n4 #(
    parameter                           DATA_WIDTH                = 32
) (
    input                               sys_clk_i                  ,

    input       signed [DATA_WIDTH*4-1: 0]xn1_real_i               ,// xn11 = [31:0] xn12 = [63:32]
    input       signed [DATA_WIDTH*4-1: 0]xn2_real_i               ,
    input       signed [DATA_WIDTH*4-1: 0]xn3_real_i               ,
    input       signed [DATA_WIDTH*4-1: 0]xn4_real_i               ,

    input       signed [DATA_WIDTH*4-1: 0]xn1_imag_i               ,
    input       signed [DATA_WIDTH*4-1: 0]xn2_imag_i               ,
    input       signed [DATA_WIDTH*4-1: 0]xn3_imag_i               ,
    input       signed [DATA_WIDTH*4-1: 0]xn4_imag_i               ,

    output reg  signed [DATA_WIDTH*4: 0]xk1_real_o                 ,
    output reg  signed [DATA_WIDTH*4: 0]xk2_real_o                 ,
    output reg  signed [DATA_WIDTH*4: 0]xk3_real_o                 ,
    output reg  signed [DATA_WIDTH*4: 0]xk4_real_o                 ,

    output reg  signed [DATA_WIDTH: 0]  xk1_imag_o                 ,
    output reg  signed [DATA_WIDTH: 0]  xk2_imag_o                 ,
    output reg  signed [DATA_WIDTH: 0]  xk3_imag_o                 ,
    output reg  signed [DATA_WIDTH: 0]  xk4_imag_o                  
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// localparam and regs
//---------------------------------------------------------------------
integer i;
    reg      signed    [DATA_WIDTH-1: 0]xn1_real            [0:3]  ;
    reg      signed    [DATA_WIDTH-1: 0]xn2_real            [0:3]  ;
    reg      signed    [DATA_WIDTH-1: 0]xn3_real            [0:3]  ;
    reg      signed    [DATA_WIDTH-1: 0]xn4_real            [0:3]  ;

    reg      signed    [DATA_WIDTH-1: 0]xn1_imag            [0:3]  ;
    reg      signed    [DATA_WIDTH-1: 0]xn2_imag            [0:3]  ;
    reg      signed    [DATA_WIDTH-1: 0]xn3_imag            [0:3]  ;
    reg      signed    [DATA_WIDTH-1: 0]xn4_imag            [0:3]  ;

    reg      signed    [DATA_WIDTH: 0]  dataA_real                 ;
    reg      signed    [DATA_WIDTH: 0]  dataB_real                 ;
    reg      signed    [DATA_WIDTH: 0]  dataC_real                 ;
    reg      signed    [DATA_WIDTH: 0]  dataD_real                 ;

    reg      signed    [DATA_WIDTH: 0]  dataA_imag                 ;
    reg      signed    [DATA_WIDTH: 0]  dataB_imag                 ;
    reg      signed    [DATA_WIDTH: 0]  dataC_imag                 ;
    reg      signed    [DATA_WIDTH: 0]  dataD_imag                 ;

    reg      signed    [DATA_WIDTH: 0]  dataA1_real                ;
    reg      signed    [DATA_WIDTH: 0]  dataB1_real                ;
    reg      signed    [DATA_WIDTH: 0]  dataC1_real                ;
    reg      signed    [DATA_WIDTH: 0]  dataD1_real                ;

    reg      signed    [DATA_WIDTH: 0]  dataA1_imag                ;
    reg      signed    [DATA_WIDTH: 0]  dataB1_imag                ;
    reg      signed    [DATA_WIDTH: 0]  dataC1_imag                ;
    reg      signed    [DATA_WIDTH: 0]  dataD1_imag                ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// Wn
//---------------------------------------------------------------------
generate
    begin
        genvar i;
        for (i = 0; i < 4; i = i + 1) begin
            always@(*)begin
                xn1_real[i] = xn1_real_i[DATA_WIDTH + DATA_WIDTH*i -1: DATA_WIDTH*i];
                xn2_real[i] = xn2_real_i[DATA_WIDTH + DATA_WIDTH*i -1: DATA_WIDTH*i];
                xn3_real[i] = xn3_real_i[DATA_WIDTH + DATA_WIDTH*i -1: DATA_WIDTH*i];
                xn4_real[i] = xn4_real_i[DATA_WIDTH + DATA_WIDTH*i -1: DATA_WIDTH*i];

                xn1_imag[i] = xn1_imag_i[DATA_WIDTH + DATA_WIDTH*i -1: DATA_WIDTH*i];
                xn2_imag[i] = xn2_imag_i[DATA_WIDTH + DATA_WIDTH*i -1: DATA_WIDTH*i];
                xn3_imag[i] = xn3_imag_i[DATA_WIDTH + DATA_WIDTH*i -1: DATA_WIDTH*i];
                xn4_imag[i] = xn4_imag_i[DATA_WIDTH + DATA_WIDTH*i -1: DATA_WIDTH*i];
            end
        end
    end
endgenerate


always@(*)begin
    dataA_real = xn1_real_i + xn3_real_i;
    dataA_imag = xn1_imag_i + xn3_imag_i;

    dataB_real = xn2_real_i + xn4_real_i;
    dataB_imag = xn2_imag_i + xn4_imag_i;

    dataC_real = xn1_real_i - xn3_real_i;
    dataC_imag = xn1_imag_i - xn3_imag_i;

    dataD_real = xn2_real_i - xn4_real_i;
    dataD_imag = xn2_imag_i - xn4_imag_i;
end

always@(posedge sys_clk_i)begin
    dataA1_real <= dataA_real + dataB_real;
    dataA1_imag <= dataA_imag + dataB_imag;

    dataB1_real <= dataA_real - dataB_real;
    dataB1_imag <= dataA_imag - dataB_imag;

    dataC1_real <= dataC_real + dataD_imag;
    dataC1_imag <= dataC_imag - dataD_real;

    dataD1_real <= dataC_real - dataD_imag;
    dataD1_imag <= dataC_imag + dataD_real;
end

always@(*)begin
    xk1_real_o = dataA1_real;
    xk1_imag_o = dataA1_imag;

    xk2_real_o = dataB1_real;
    xk2_imag_o = dataB1_imag;

    xk3_real_o = dataC1_real;
    xk3_imag_o = dataC1_imag;

    xk4_real_o = dataD1_real;
    xk4_imag_o = dataD1_imag;
end

endmodule