`timescale 1ns/1ns
module sdram_init_tb;

  // Parameters

  //Ports
reg                                     sys_clk_i                  ;
reg                                     rst_n_i                    ;
wire                   [   3:0]         init_cmd                   ;
wire                   [   1:0]         init_ba                    ;
wire                   [  12:0]         init_addr                  ;
wire                                    init_end                   ;

initial begin
    sys_clk_i = 0;
    rst_n_i = 0;
    #100
    rst_n_i = 1;
end

defparam sdram_model_plus_inst.addr_bits = 13;
defparam sdram_model_plus_inst.data_bits = 16;
defparam sdram_model_plus_inst.col_bits  = 9;
defparam sdram_model_plus_inst.mem_sizes = 2*1024*1024;

sdram_init  sdram_init_inst (
    .sys_clk_i                         (sys_clk_i                 ),
    .rst_n_i                           (rst_n_i                   ),

    .init_cmd_o                        (init_cmd                  ),
    .init_ba_o                         (init_ba                   ),
    .init_addr_o                       (init_addr                 ),
    .init_end_o                        (init_end                  ) 
  );

sdram_model_plus  sdram_model_plus_inst (
    .Dq                                (                          ),
    .Addr                              (init_addr                 ),
    .Ba                                (init_ba                   ),
    .Clk                               (~sys_clk_i                ),
    .Cke                               (1'b1                      ),
    .Cs_n                              (init_cmd[3]               ),
    .Ras_n                             (init_cmd[2]               ),
    .Cas_n                             (init_cmd[1]               ),
    .We_n                              (init_cmd[0]               ),
    .Dqm                               (2'b0                      ),
    .Debug                             (1'b1                      ) 
  );

always #5  sys_clk_i = ! sys_clk_i ;

endmodule