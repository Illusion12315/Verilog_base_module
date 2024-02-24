`timescale 1ps/1ps

module N16_butterfly_base_n4_tb;

  // Parameters
    parameter                           Wn_WIDTH                  = 8;
    parameter                           DATA_WIDTH                = 8;
    parameter                           N_POINT                   = 16;
  //Ports

    integer i;

    reg                                 sys_clk_i                  ;
    reg      signed    [DATA_WIDTH*N_POINT-1: 0]xn_real_i          ;
    reg      signed    [DATA_WIDTH*N_POINT-1: 0]xn_imag_i          ;
    wire     signed    [(DATA_WIDTH+Wn_WIDTH+1)*N_POINT-1: 0]xk_real_o;
    wire     signed    [(DATA_WIDTH+Wn_WIDTH+1)*N_POINT-1: 0]xk_imag_o;

    localparam                          STAGE2_DATA_WIDTH         = DATA_WIDTH+Wn_WIDTH+1;
    localparam                          FINAL_WIDTH               = STAGE2_DATA_WIDTH + 1;

    wire     signed    [FINAL_WIDTH*N_POINT-1: 0]x_final_real      ;
    wire     signed    [FINAL_WIDTH*N_POINT-1: 0]x_final_imag      ;

    initial begin
        sys_clk_i = 0;
        
        for (i = 0; i<N_POINT; i = i + 1) begin
            xn_real_i[DATA_WIDTH-1+DATA_WIDTH*i -: DATA_WIDTH] = i*2+1;
            xn_imag_i[DATA_WIDTH-1+DATA_WIDTH*i -: DATA_WIDTH] = 31-i*2;
        end
        // #100
        // for (i = 0; i<N_POINT; i = i + 1) begin
        //     xn_real_i[DATA_WIDTH-1+DATA_WIDTH*i -: DATA_WIDTH] = 0;
        //     xn_imag_i[DATA_WIDTH-1+DATA_WIDTH*i -: DATA_WIDTH] = 0;
        // end
    end
// first stage
N16_butterfly_base_n4 #(
    .Wn_WIDTH                           (Wn_WIDTH                  ),
    .DATA_WIDTH                         (DATA_WIDTH                ),
    .N_POINT                            (N_POINT                   ) 
  )
  N16_butterfly_base_n4_inst(
    .sys_clk_i                          (sys_clk_i                 ),

    .xn_real_i                          (xn_real_i                 ),
    .xn_imag_i                          (xn_imag_i                 ),
    
    .xk_real_o                          (xk_real_o                 ),
    .xk_imag_o                          (xk_imag_o                 ) 
  );

// second stage
generate
    begin
        genvar i;
        for (i = 0; i<N_POINT/4; i=i+1) begin:butterfly
N4_butterfly_base_n4 #(
    .DATA_WIDTH                         (STAGE2_DATA_WIDTH         ),
    .N_POINT                            (N_POINT/4                 ) 
    )
    N4_butterfly_base_n4_inst(
    .sys_clk_i                          (sys_clk_i                 ),
            
    .xn_real_i                          (xk_real_o[STAGE2_DATA_WIDTH*4-1+STAGE2_DATA_WIDTH*i*4 -: STAGE2_DATA_WIDTH*4]),
    .xn_imag_i                          (xk_imag_o[STAGE2_DATA_WIDTH*4-1+STAGE2_DATA_WIDTH*i*4 -: STAGE2_DATA_WIDTH*4]),
                
    .xk_real_o                          (x_final_real[FINAL_WIDTH*4-1+FINAL_WIDTH*i*4 -: FINAL_WIDTH*4]),
    .xk_imag_o                          (x_final_imag[FINAL_WIDTH*4-1+FINAL_WIDTH*i*4 -: FINAL_WIDTH*4]) 
    );
        end
    end
endgenerate

    reg      signed    [FINAL_WIDTH-1: 0]fn_final_real        [0:N_POINT-1]  ;
    reg      signed    [FINAL_WIDTH-1: 0]fn_final_imag        [0:N_POINT-1]  ;

always@(*)begin
    for (i = 0; i<N_POINT; i=i+1) begin
        fn_final_real[i] = x_final_real[FINAL_WIDTH-1+FINAL_WIDTH*i -: FINAL_WIDTH];
        fn_final_imag[i] = x_final_imag[FINAL_WIDTH-1+FINAL_WIDTH*i -: FINAL_WIDTH];
    end
end

always #5  sys_clk_i = ! sys_clk_i ;

endmodule