`timescale 1ps/1ps

module N16_butterfly_base_n4_top_tb;

  // Parameters
    localparam                          DATA_WIDTH                = 8;
    localparam                          Wn_WIDTH                  = 8;
    localparam                          N_POINT                   = 16;

  //Ports
    reg                                 sys_clk_i                  ;
    reg                                 rst_n_i                    ;
    reg                                 data_in_valid_i            ;
    reg      signed    [DATA_WIDTH-1: 0]xn_real_i                  ;
    reg      signed    [DATA_WIDTH-1: 0]xn_imag_i                  ;
    wire                                data_out_valid_o           ;
    wire     signed    [DATA_WIDTH+Wn_WIDTH+1: 0]xk_real_o         ;
    wire     signed    [DATA_WIDTH+Wn_WIDTH+1: 0]xk_imag_o         ;
    reg                [   5: 0]        period_cnt                 ;

initial begin
    sys_clk_i = 0;
    rst_n_i = 0;
    xn_real_i = 0;
    xn_imag_i = 0;
    #100
    rst_n_i = 1;
end

// always@(posedge sys_clk_i or negedge rst_n_i)begin
//   if (!rst_n_i) begin
//     data_in_valid_i <= 'd0;
//   end
//   else
//     data_in_valid_i <= 'd1;
// end

always@(posedge sys_clk_i or negedge rst_n_i)begin
  if (!rst_n_i) begin
    data_in_valid_i <= 'd0;
  end
  else if (period_cnt >= 6 && period_cnt <48) begin
    data_in_valid_i <= 'd1;
  end
  else
    data_in_valid_i <= 'd0;
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
  if (!rst_n_i) begin
    period_cnt <= 'd0;
  end
  else
    period_cnt <= period_cnt + 'd1;
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
  if (!rst_n_i) begin
    xn_real_i <= 'd1;
  end
  else if (data_in_valid_i) begin
    // if (xn_real_i == 'd31) begin
    //   xn_real_i <= 'd1;
    // end
    // else
      xn_real_i <= xn_real_i + 'd2;
  end
  // else
  //   xn_real_i <= 'd1;
end

always@(*)begin
  xn_imag_i = 32 - xn_real_i;
end

N16_butterfly_base_n4_top # (
    .DATA_WIDTH                         (DATA_WIDTH                ),
    .Wn_WIDTH                           (Wn_WIDTH                  ),
    .N_POINT                            (N_POINT                   ) 
  )
  N16_butterfly_base_n4_top_inst (
    .sys_clk_i                          (sys_clk_i                 ),
    .rst_n_i                            (rst_n_i                   ),
    .data_in_valid_i                    (data_in_valid_i           ),
    .xn_real_i                          (xn_real_i                 ),
    .xn_imag_i                          (xn_imag_i                 ),
    .data_out_valid_o                   (data_out_valid_o          ),
    .xk_real_o                          (xk_real_o                 ),
    .xk_imag_o                          (xk_imag_o                 ) 
  );

always #5  sys_clk_i = ! sys_clk_i ;

endmodule