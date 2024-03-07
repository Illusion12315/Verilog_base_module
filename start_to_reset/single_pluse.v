//单低变高输入，单脉冲输出
module signle_pluse(
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,
    input                               signal_in                  ,
    output                              pluse_out                   
);
    reg                                 signal_r1                  ;

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if (!rst_n_i) begin
        signal_r1 <= 'd0;
    end
    else
        signal_r1 <= signal_in;
end

    assign                              pluse_out                 = signal_in & ~signal_r1;

endmodule