// ********************************************************************************** // 
//---------------------------------------------------------------------
// 格雷码转二进制模块
//---------------------------------------------------------------------
module gray2bin
#(
    parameter                           integer DATA_WIDTH = 256    
)
(
    output             [DATA_WIDTH-1:0] bin_o                      ,
    input              [DATA_WIDTH-1:0] gray_i                      
);

assign bin_o[DATA_WIDTH-1] = gray_i[DATA_WIDTH-1];

generate
    genvar i;
    for (i = 0; i<DATA_WIDTH-1; i=i+1) begin
        assign bin_o[i] = gray_i[i]^bin_o[i+1];
    end
endgenerate

endmodule