
module N16_butterfly_base_n4_top #(
    parameter                           DATA_WIDTH                = 8,
    parameter                           Wn_WIDTH                  = 8,
    parameter                           N_POINT                   = 16
) (
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,

    input                               data_in_valid_i            ,
    input       signed [DATA_WIDTH-1: 0]xn_real_i                  ,
    input       signed [DATA_WIDTH-1: 0]xn_imag_i                  ,

    output reg                          data_out_valid_o           ,
    output reg  signed [DATA_WIDTH+Wn_WIDTH+1: 0]xk_real_o         ,
    output reg  signed [DATA_WIDTH+Wn_WIDTH+1: 0]xk_imag_o          
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// wires and regs
//---------------------------------------------------------------------
    localparam                          STAGE2_DATA_WIDTH         = DATA_WIDTH+Wn_WIDTH+1;
    localparam                          FINAL_WIDTH               = STAGE2_DATA_WIDTH + 1;

    integer i;

    reg      signed    [DATA_WIDTH*N_POINT-1: 0]xn_cache1_real     ;
    reg      signed    [DATA_WIDTH*N_POINT-1: 0]xn_cache1_imag     ;
    wire     signed    [(DATA_WIDTH+Wn_WIDTH+1)*N_POINT-1: 0]xn_cache2_real;
    wire     signed    [(DATA_WIDTH+Wn_WIDTH+1)*N_POINT-1: 0]xn_cache2_imag;
    wire     signed    [FINAL_WIDTH*N_POINT-1: 0]xk_real           ;
    wire     signed    [FINAL_WIDTH*N_POINT-1: 0]xk_imag           ;

    reg                                 data_in_valid_r1           ;
    wire                                data_in_valid_posedge      ;
    reg                [   5: 0]        wait_period_cnt            ;
    reg                [   3: 0]        revorder_addr              ;

    wire                                data_in_valid_time16       ;

    reg                [   3: 0]        xn_cache1_addr             ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// serial trans to parallel
//---------------------------------------------------------------------
    assign                              data_in_valid_posedge     = data_in_valid_i & ~data_in_valid_r1;
    assign                              data_in_valid_time16      = data_in_valid_posedge || ((wait_period_cnt >= 'd1) && (wait_period_cnt <= 'd15));

always@(posedge sys_clk_i)begin
    data_in_valid_r1 <= data_in_valid_i;
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        xn_cache1_addr <= 'd0;
    end
    else if (data_in_valid_time16) begin
        xn_cache1_addr <= xn_cache1_addr + 'd1;
    end
    else begin
        xn_cache1_addr <= xn_cache1_addr;
    end
end

always@(posedge sys_clk_i)begin
    if (data_in_valid_time16) begin
        xn_cache1_real[DATA_WIDTH-1+xn_cache1_addr*DATA_WIDTH -: DATA_WIDTH] <= xn_real_i;
        xn_cache1_imag[DATA_WIDTH-1+xn_cache1_addr*DATA_WIDTH -: DATA_WIDTH] <= xn_imag_i;
    end
    else begin
        xn_cache1_real <= xn_cache1_real;
        xn_cache1_imag <= xn_cache1_imag;
    end
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// first stage , N16 TO N4
//---------------------------------------------------------------------
N16_butterfly_base_n4 #(
    .Wn_WIDTH                           (Wn_WIDTH                  ),
    .DATA_WIDTH                         (DATA_WIDTH                ),
    .N_POINT                            (N_POINT                   ) 
  )
  N16_butterfly_base_n4_inst(
    .sys_clk_i                          (sys_clk_i                 ),

    .xn_real_i                          (xn_cache1_real            ),
    .xn_imag_i                          (xn_cache1_imag            ),
    
    .xk_real_o                          (xn_cache2_real            ),
    .xk_imag_o                          (xn_cache2_imag            ) 
  );
// ********************************************************************************** // 
//---------------------------------------------------------------------
// second stage , N4
//---------------------------------------------------------------------
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
            
    .xn_real_i                          (xn_cache2_real[STAGE2_DATA_WIDTH*4-1+STAGE2_DATA_WIDTH*i*4 -: STAGE2_DATA_WIDTH*4]),
    .xn_imag_i                          (xn_cache2_imag[STAGE2_DATA_WIDTH*4-1+STAGE2_DATA_WIDTH*i*4 -: STAGE2_DATA_WIDTH*4]),
                
    .xk_real_o                          (xk_real[FINAL_WIDTH*4-1+FINAL_WIDTH*i*4 -: FINAL_WIDTH*4]),
    .xk_imag_o                          (xk_imag[FINAL_WIDTH*4-1+FINAL_WIDTH*i*4 -: FINAL_WIDTH*4]) 
    );
        end
    end
