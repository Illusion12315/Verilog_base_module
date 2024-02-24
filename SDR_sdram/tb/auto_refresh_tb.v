`timescale 1ns/1ns

module sdram_auto_refresh_tb;

  // Parameters

  //Ports
reg                                     sys_clk_i                  ;
reg                                     rst_n_i                    ;
reg                                     init_end                   ;
reg                                     auto_refresh_en            ;
wire                                    auto_refresh_req           ;
wire                                    auto_refresh_end           ;
wire                   [   3:0]         auto_refresh_cmd           ;
wire                   [   1:0]         auto_refresh_ba            ;
wire                   [  12:0]         auto_refresh_addr          ;

defparam sdram_model_plus_inst.addr_bits = 13;
defparam sdram_model_plus_inst.data_bits = 16;
defparam sdram_model_plus_inst.col_bits  = 9;
defparam sdram_model_plus_inst.mem_sizes = 2*1024*1024;

always@(posedge sys_clk_i or negedge rst_n_i)begin
  if(!rst_n_i)
    auto_refresh_en<='d0;
  else if (auto_refresh_req) begin
    auto_refresh_en<='d1;
  end
  else
    auto_refresh_en<='d0;
end

initial begin
  sys_clk_i = 0;
  rst_n_i = 0;
  init_end = 0;
  auto_refresh_en = 0;
  #100
  rst_n_i = 1;
  #100
  init_end = 1;
end

  sdram_auto_refresh  sdram_auto_refresh_inst (
    .sys_clk_i                         (sys_clk_i                 ),
    .rst_n_i                           (rst_n_i                   ),
    .init_end                          (init_end                  ),
    .auto_refresh_en                   (auto_refresh_en           ),

    .auto_refresh_req                  (auto_refresh_req          ),
    .auto_refresh_end                  (auto_refresh_end          ),

    .auto_refresh_cmd                  (auto_refresh_cmd          ),
    .auto_refresh_ba                   (auto_refresh_ba           ),
    .auto_refresh_addr                 (auto_refresh_addr         ) 
  );

  sdram_model_plus  sdram_model_plus_inst (
    .Dq                                (                          ),
    .Addr                              (auto_refresh_addr         ),
    .Ba                                (auto_refresh_ba           ),
    .Clk                               (~sys_clk_i                ),
    .Cke                               (1'b1                      ),
    .Cs_n                              (auto_refresh_cmd[3]       ),
    .Ras_n                             (auto_refresh_cmd[2]       ),
    .Cas_n                             (auto_refresh_cmd[1]       ),
    .We_n                              (auto_refresh_cmd[0]       ),
    .Dqm                               (2'b0                      ),
    .Debug                             (1'b1                      ) 
  );
always #5  sys_clk_i = ! sys_clk_i ;

endmodule