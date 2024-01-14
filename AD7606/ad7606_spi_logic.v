

module ad9606_spi_logic (
    input                               sys_clk_i                  ,
    input                               rst_n_i                    ,
    //开始读取信号
    input                               spi_start_flag_i           ,
    //spi并行接口
    output                              cs_o                       ,
    output reg                          rd_o                       ,
    input              [  15:0]         ad_data_i                  ,
    //输出
    output reg                          data_flag_o                ,
    output reg         [  15:0]         ch1_data                   ,
    output reg         [  15:0]         ch2_data                   ,
    output reg         [  15:0]         ch3_data                   ,
    output reg         [  15:0]         ch4_data                   ,
    output reg         [  15:0]         ch5_data                   ,
    output reg         [  15:0]         ch6_data                   ,
    output reg         [  15:0]         ch7_data                   ,
    output reg         [  15:0]         ch8_data                   
);

// ********************************************************************************** // 
//---------------------------------------------------------------------
// REGS
//---------------------------------------------------------------------

reg                    [   3:0]         cur_state                  ;

reg                    [   3:0]         next_state                 ;

reg                    [   1:0]         cnt_clk                    ;

reg                    [   3:0]         cnt_data                   ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// localparam
//---------------------------------------------------------------------
localparam                              IDLE = 0                   ;
localparam                              READ = 1                   ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// 计数器
//---------------------------------------------------------------------
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cnt_clk<='d0;
    else if (cur_state==READ) begin
        cnt_clk<=cnt_clk+'d1;
    end
    else
        cnt_clk<='d0;
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cnt_data<='d0;
    else if (cnt_clk == 'd1 && cnt_data == 'd8) begin
        cnt_data<='d0;
    end
    else if (cur_state==READ && cnt_clk == 'd3) begin
        cnt_data<=cnt_data+'d1;
    end
    else
        cnt_data<=cnt_data;
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// 状态机
//---------------------------------------------------------------------
//第一段,状态跳转,时序逻辑
always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        cur_state<=IDLE;
    else
        cur_state<=next_state;
end

//第二段,跳转条件,组合逻辑
always@(*)begin
    case(cur_state)
        IDLE:begin
            if (spi_start_flag_i) begin
                next_state<=READ;
            end
            else
                next_state<=IDLE;
        end
        READ:begin
            if (cnt_clk == 'd1 && cnt_data == 'd8) begin
                next_state<=IDLE;
            end
            else
                next_state<=READ;
        end
        default:next_state<=IDLE;
    endcase
end

assign cs_o = rd_o;

always@(*)begin
    if (cur_state == READ) begin
        if (cnt_clk=='d0||cnt_clk=='d1) begin
            rd_o<='d1;
        end
        else
            rd_o<='d0;
    end
    else
        rd_o<='d1;
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)begin
        ch1_data<='d0;
        ch2_data<='d0;
        ch3_data<='d0;
        ch4_data<='d0;
        ch5_data<='d0;
        ch6_data<='d0;
        ch7_data<='d0;
        ch8_data<='d0;
    end
    else if (cnt_clk==3) begin
        case (cnt_data)
            0: ch1_data<=ad_data_i;
            1: ch2_data<=ad_data_i;
            2: ch3_data<=ad_data_i;
            3: ch4_data<=ad_data_i;
            4: ch5_data<=ad_data_i;
            5: ch6_data<=ad_data_i;
            6: ch7_data<=ad_data_i;
            7: ch8_data<=ad_data_i;
            default: begin
                ch1_data<=ch1_data;
                ch2_data<=ch2_data;
                ch3_data<=ch3_data;
                ch4_data<=ch4_data;
                ch5_data<=ch5_data;
                ch6_data<=ch6_data;
                ch7_data<=ch7_data;
                ch8_data<=ch8_data;
            end
        endcase
    end
    else begin
        ch1_data<=ch1_data;
        ch2_data<=ch2_data;
        ch3_data<=ch3_data;
        ch4_data<=ch4_data;
        ch5_data<=ch5_data;
        ch6_data<=ch6_data;
        ch7_data<=ch7_data;
        ch8_data<=ch8_data;
    end
end

always@(posedge sys_clk_i or negedge rst_n_i)begin
    if(!rst_n_i)
        data_flag_o <= 'd0;
    else if (cnt_clk == 'd1 && cnt_data == 'd8) begin
        data_flag_o <= 'd1;
    end
    else
        data_flag_o <= 'd0;
end
// ila_ch_data ila_ch_data (
//     .clk                               (sys_clk_i                 ),// input wire clk


//     .probe0                            (ch1_data                  ),// input wire [15:0]  probe0  
//     .probe1                            (ch2_data                  ),// input wire [15:0]  probe1 
//     .probe2                            (ch3_data                  ),// input wire [15:0]  probe2 
//     .probe3                            (ch4_data                  ),// input wire [15:0]  probe3 
//     .probe4                            (ch5_data                  ),// input wire [15:0]  probe4 
//     .probe5                            (ch6_data                  ),// input wire [15:0]  probe5 
//     .probe6                            (ch7_data                  ),// input wire [15:0]  probe6 
//     .probe7                            (ch8_data                  ),// input wire [15:0]  probe7 
//     .probe8                            (next_state                ) // input wire [3:0]  probe8
// );
endmodule