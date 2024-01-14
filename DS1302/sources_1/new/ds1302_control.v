`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/01 09:15:26
// Design Name: 
// Module Name: ds1302_control
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


module ds1302_control(
    input                       sys_clk             ,           //
    input                       sys_rst             ,           //
	input						vio_wr_start_flag	,           //vio������д����
	input						vio_rd				,           //vio���ƵĶ��źţ�����Ч
	input						wr_done				,           //д��ɱ�־
	input						rd_done				,           //����ɱ�־
	input	[7:0]				years				,           //
	input	[7:0]				months				,           //
	input	[7:0]				dates				,           //
	input	[7:0]				hours				,           //
	input	[7:0]				minutes				,           //
	input	[7:0]				seconds				,           //
	input   [7:0]               reg_data_out		,           //
	output	reg					first_wr			,           //һ����д�ĵ�һ��
	output	reg					first_rd			,           //һ�������ĵ�һ��
	output	reg		[7:0]		control_data		,           //������Ƶ�ַ
	output	reg		[7:0]		reg_data			,           //���д�ļĴ�������
	output	reg		[7:0]		rd_control_data		,           //���8bit����������
	output	reg		[47:0]		rd_data				            //����������������
    );
//---------------------------------------------------------------------
// regs
//---------------------------------------------------------------------
	reg		[3:0]				i					;
	reg		[3:0]				j					;

always@(posedge sys_clk or negedge sys_rst)begin
	if(!sys_rst)begin
		i<=1'd0;
		control_data<=8'd0;
		first_wr<=1'd0;
	end else if(!vio_rd)begin
		case(i)
			'd0:if(vio_wr_start_flag)
					i<='d1;
				else
					i<=i;
			'd1:begin if(wr_done)begin
					i<=i+'d1;
					first_wr<=1'd0;
				end else begin
					first_wr<=1'd1;
					control_data<=8'h8E;				//��дʹ��
					reg_data<=8'b0000_0001;
					end
				end 
			'd2:begin if(wr_done)begin
					i<=i+'d1;
					first_wr<=1'd0;
				end else begin
					first_wr<=1'd1;
					control_data<=8'h8C;				//д��
					reg_data<=years;
					end
				end
			'd3:begin if(wr_done)begin
					i<=i+'d1;
					first_wr<=1'd0;
				end else begin
					first_wr<=1'd1;
					control_data<=8'h88;				//д��
					reg_data<=months;
					end
				end
			'd4:begin if(wr_done)begin
					i<=i+'d1;
					first_wr<=1'd0;
				end else begin
					first_wr<=1'd1;
					control_data<=8'h86;				//д��
					reg_data<=dates;
					end
				end
			'd5:begin if(wr_done)begin
					i<=i+'d1;
					first_wr<=1'd0;
				end else begin
					first_wr<=1'd1;
					control_data<=8'h84;				//дСʱ
					reg_data<=hours;
					end
				end
			'd6:begin if(wr_done)begin
					i<=i+'d1;
					first_wr<=1'd0;
				end else begin
					first_wr<=1'd1;
					control_data<=8'h82;				//д����
					reg_data<=minutes;
					end
				end
			'd7:begin if(wr_done)begin
					i<=i+'d1;
					first_wr<=1'd0;
				end else begin
					first_wr<=1'd1;
					control_data<=8'h82;				//д��
					reg_data<=seconds;
					end
				end
			'd8:begin if(wr_done)begin
					i<=1'd0;
					first_wr<=1'd0;
				end else begin
					first_wr<=1'd1;
					control_data<=8'h8E;				//�ر�дʹ��
					reg_data<=8'b1000_0000;
					end
				end
			default:i<=i;
		endcase
	end	else
			i<=i;
end

always@(posedge sys_clk or negedge sys_rst)begin
	if(!sys_rst)begin
		j<=1'd0;
		first_rd<=1'd0;
		rd_control_data<=8'd0;
	end else begin
		case(j)
			'd0:if(vio_rd)
					j<='d1;
				else
					j<=j;
			'd1:begin if(rd_done)begin
					j<=j+'d1;
					first_rd<=1'd0;						
					rd_data[47:40]<=reg_data_out;		//����
				end else begin
					first_rd<=1'd1;
					rd_control_data<=8'h8D;				
					end
				end
			'd2:begin if(rd_done)begin
					j<=j+'d1;
					first_rd<=1'd0;
					rd_data[39:32]<=reg_data_out;		//����
				end else begin
					first_rd<=1'd1;
					rd_control_data<=8'h89;				
					end
				end
			'd3:begin if(rd_done)begin
					j<=j+'d1;
					first_rd<=1'd0;
					rd_data[31:24]<=reg_data_out;		//����
				end else begin
					first_rd<=1'd1;
					rd_control_data<=8'h87;				
					end
				end
			'd4:begin if(rd_done)begin
					j<=j+'d1;
					first_rd<=1'd0;
					rd_data[23:16]<=reg_data_out;		//��Сʱ
				end else begin
					first_rd<=1'd1;
					rd_control_data<=8'h85;				
					end
				end
			'd5:begin if(rd_done)begin
					j<=j+'d1;
					first_rd<=1'd0;
					rd_data[15:8]<=reg_data_out;		//������
				end else begin
					first_rd<=1'd1;
					rd_control_data<=8'h83;				
					end
				end
			'd6:begin if(rd_done)begin
					j<=1'd0;
					first_rd<=1'd0;
					rd_data[7:0]<=reg_data_out;			//������
				end else begin
					first_rd<=1'd1;
					rd_control_data<=8'h81;				
					end
				end
			default:j<=j;
		endcase
	end
end

endmodule
