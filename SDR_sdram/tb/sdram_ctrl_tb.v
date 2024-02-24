`timescale 1ns/1ns


module sdram_ctrl_tb;

// Parameters

//Ports
reg                                     sys_clk_i                  ;
reg                                     rst_n_i                    ;
reg                                     sdram_wr_req_i             ;
reg                    [  23:0]         sdram_wr_addr_i            ;
reg                    [  15:0]         sdram_wr_data_i            ;
reg                    [   9:0]         sdram_wr_length_i          ;
wire                                    sdram_wr_ack_o             ;
reg                                     sdram_rd_req_i             ;
reg                    [  23:0]         sdram_rd_addr_i            ;
wire                   [  15:0]         sdram_rd_data_o            ;
reg                    [   9:0]         sdram_rd_length_i          ;
wire                                    sdram_rd_ack_o             ;
wire                                    sdram_init_end_o           ;
wire                   [   1:0]         sdram_ba_o                 ;
wire                   [  12:0]         sdram_addr_o               ;
wire                   [  15:0]         sdram_dq_io                ;
wire                                    sdram_cke_o                ;
wire                                    sdram_cs_n_o               ;
wire                                    sdram_cas_n_o              ;
wire                                    sdram_ras_n_o              ;
wire                                    sdram_we_n_o               ;

defparam sdram_model_plus_inst.addr_bits = 13;
defparam sdram_model_plus_inst.data_bits = 16;
defparam sdram_model_plus_inst.col_bits  = 9;
defparam sdram_model_plus_inst.mem_sizes = 2*1024*1024;

initial begin
    sys_clk_i = 0;
    rst_n_i = 0;
    sdram_wr_length_i = 8;
    sdram_rd_length_i = 8;
    #100
    rst_n_i = 1;
end

reg                    [  63:0]         cnt                        ;
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        cnt <= 'd0;
    end
    else if (cnt == 999) begin
        cnt <= 'd0;
    end
    else if (sdram_init_end_o) begin
        cnt <= cnt + 'd1;
    end
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        sdram_wr_req_i <= 'd0;
    end
    else if (cnt >= 699 && cnt <= 799 && sdram_init_end_o) begin
        sdram_wr_req_i <= 'd1;
    end
    else
        sdram_wr_req_i <= 'd0;
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        sdram_wr_data_i <= 'd0;
    end
    else if (sdram_wr_ack_o) begin
        sdram_wr_data_i <= sdram_wr_data_i + 'd1;
    end
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        sdram_wr_addr_i <= 'd0;
    end
    else if (sdram_wr_ack_o) begin
        sdram_wr_addr_i <= sdram_wr_addr_i + 'd1;
    end
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        sdram_rd_req_i <= 'd0;
    end
    else if (cnt >= 899 && cnt <= 999 && sdram_init_end_o) begin
        sdram_rd_req_i <= 'd1;
    end
    else
        sdram_rd_req_i <= 'd0;
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        sdram_rd_addr_i <= 'd0;
    end
    else if (sdram_rd_ack_o) begin
        sdram_rd_addr_i <= sdram_rd_addr_i + 'd1;
    end
end

sdram_ctrl  sdram_ctrl_inst (
    .sys_clk_i                         (sys_clk_i                 ),
    .rst_n_i                           (rst_n_i                   ),

    .sdram_wr_req_i                    (sdram_wr_req_i            ),
    .sdram_wr_addr_i                   (sdram_wr_addr_i           ),
    .sdram_wr_data_i                   (sdram_wr_data_i           ),
    .sdram_wr_length_i                 (sdram_wr_length_i         ),
    .sdram_wr_ack_o                    (sdram_wr_ack_o            ),

    .sdram_rd_req_i                    (sdram_rd_req_i            ),
    .sdram_rd_addr_i                   (sdram_rd_addr_i           ),
    .sdram_rd_data_o                   (sdram_rd_data_o           ),
    .sdram_rd_length_i                 (sdram_rd_length_i         ),
    .sdram_rd_ack_o                    (sdram_rd_ack_o            ),

    .sdram_init_end_o                  (sdram_init_end_o          ),

    .sdram_ba_o                        (sdram_ba_o                ),
    .sdram_addr_o                      (sdram_addr_o              ),
    .sdram_dq_io                       (sdram_dq_io               ),
    .sdram_cke_o                       (sdram_cke_o               ),
    .sdram_cs_n_o                      (sdram_cs_n_o              ),
    .sdram_cas_n_o                     (sdram_cas_n_o             ),
    .sdram_ras_n_o                     (sdram_ras_n_o             ),
    .sdram_we_n_o                      (sdram_we_n_o              ) 
);

sdram_model_plus  sdram_model_plus_inst (
    .Dq                                (sdram_dq_io               ),
    .Addr                              (sdram_addr_o              ),
    .Ba                                (sdram_ba_o                ),
    .Clk                               (~sys_clk_i                ),
    .Cke                               (1'b1                      ),
    .Cs_n                              (sdram_cs_n_o              ),
    .Ras_n                             (sdram_ras_n_o             ),
    .Cas_n                             (sdram_cas_n_o             ),
    .We_n                              (sdram_we_n_o              ),
    .Dqm                               ( 'b0                      ),
    .Debug                             (1'b1                      ) 
  );

always #5  sys_clk_i = ! sys_clk_i ;

endmodule