endgenerate
// ********************************************************************************** // 
//---------------------------------------------------------------------
// trans to ram type , convenient to view
//---------------------------------------------------------------------
    reg      signed    [FINAL_WIDTH-1: 0]fn_final_real       [0:N_POINT-1]  ;
    reg      signed    [FINAL_WIDTH-1: 0]fn_final_imag       [0:N_POINT-1]  ;
    reg      signed    [FINAL_WIDTH-1: 0]fn_reorder_real     [0:N_POINT-1]  ;
    reg      signed    [FINAL_WIDTH-1: 0]fn_reorder_imag     [0:N_POINT-1]  ;

always@(*)begin
    for (i = 0; i<N_POINT; i=i+1) begin
        fn_final_real[i] = xk_real[FINAL_WIDTH-1+FINAL_WIDTH*i -: FINAL_WIDTH];
        fn_final_imag[i] = xk_imag[FINAL_WIDTH-1+FINAL_WIDTH*i -: FINAL_WIDTH];
    end
end

always@(*)begin
    fn_reorder_real[0 ] = fn_final_real[0];
    fn_reorder_real[1 ] = fn_final_real[8];
    fn_reorder_real[2 ] = fn_final_real[4];
    fn_reorder_real[3 ] = fn_final_real[12];
    fn_reorder_real[4 ] = fn_final_real[2];
    fn_reorder_real[5 ] = fn_final_real[10];
    fn_reorder_real[6 ] = fn_final_real[6];
    fn_reorder_real[7 ] = fn_final_real[14];
    fn_reorder_real[8 ] = fn_final_real[1];
    fn_reorder_real[9 ] = fn_final_real[9];
    fn_reorder_real[10] = fn_final_real[5];
    fn_reorder_real[11] = fn_final_real[13];
    fn_reorder_real[12] = fn_final_real[3];
    fn_reorder_real[13] = fn_final_real[11];
    fn_reorder_real[14] = fn_final_real[7];
    fn_reorder_real[15] = fn_final_real[15];

    fn_reorder_imag[0 ] = fn_final_imag[0];
    fn_reorder_imag[1 ] = fn_final_imag[8];
    fn_reorder_imag[2 ] = fn_final_imag[4];
    fn_reorder_imag[3 ] = fn_final_imag[12];
    fn_reorder_imag[4 ] = fn_final_imag[2];
    fn_reorder_imag[5 ] = fn_final_imag[10];
    fn_reorder_imag[6 ] = fn_final_imag[6];
    fn_reorder_imag[7 ] = fn_final_imag[14];
    fn_reorder_imag[8 ] = fn_final_imag[1];
    fn_reorder_imag[9 ] = fn_final_imag[9];
    fn_reorder_imag[10] = fn_final_imag[5];
    fn_reorder_imag[11] = fn_final_imag[13];
    fn_reorder_imag[12] = fn_final_imag[3];
    fn_reorder_imag[13] = fn_final_imag[11];
    fn_reorder_imag[14] = fn_final_imag[7];
    fn_reorder_imag[15] = fn_final_imag[15];
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// rader
//---------------------------------------------------------------------
    wire                                data_out_valid_r           ;

    assign                              data_out_valid_r          = (wait_period_cnt >= 'd19) && (wait_period_cnt < 'd35);

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        data_out_valid_o <= 'd0;
    end
    else
        data_out_valid_o <= data_out_valid_r;
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        wait_period_cnt <= 'd0;
    end
    else begin
        if (wait_period_cnt < 'd35 && wait_period_cnt >= 'd1) begin
            wait_period_cnt <= wait_period_cnt + 'd1;
        end
        else if (data_in_valid_posedge) begin
            wait_period_cnt <= 'd1;
        end
        else
            wait_period_cnt <= 'd0;
    end
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        revorder_addr <= 'd0;
    end
    else if (data_out_valid_r) begin
        revorder_addr <= revorder_addr + 'd1;
    end
    else
        revorder_addr <= revorder_addr;
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        xk_real_o <= 'd0;
        xk_imag_o <= 'd0;
    end
    else if (data_out_valid_r) begin
        xk_real_o <= fn_reorder_real[revorder_addr];
        xk_imag_o <= fn_reorder_imag[revorder_addr];
    end
    else begin
        xk_real_o <= 'd0;
        xk_imag_o <= 'd0;
    end
end
endmodule