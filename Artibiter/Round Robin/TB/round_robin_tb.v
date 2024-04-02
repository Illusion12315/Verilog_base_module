`timescale 1ns / 1ps
// ********************************************************************************** // 
// Company:               
// Engineer:              Chen Xiong Zhi
// 
// File name:             round_robin_tb
// Create Date:           2024/03/23 22:28:15
// Version:               V1.0
// PATH:                  E:\FPGA\module_base\Artibiter\Round Robin\TB\round_robin_tb.v
// Descriptions:          
// 
// ********************************************************************************** // 


module round_robin_tb;

  // Parameters
    localparam                          REQUIRE_NUM               = 4     ;

  //Ports
    reg                                 sys_clk_i                  ;
    reg                                 rst_n_i                    ;
    reg                [REQUIRE_NUM-1: 0]request_i                 ;
    wire               [REQUIRE_NUM-1: 0]respond_o                 ;
    integer                             i                          ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// initial
//---------------------------------------------------------------------
initial begin
    sys_clk_i = 0;
    rst_n_i = 0;
    request_i = 0;
    # 100
    rst_n_i = 1;
    request_i = 4'b1111;
    # 1000
    for (i = 0; i<100; i=i+1) begin
        #50
        test_rr;
    end
end

task test_rr;
    request_i = $random;
endtask

round_robin_v2 # (
    .REQUIRE_NUM                        (REQUIRE_NUM               ) 
  )
  round_robin_v2_inst (
    .sys_clk_i                          (sys_clk_i                 ),
    .rst_n_i                            (rst_n_i                   ),
    .request_i                          (request_i                 ),
    .respond_o                          (respond_o                 ) 
  );

always #5  sys_clk_i = ! sys_clk_i ;

endmodule