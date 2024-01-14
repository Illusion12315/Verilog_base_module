`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/29 12:08:15
// Design Name: 
// Module Name: ds1302_top
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


module ds1302_top(
	input						sys_clk_in_p		,           //ϵͳʱ��
	input						sys_clk_in_n		,           //ϵͳʱ��

	output						rtc_ce				,           //Ƭѡ
	output						rtc_sclk			,           //ʱ��
	inout						rtc_io                          //������IO
	
	//�������
	//input						vio_wr				,
	//input						vio_rd				,
	//input	[7:0]				years				,
	//input	[7:0]				months				,
	//input	[7:0]				dates				,
	//input	[7:0]				hours				,
	//input	[7:0]				minutes				,
	//input	[7:0]				seconds				
    );
//---------------------------------------------------------------------
// wires
//---------------------------------------------------------------------
    wire                        inout_en			;           //��̬�ſ��ƿ���
    wire                        rtc_out				;           //IO���
    wire                        rtc_in				;           //IO����
	wire						sys_clk				;           //ϵͳʱ�ӣ�0.5MHz
	wire						sys_clk_in			;           //ϵͳʱ�ӣ�200MHz
	wire						vio_wr				;           //дVIO
	wire						vio_rd				;           //��VIO
	wire						sys_rst_in			;           //ϵͳ��λ
	wire						sys_rst				;           //ϵͳ��λ
	wire						wr_start_flag		;           //д��ʼ��־
	wire						inout_en_wr			;           //д��̬�ſ���
	wire						rtc_ce_wr			;           //дƬѡ
	wire						rtc_sclk_wr			;           //дʱ��
	wire						rtc_out_wr			;           //д����

	wire						rd_start_flag		;           //����ʼ��־
	wire                        inout_en_rd			;           //����̬�ſ���
	wire                        rtc_ce_rd			;           //��Ƭѡ
	wire                        rtc_sclk_rd			;           //��ʱ��
	wire						rtc_out_rd			;           //��������

	wire						now_wr				;           //��ʾ�����Ƿ���д״̬
	wire 	[7:0]				reg_data_out		;           //������1bit����ת��Ϊ8bit����
	wire						wr_done				;           //vio���Ƶ�д�źţ�����Ч
	wire						rd_done				;           //vio���ƵĶ��źţ�����Ч
	wire						vio_wr_start_flag	;           //vio������д����
	wire						vio_rd_start_flag	;           //vio�����Ķ�����
	wire	[7:0]				years				;
	wire	[7:0]				months				;
	wire	[7:0]				dates				;
	wire	[7:0]				hours				;
	wire	[7:0]				minutes				;
	wire	[7:0]				seconds				;
	
	wire    [7:0]				control_data	    ;           //������Ƶ�ַ
	wire    [7:0]				reg_data		    ;           //���д�ļĴ�������
	wire    [7:0]				rd_control_data	    ;           //���8bit����������
	wire    [47:0]				rd_data			    ;           //����������������
	wire						first_wr            ;           //һ����д�ĵ�һ��
	wire                        first_rd            ;           //һ�������ĵ�һ��
//---------------------------------------------------------------------
// ����
//---------------------------------------------------------------------
assign	rtc_io = (inout_en)?rtc_out:1'bz;                       //������̬��
assign	rtc_in = rtc_io;                                        //
assign	sys_rst_in = 1'b1;                                      //����ϵͳ��λ

assign	inout_en = (now_wr)?inout_en_wr:inout_en_rd;            //ѡ���д
assign	rtc_ce = (now_wr)?rtc_ce_wr:rtc_ce_rd;                  //
assign	rtc_sclk = (now_wr)?rtc_sclk_wr:rtc_sclk_rd;            //
assign	rtc_out = (now_wr)?rtc_out_wr:rtc_out_rd;               //

IBUFDS #(
   .DIFF_TERM("FALSE"),       // Differential Termination
   .IBUF_LOW_PWR("TRUE"),     // Low power="TRUE", Highest performance="FALSE" 
   .IOSTANDARD("DEFAULT")     // Specify the input I/O standard
) IBUFDS_inst (
   .O(sys_clk_in),  // Buffer output
   .I(sys_clk_in_p),  // Diff_p buffer input (connect directly to top-level port)
   .IB(sys_clk_in_n) // Diff_n buffer input (connect directly to top-level port)
);

//����1MHzϵͳʱ��
divide N_200(
	.clk_in(sys_clk_in),
	.rst(sys_rst),
	
	.clk_out(sys_clk)
);

//�ϵ縴λģ��
rst rst_start(
	.clk			(sys_clk_in)		,
	.rst_in			(sys_rst_in)		,
	
	.rst_n      	(sys_rst)
);

//������һ��д����
signle_pluse sign_first_wr(
	.clk			(sys_clk)			,
	.rst			(sys_rst)			,
	.signal_in		(first_wr)			,
	.pluse_out      (wr_start_flag)
);

//������һ��������
signle_pluse sign_first_rd(
	.clk			(sys_clk)			,
	.rst			(sys_rst)			,
	.signal_in		(first_rd)			,
	.pluse_out      (rd_start_flag)
);

//��������д����
signle_pluse sign_wr(
	.clk			(sys_clk)			,
	.rst			(sys_rst)			,
	.signal_in		(vio_wr)			,
	.pluse_out      (vio_wr_start_flag)
);

//��������������
signle_pluse sign_rd(
	.clk			(sys_clk)			,
	.rst			(sys_rst)			,
	.signal_in		(vio_rd)			,
	.pluse_out      (vio_rd_start_flag)
);

//дģ������
spi_wr wr_ex(
	.sys_clk			(sys_clk)		,		//1MHz
	.wr_start_flag		(wr_start_flag)	,		
	.control_data		(control_data)	,
	.reg_data			(reg_data)		,
	.rst				(sys_rst)		,
	
	.inout_en			(inout_en_wr)	,
	.sclk				(rtc_sclk_wr)	,		//0.5MHz
	.wr_data			(rtc_out_wr)	,
	.ce					(rtc_ce_wr)		,
	.now_wr				(now_wr)		,
	.wr_done			(wr_done)
);

//��ģ������
spi_rd rd_ex(
	.sys_clk			(sys_clk)				,		//1MHz
	.rd_start_flag		(rd_start_flag)			,		
	.control_data		(rd_control_data)		,
	.reg_data			(reg_data_out)			,
	.rst				(sys_rst)				,
	
	.inout_en			(inout_en_rd)			,
	.sclk				(rtc_sclk_rd)			,		//0.5MHz
	.wr_data			(rtc_out_rd)			,
	.rtc_in				(rtc_in)				,
	.ce					(rtc_ce_rd)				,
	.rd_done			(rd_done)
);

//����ģ������
ds1302_control control_1302(
	.sys_clk			(sys_clk)               ,
	.sys_rst            (sys_rst)               ,
	.vio_wr_start_flag	(vio_wr_start_flag)		,       //vio������д����
	.vio_rd				(vio_rd)				,       //vio���ƵĶ��źţ�����Ч
	.wr_done			(wr_done)				,       //д��ɱ�־
	.rd_done			(rd_done)				,       //����ɱ�־
	.years				(years)					,
	.months				(months)				,
	.dates				(dates)					,
	.hours				(hours)					,
	.minutes			(minutes)				,
	.seconds			(seconds)               ,
	.reg_data_out	    (reg_data_out)          ,
	.first_wr		    (first_wr)              ,       //һ����д�ĵ�һ��
	.first_rd		    (first_rd)              ,       //һ�������ĵ�һ��
	.control_data	    (control_data)          ,       //������Ƶ�ַ
	.reg_data		    (reg_data)              ,       //���д�ļĴ�������
	.rd_control_data	(rd_control_data)       ,       //���8bit����������
	.rd_data			(rd_data)                       //����������������
);

vio_0 shangweiji (
	.clk(sys_clk_in),                // input wire clk
	.probe_in0(rd_data),    // input wire [47 : 0] probe_in0
	.probe_out0(vio_rd),  // output wire [0 : 0] probe_out0
	.probe_out1(vio_wr),  // output wire [0 : 0] probe_out1
	.probe_out2(years),  // output wire [7 : 0] probe_out2
	.probe_out3(months),  // output wire [7 : 0] probe_out3
	.probe_out4(dates),  // output wire [7 : 0] probe_out4
	.probe_out5(hours),  // output wire [7 : 0] probe_out5
	.probe_out6(minutes),  // output wire [7 : 0] probe_out6
	.probe_out7(seconds)  // output wire [7 : 0] probe_out7
);


ila_0 ila_top (
	.clk(sys_clk_in), // input wire clk


	.probe0(rtc_ce), // input wire [0:0]  probe0  
	.probe1(rtc_sclk), // input wire [0:0]  probe1 
	.probe2(rd_start_flag), // input wire [0:0]  probe2 
	.probe3(rtc_io), // input wire [0:0]  probe3 
	.probe4(now_wr), // input wire [0:0]  probe4 
	.probe5(wr_start_flag), // input wire [0:0]  probe5 
	.probe6(control_data), // input wire [7:0]  probe6 
	.probe7(reg_data_out) // input wire [7:0]  probe7
);

endmodule
