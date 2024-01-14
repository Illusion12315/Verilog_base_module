//дģ��
module spi_wr(
	input					sys_clk			,		//1MHz
	input					wr_start_flag	,		//д��ʼ��־
	input	[7:0]			control_data	,       //д��ַ�������ֽ�
	input	[7:0]			reg_data		,       //д�����ֽ�
	input					rst				,       //
	
	output					inout_en		,       //��̬�ſ���
	output	reg				sclk			,		//0.5MHz
	output	reg				wr_data			,       //д������
	output	reg				ce              ,       //Ƭѡ
	output	reg				now_wr			,       //��ʾϵͳ����ִ��д���������ܽ�����������
	output					wr_done
);
//---------------------------------------------------------------------
// regs
//---------------------------------------------------------------------
	reg	  		[5:0]		cnt_clk;                         //������
	reg	  		[4:0]		cnt_bit;                         //������
	reg   		[2:0]		state;                           //״̬��
//---------------------------------------------------------------------
// ����
//---------------------------------------------------------------------
    localparam	IDLE 		= 1'd0;	
	localparam	WRITE		= 1'd1;
//---------------------------------------------------------------------
// ����
//---------------------------------------------------------------------
assign inout_en = (cnt_clk>=6'd4&&cnt_clk<=6'd42);			//������̬�ſ���

always@(posedge sys_clk or negedge rst)begin                //��ʾϵͳ����ִ��д���������ܽ�����������
	if(!rst)
		now_wr<=1'b0;
	else if(wr_start_flag)
		now_wr<=1'b1;
	else if(state==IDLE)
		now_wr<=1'b0;
	else
		now_wr<=now_wr;
end

always@(posedge sys_clk or negedge rst)begin
	if(!rst)
		state<=IDLE;
	else begin
		case(state)
			IDLE:begin
				if(wr_start_flag)               			//ϵͳ������ʼ�źź󣬽���д״̬
					state<=WRITE;                   				
				else                                				 
					state<=state;                   				 
				end                        						
			WRITE:begin												 
				if(cnt_clk==6'd45)begin						//ce���ߺ�д��ɣ���������״̬
					state<=IDLE;
				end
				else                                 	
					state<=state;                    	
				end                          	
			default:state<=IDLE;                     	
		endcase	
	end	
end	

always@(posedge sys_clk or negedge rst)begin               //����ʱ�Ӽ�����
	if(!rst)
		cnt_clk<=6'd0;
	else if(state!=IDLE)
		cnt_clk<=cnt_clk+6'd1;
	else
		cnt_clk<=6'd0;
end

always@(posedge sys_clk or negedge rst)begin               //�л�״̬��Ƭѡ����
	if(!rst)
		ce<=1'd0;
	else if(state!=IDLE)
		ce<=1'd1;
	else if(state==IDLE)
		ce<=1'd0;
	else
		ce<=ce;
end

always@(posedge sys_clk or negedge rst)begin		 	   //����sclk
	if(!rst)	
		sclk<=1'd0;	
	else if(cnt_clk>=6'd7&&cnt_clk<6'd39)	
		sclk<=~sclk;	
	else
		sclk<=1'd0;	
end	

always@(posedge sys_clk or negedge rst)begin               //����bit������
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

always@(posedge sys_clk or negedge rst)begin              //����д������
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
			6'd22:wr_data<=reg_data[0];
			6'd24:wr_data<=reg_data[1];
			6'd26:wr_data<=reg_data[2];
			6'd28:wr_data<=reg_data[3];
			6'd30:wr_data<=reg_data[4];
			6'd32:wr_data<=reg_data[5];
			6'd34:wr_data<=reg_data[6];
			6'd36:wr_data<=reg_data[7];
			6'd38:wr_data<=1'd0;
			default:cnt_bit<=cnt_bit;
		endcase
	end
end

signle_pluse wr_done_start(
	.clk		(sys_clk)	,
	.rst		(rst)		,
	.signal_in	(~ce)		,
	.pluse_out	(wr_done)
);

endmodule