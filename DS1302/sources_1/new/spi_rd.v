`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/29 12:04:42
// Design Name: 
// Module Name: spi_rd
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

//读模块
module spi_rd(
	input					sys_clk			,		//1MHz
	input					rd_start_flag	,		
	input		[7:0]		control_data	,
	output	reg [7:0]		reg_data		,		//读出的值
	input					rst				,
	
	output					inout_en		,
	output	reg				sclk			,		//0.5MHz
	output	reg				wr_data			,
	input					rtc_in			,
	output	reg				ce				,
	output					rd_done
);
//---------------------------------------------------------------------
// wires
//---------------------------------------------------------------------

//---------------------------------------------------------------------
// regs
//---------------------------------------------------------------------
	reg	  		[5:0]		cnt_clk;                         //计数器
	reg	  		[4:0]		cnt_bit;                         //计数器
	reg   		[2:0]		state;                           //状态机
//---------------------------------------------------------------------
// 参数
//---------------------------------------------------------------------
    localparam	IDLE 		= 1'd0;
	localparam	READ		= 1'd1;
//---------------------------------------------------------------------
// 主体
//---------------------------------------------------------------------
assign inout_en = (cnt_clk>=6'd4&&cnt_clk<=6'd22);

always@(posedge sys_clk or negedge rst)begin
	if(!rst)
		state<=IDLE;
	else begin
		case(state)
			IDLE:begin
				if(rd_start_flag)               			//系统给出开始信号后，进入写状态
					state<=READ;                   				
				else                                				 
					state<=state;                   				 
				end                        						
			READ:begin												 
				if(cnt_clk==6'd45)begin						//ce拉高后写完成，跳至空闲状态
					state<=IDLE;
				end
				else                                 	
					state<=state;                    	
				end                          	
			default:state<=IDLE;                     	
		endcase	
	end	
end	

always@(posedge sys_clk or negedge rst)begin
	if(!rst)
		cnt_clk<=6'd0;
	else if(state!=IDLE)
		cnt_clk<=cnt_clk+6'd1;
	else
		cnt_clk<=6'd0;
end

always@(posedge sys_clk or negedge rst)begin
	if(!rst)
		ce<=1'd0;
	else if(state!=IDLE)
		ce<=1'd1;
	else if(state==IDLE)
		ce<=1'd0;
	else
		ce<=ce;
end

always@(posedge sys_clk or negedge rst)begin		 				//配置sclk
	if(!rst)	
		sclk<=1'd0;	
	else if(cnt_clk>=6'd7&&cnt_clk<6'd39)	
		sclk<=~sclk;	
	else
		sclk<=1'd0;	
end	

always@(posedge sys_clk or negedge rst)begin
	if(!rst)
		cnt_bit<=5'd0;
	else begin
		case(cnt_clk)
			6'd6 :cnt_bit<=cnt_bit+5'd1;
			6'd8 :cnt_bit<=cnt_bit+5'd1;
			6'd10:cnt_bit<=cnt_bit+5'd1;
			6'd12:cnt_bit<=cnt_bit+5'd1;
			6'd14:cnt_bit<=cnt_bit+5'd1;
			6'd16:cnt_bit<=cnt_bit+5'd1;
			6'd18:cnt_bit<=cnt_bit+5'd1;
			6'd20:cnt_bit<=cnt_bit+5'd1;
			6'd22:cnt_bit<=cnt_bit+5'd1;
			6'd24:cnt_bit<=cnt_bit+5'd1;
			6'd26:cnt_bit<=cnt_bit+5'd1;
			6'd28:cnt_bit<=cnt_bit+5'd1;
			6'd30:cnt_bit<=cnt_bit+5'd1;
			6'd32:cnt_bit<=cnt_bit+5'd1;
			6'd34:cnt_bit<=cnt_bit+5'd1;
			6'd36:cnt_bit<=cnt_bit+5'd1;
			6'd38:cnt_bit<=5'd0;
			default:cnt_bit<=cnt_bit;
		endcase
	end
end

always@(posedge sys_clk or negedge rst)begin                        //前8bit配置地址等信息
	if(!rst)
		wr_data<=1'd0;
	else begin
		case(cnt_clk)
			6'd6 :wr_data<=control_data[0];
			6'd8 :wr_data<=control_data[1];
			6'd10:wr_data<=control_data[2];
			6'd12:wr_data<=control_data[3];
			6'd14:wr_data<=control_data[4];
			6'd16:wr_data<=control_data[5];
			6'd18:wr_data<=control_data[6];
			6'd20:wr_data<=control_data[7];
			6'd22:wr_data<=1'd0;
			default:wr_data<=wr_data;
		endcase
	end
end

always@(posedge sys_clk or negedge rst)begin                        //后8bit存储IC回应的数据
	if(!rst)
		reg_data<=8'd0;
	else begin
		case(cnt_clk)
			6'd23:reg_data[0]<=rtc_in;
			6'd25:reg_data[1]<=rtc_in;
			6'd27:reg_data[2]<=rtc_in;
			6'd29:reg_data[3]<=rtc_in;
			6'd31:reg_data[4]<=rtc_in;
			6'd33:reg_data[5]<=rtc_in;
			6'd35:reg_data[6]<=rtc_in;
			6'd37:reg_data[7]<=rtc_in;
			default:reg_data<=reg_data;
		endcase
	end
end

signle_pluse wr_done_start(
	.clk		(sys_clk)	,
	.rst		(rst)		,
	.signal_in	(~ce)		,
	.pluse_out	(rd_done)
);

endmodule