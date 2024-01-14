
module async_fifo_tb;

  // Parameters
localparam                              integer RD_DATA_WIDTH = 64 ;
localparam                              integer WR_DATA_WIDTH = 64 ;
localparam                              integer RAM_DATA_WIDTH = 64;
localparam                              integer WR_DEPTH = 1024    ;

  //Ports
reg                                     global_rst                 ;
reg                                     wr_clk                     ;
wire                                    wr_en                      ;
reg                    [WR_DATA_WIDTH-1:0]din                        ;
wire                                    full                       ;
wire                                    prog_full                  ;
reg                                     rd_clk                     ;
wire                                     rd_en                      ;
wire                   [RD_DATA_WIDTH-1:0]dout                       ;
wire                                    empty                      ;
wire                                    prog_empty                 ;
reg                                    error                      ;
reg                    [RD_DATA_WIDTH-1:0]cnt                        ;

initial begin
  global_rst = 1;
  wr_clk=0;
  rd_clk=0;
  #20
  global_rst = 0;
end

assign wr_en = ~full;

assign rd_en = ~empty;

always@(posedge rd_clk)begin
  if (global_rst) begin
    cnt<='d0;
  end
  else if(rd_en)
    cnt<=cnt+'d1;
end

always@(posedge rd_clk)begin
  if (global_rst) begin
    error<='d0;
  end
  else if(cnt==dout)
    error<='d0;
  else
    error<='d1;
end

always@(posedge wr_clk)begin
  if (global_rst) begin
    din<='d0;
  end
  else if(wr_en)
    din<=din+'d1;
end

  async_fifo # (
    .RD_DATA_WIDTH                     (RD_DATA_WIDTH             ),
    .WR_DATA_WIDTH                     (WR_DATA_WIDTH             ),
    .RAM_DATA_WIDTH                    (RAM_DATA_WIDTH            ),
    .WR_DEPTH                          (WR_DEPTH                  ) 
  )
  async_fifo_inst (
    .global_rst                        (global_rst                ),
    .wr_clk                            (wr_clk                    ),
    .wr_en                             (wr_en                     ),
    .din                               (din                       ),
    .full                              (full                      ),
    .prog_full                         (prog_full                 ),
    .rd_clk                            (rd_clk                    ),
    .rd_en                             (rd_en                     ),
    .dout                              (dout                      ),
    .empty                             (empty                     ),
    .prog_empty                        (prog_empty                ) 
  );

always #5  wr_clk = ! wr_clk ;
always #15  rd_clk = ! rd_clk ;
endmodule