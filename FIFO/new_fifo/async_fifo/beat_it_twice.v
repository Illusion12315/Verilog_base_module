// ********************************************************************************** // 
//---------------------------------------------------------------------
// ╢Ра╫ее
//---------------------------------------------------------------------
module beat_it_twice #(
    parameter                           integer DATA_WIDTH = 1      
)
(
    input              [DATA_WIDTH-1:0] signal_i                   ,
    input                               sys_clk_i                  ,
    output             [DATA_WIDTH-1:0] signal_o                    
);

(* ASYNC_REG = "TRUE" *)
reg                    [DATA_WIDTH-1:0] r_s1,r_s2                  ;

initial begin
    r_s1 = 'd0;
    r_s2 = 'd0;
end

assign    signal_o    =    r_s2;

always@(posedge sys_clk_i)begin
    r_s1    <=    signal_i;
    r_s2    <=    r_s1;
end

endmodule