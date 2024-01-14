//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: chenxiongzhi
// 
// Create Date: 2023/08/24 16:22:08
// Design Name: 
// Module Name: RST
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


//�ϵ��Զ�������λ
module start_rst_module
#(
    parameter                           RST_TIME_CNT = 'd1_000      
)
(
    input                               i_sys_clk                  ,
    input                               i_rst_in                   ,
	
    output                              o_rst_out                   
);
reg                    [  15:0]         cnt='d0                    ;
reg                                     auto_rst_n                 ;

assign    o_rst_out = auto_rst_n & i_rst_in;

always@(posedge i_sys_clk)begin
    if(cnt<RST_TIME_CNT-'d1)begin
        cnt<=cnt+'d1;
        auto_rst_n<='d0;
    end
    else begin
        cnt<=cnt;
        auto_rst_n<=1'd1;
    end
end

endmodule
/*

//�����ϵ縴λģ��
start_rst_module
    start_rst
(
    .i_sys_clk                         (                          ),//����ʱ��
    .i_rst_in                          (                          ),//��λ
	
    .o_rst_out                         (                          ) //������λ�ź�
);

*/

//��λͬ��
module    reset_sync_module(
    input                               i_sys_clk                  ,//ͬ��ʱ��
    input                               i_rst_n                    ,//��ͬ���첽��λ�ź�
    output                              o_sync_rst                  //ͬ����λ�ź�
);

(* ASYNC_REG = "TRUE" *)
reg                                     r_rst1,r_rst2              ;

assign    o_sync_rst = r_rst2;

always@(posedge i_sys_clk or negedge i_rst_n)begin
    if(!i_rst_n)begin
        r_rst1    <=    'd0;
        r_rst2    <=    'd0;
    end else begin
        r_rst1    <=    i_rst_n;
        r_rst2    <=    r_rst1;
    end
end

endmodule
/*

//���ø�λͬ��ģ��
reset_sync_module rst_sync(
    .i_sys_clk                         (                          ),//ͬ��ʱ��
    .i_rst_n                           (                          ),//��ͬ���첽��λ�ź�
    .o_sync_rst                        (                          ) //ͬ����λ�ź�
);

*/

//��bit��ʱ��ͬ������ʱ��
module    slow2fast_sync_module(
    input                               i_signal                   ,//��ͬ���źţ���ʱ��
    input                               i_clk_fast                 ,//��ʱ����
    output                              o_signal                    //���ͬ����ɵ��ź�
);

(* ASYNC_REG = "TRUE" *)
reg                                     r_s1,r_s2                  ;

assign    o_signal    =    r_s2;

always@(posedge i_clk_fast)begin
    r_s1    <=    i_signal;
    r_s2    <=    r_s1;
end

endmodule
/*

//���õ�bit��ʱ��ͬ������ʱ��ģ��
slow2fast_sync_module s2f_sync(
    .i_signal                          (                          ),//��ͬ���źţ���ʱ��
    .i_clk_fast                        (                          ),//��ʱ����
    .o_signal                          (                          ) //���ͬ����ɵ��ź�
);

*/

//��bit��ʱ��ͬ������ʱ��
module    fast2slow_sync_module(
    input                               i_clk_fast                 ,//��ʱ��
    input                               i_signal                   ,//
    input                               i_clk_slow                 ,//
    output                              o_signal                    //
);
wire                                    r_pos                      ;
(* ASYNC_REG = "TRUE" *)
reg                                     r_d1,r_d2                  ;

assign    r_pos = i_signal|r_d1|r_d2;

always@(posedge i_clk_fast)begin
    r_d1    <=    i_signal;
    r_d2    <=    r_d1;
end

(* ASYNC_REG = "TRUE" *)
reg                                     r_p1,r_p2                  ;

assign    o_signal = r_p2;

always@(posedge i_clk_slow)begin
    r_p1    <=    i_signal;
    r_p2    <=    r_p1;
end

endmodule

//������
module    beat_it_twice(
    input                               i_sys_clk                  ,
    input                               i_signal                   ,
    output                              o_signal_delay2             
);

(* ASYNC_REG = "TRUE" *)
reg                                     r_rst1,r_rst2              ;

assign    o_signal_delay2 = r_rst2;

always@(posedge i_sys_clk)begin
    r_rst1    <=    i_signal;
    r_rst2    <=    r_rst1;
end

endmodule