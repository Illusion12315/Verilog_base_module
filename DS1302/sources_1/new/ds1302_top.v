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
	input						sys_clk_in_p		,           //系统时钟
	input						sys_clk_in_n		,           //系统时钟

	output						rtc_ce				,           //片选
	output						rtc_sclk			,           //时钟
	inout						rtc_io                          //输出输出IO
	
	//仿真测试
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
    wire                        inout_en			;           //三态门控制开关
    wire                        rtc_out				;           //IO输出
    wire                        rtc_in				;           //IO输入
	wire						sys_clk				;           //系统时钟，0.5MHz
	wire						sys_clk_in			;           //系统时钟，200MHz
	wire						vio_wr				;           //写VIO
	wire						vio_rd				;           //读VIO
	wire						sys_rst_in			;           //系统复位
	wire						sys_rst				;           //系统复位
	wire						wr_start_flag		;           //写开始标志
	wire						inout_en_wr			;           //写三态门开关
	wire						rtc_ce_wr			;           //写片选
	wire						rtc_sclk_wr			;           //写时钟
	wire						rtc_out_wr			;           //写数据

	wire						rd_start_flag		;           //读开始标志
	wire                        inout_en_rd			;           //读三态门开关
	wire                        rtc_ce_rd			;           //读片选
	wire                        rtc_sclk_rd			;           //读时钟
	wire						rtc_out_rd			;           //读出数据

	wire						now_wr				;           //表示现在是否在写状态
	wire 	[7:0]				reg_data_out		;           //读出的1bit数据转化为8bit数据
	wire						wr_done				;           //vio控制的写信号，高有效
	wire						rd_done				;           //vio控制的读信号，高有效
	wire						vio_wr_start_flag	;           //vio产生的写脉冲
	wire						vio_rd_start_flag	;           //vio产生的读脉冲
	wire	[7:0]				years				;
	wire	[7:0]				months				;
	wire	[7:0]				dates				;
	wire	[7:0]				hours				;
	wire	[7:0]				minutes				;
	wire	[7:0]				seconds				;
	
	wire    [7:0]				control_data	    ;           //输出控制地址
	wire    [7:0]				reg_data		    ;           //输出写的寄存器数据
	wire    [7:0]				rd_control_data	    ;           //输出8bit读到的数据
	wire    [47:0]				rd_data			    ;           //读出的年月日数据
	wire						first_wr            ;           //一连串写的第一个
	wire                        first_rd            ;           //一连串读的第一个
//---------------------------------------------------------------------
// 主体
//---------------------------------------------------------------------
assign	rtc_io = (inout_en)?rtc_out:1'bz;                       //配置三态门
assign	rtc_in = rtc_io;                                        //
assign	sys_rst_in = 1'b1;                                      //配置系统复位

assign	inout_en = (now_wr)?inout_en_wr:inout_en_rd;            //选择读写
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

//产生1MHz系统时钟
divide N_200(
	.clk_in(sys_clk_in),
	.rst(sys_rst),
	
	.clk_out(sys_clk)
);

//上电复位模块
rst rst_start(
	.clk			(sys_clk_in)		,
	.rst_in			(sys_rst_in)		,
	
	.rst_n      	(sys_rst)
);

//产生第一个写脉冲
signle_pluse sign_first_wr(
	.clk			(sys_clk)			,
	.rst			(sys_rst)			,
	.signal_in		(first_wr)			,
	.pluse_out      (wr_start_flag)
);

//产生第一个读脉冲
signle_pluse sign_first_rd(
	.clk			(sys_clk)			,
	.rst			(sys_rst)			,
	.signal_in		(first_rd)			,
	.pluse_out      (rd_start_flag)
);

//产生单个写脉冲
signle_pluse sign_wr(
	.clk			(sys_clk)			,
	.rst			(sys_rst)			,
	.signal_in		(vio_wr)			,
	.pluse_out      (vio_wr_start_flag)
);

//产生单个读脉冲
signle_pluse sign_rd(
	.clk			(sys_clk)			,
	.rst			(sys_rst)			,
	.signal_in		(vio_rd)			,
	.pluse_out      (vio_rd_start_flag)
);

//写模块例化
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

//读模块例化
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

//控制模块例化
ds1302_control control_1302(
	.sys_clk			(sys_clk)               ,
	.sys_rst            (sys_rst)               ,
	.vio_wr_start_flag	(vio_wr_start_flag)		,       //vio产生的写脉冲
	.vio_rd				(vio_rd)				,       //vio控制的读信号，高有效
	.wr_done			(wr_done)				,       //写完成标志
	.rd_done			(rd_done)				,       //读完成标志
	.years				(years)					,
	.months				(months)				,
	.dates				(dates)					,
	.hours				(hours)					,
	.minutes			(minutes)				,
	.seconds			(seconds)               ,
	.reg_data_out	    (reg_data_out)          ,
	.first_wr		    (first_wr)              ,       //一连串写的第一个
	.first_rd		    (first_rd)              ,       //一连串读的第一个
	.control_data	    (control_data)          ,       //输出控制地址
	.reg_data		    (reg_data)              ,       //输出写的寄存器数据
	.rd_control_data	(rd_control_data)       ,       //输出8bit读到的数据
	.rd_data			(rd_data)                       //读出的年月日数据
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
