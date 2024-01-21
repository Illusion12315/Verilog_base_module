`timescale 1 ns / 1 ps

module axi_slave
#(
    //�û�����


    //AXI�ӿڲ���
		
    parameter                           integer C_S_AXI_ID_WIDTH	= 1,// Width of ID for for write address, write data, read address and read data
    parameter                           integer C_S_AXI_DATA_WIDTH	= 32,// Width of S_AXI data bus
    parameter                           integer C_S_AXI_ADDR_WIDTH	= 6,// Width of S_AXI address bus
    parameter                           integer C_S_AXI_AWUSER_WIDTH= 0,// Width of optional user defined signal in write address channel
    parameter                           integer C_S_AXI_ARUSER_WIDTH= 0,// Width of optional user defined signal in read address channel
    parameter                           integer C_S_AXI_WUSER_WIDTH	= 0,// Width of optional user defined signal in write data channel
    parameter                           integer C_S_AXI_RUSER_WIDTH	= 0,// Width of optional user defined signal in read data channel
    parameter                           integer C_S_AXI_BUSER_WIDTH	= 0 // Width of optional user defined signal in write response channel
)
(
//�û��ź�



//ȫ���ź�
    input  wire                         S_AXI_ACLK                 ,// Global Clock Signal
    input  wire                         S_AXI_ARESETN              ,// Global Reset Signal. This Signal is Active LOW
//д��ַͨ��
    input  wire        [C_S_AXI_ID_WIDTH-1 : 0]S_AXI_AWID                 ,// Write Address ID
    input  wire        [C_S_AXI_ADDR_WIDTH-1 : 0]S_AXI_AWADDR               ,// Write address
    input  wire        [   7:0]         S_AXI_AWLEN                ,// Burst length. The burst length gives the exact number of transfers in a burst
    input  wire        [   2:0]         S_AXI_AWSIZE               ,// Burst size. This signal indicates the size of each transfer in the burst
    input  wire        [   1:0]         S_AXI_AWBURST              ,// Burst type. The burst type and the size information, determine how the address for each transfer within the burst is calculated.
    input  wire                         S_AXI_AWLOCK               ,// Lock type. Provides additional information about the atomic characteristics of the transfer.
    input  wire        [   3:0]         S_AXI_AWCACHE              ,// Memory type. This signal indicates how transactions are required to progress through a system.
    input  wire        [   2:0]         S_AXI_AWPROT               ,// Protection type. This signal indicates the privilege and security level of the transaction, and whether the transaction is a data access or an instruction access.
    input  wire        [   3:0]         S_AXI_AWQOS                ,// Quality of Service, QoS identifier sent for each write transaction.
    input  wire        [   3:0]         S_AXI_AWREGION             ,// Region identifier. Permits a single physical interface on a slave to be used for multiple logical interfaces.
    input  wire        [C_S_AXI_AWUSER_WIDTH-1 : 0]S_AXI_AWUSER               ,// Optional User-defined signal in the write address channel.
    input  wire                         S_AXI_AWVALID              ,// Write address valid. This signal indicates that the channel is signaling valid write address and control information.
    output wire                         S_AXI_AWREADY              ,// Write address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
//д����ͨ��
    input  wire        [C_S_AXI_DATA_WIDTH-1 : 0]S_AXI_WDATA                ,// Write Data
    input  wire        [(C_S_AXI_DATA_WIDTH/8)-1 : 0]S_AXI_WSTRB                ,// Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bits of the write data bus.
    input  wire                         S_AXI_WLAST                ,// Write last. This signal indicates the last transfer in a write burst.
    input  wire        [C_S_AXI_WUSER_WIDTH-1 : 0]S_AXI_WUSER                ,// Optional User-defined signal in the write data channel.
    input  wire                         S_AXI_WVALID               ,// Write valid. This signal indicates that valid write data and strobes are available.
    output wire                         S_AXI_WREADY               ,// Write ready. This signal indicates that the slave can accept the write data.
//д��Ӧͨ��
    output wire        [C_S_AXI_ID_WIDTH-1 : 0]S_AXI_BID                  ,// Response ID tag. This signal is the ID tag of the write response.
    output wire        [   1:0]         S_AXI_BRESP                ,// Write response. This signal indicates the status of the write transaction.
    output wire        [C_S_AXI_BUSER_WIDTH-1 : 0]S_AXI_BUSER                ,// Optional User-defined signal in the write response channel.
    output wire                         S_AXI_BVALID               ,// Write response valid. This signal indicates that the channel is signaling a valid write response.
    input  wire                         S_AXI_BREADY               ,// Response ready. This signal indicates that the master can accept a write response.
//����ַͨ��
    input  wire        [C_S_AXI_ID_WIDTH-1 : 0]S_AXI_ARID                 ,// Read address ID. This signal is the identification tag for the read address group of signals.
    input  wire        [C_S_AXI_ADDR_WIDTH-1 : 0]S_AXI_ARADDR               ,// Read address. This signal indicates the initial address of a read burst transaction.
    input  wire        [   7:0]         S_AXI_ARLEN                ,// Burst length. The burst length gives the exact number of transfers in a burst
    input  wire        [   2:0]         S_AXI_ARSIZE               ,// Burst size. This signal indicates the size of each transfer in the burst
    input  wire        [   1:0]         S_AXI_ARBURST              ,// Burst type. The burst type and the size information, determine how the address for each transfer within the burst is calculated.
    input  wire                         S_AXI_ARLOCK               ,// Lock type. Provides additional information about the atomic characteristics of the transfer.
    input  wire        [   3:0]         S_AXI_ARCACHE              ,// Memory type. This signal indicates how transactions are required to progress through a system.
    input  wire        [   2:0]         S_AXI_ARPROT               ,// Protection type. This signal indicates the privilege and security level of the transaction, and whether the transaction is a data access or an instruction access.
    input  wire        [   3:0]         S_AXI_ARQOS                ,// Quality of Service, QoS identifier sent for each read transaction.
    input  wire        [   3:0]         S_AXI_ARREGION             ,// Region identifier. Permits a single physical interface on a slave to be used for multiple logical interfaces.
    input  wire        [C_S_AXI_ARUSER_WIDTH-1 : 0]S_AXI_ARUSER               ,// Optional User-defined signal in the read address channel.
    input  wire                         S_AXI_ARVALID              ,// Write address valid. This signal indicates that the channel is signaling valid read address and control information.
    output wire                         S_AXI_ARREADY              ,// Read address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
//������ͨ��
    output wire        [C_S_AXI_ID_WIDTH-1 : 0]S_AXI_RID                  ,// Read ID tag. This signal is the identification tag for the read data group of signals generated by the slave.
    output wire        [C_S_AXI_DATA_WIDTH-1 : 0]S_AXI_RDATA                ,// Read Data
    output wire        [   1:0]         S_AXI_RRESP                ,// Read response. This signal indicates the status of the read transfer.
    output wire                         S_AXI_RLAST                ,// Read last. This signal indicates the last transfer in a read burst.
    output wire        [C_S_AXI_RUSER_WIDTH-1 : 0]S_AXI_RUSER                ,// Optional User-defined signal in the read address channel.
    output wire                         S_AXI_RVALID               ,// Read valid. This signal indicates that the channel is signaling the required read data.
    input  wire                         S_AXI_RREADY                // Read ready. This signal indicates that the master can accept the read data and response information.         
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// �Ĵ�������
//---------------------------------------------------------------------
//д��ַͨ��
reg                                     awready_r                  ;
//д����ͨ��
reg                                     wready_r                   ;
//д��Ӧͨ��
reg                    [   1:0]         bresp_r                    ;
reg                                     bvalid_r                   ;
//����ַͨ��
reg                                     arready_r                  ;
reg                    [   1:0]         arbrust_r                  ;
reg                    [   7:0]         arlen_r                    ;
reg                    [   2:0]         arsize_r                   ;
//������ͨ��
reg                    [C_S_AXI_DATA_WIDTH-1 : 0]rdata_r                    ;
reg                                     rlast_r                    ;
reg                                     rvalid_r                   ;
reg                    [   1:0]         rresp_r                    ;
//�û��ź�
reg                                     awaddr_done = 'd0          ;
reg                                     wdata_done = 'd0           ;
reg                    [   7:0]         read_cnt                   ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// ����߼�
//---------------------------------------------------------------------
//д��ַͨ��
assign S_AXI_AWREADY    = awready_r;
//д����ͨ��
assign S_AXI_WREADY    = wready_r;
//д��Ӧͨ��
assign S_AXI_BRESP    = bresp_r;
assign S_AXI_BUSER    = 'd0;
assign S_AXI_BVALID    = bvalid_r;
assign S_AXI_BID = S_AXI_AWID;
//����ַͨ��
assign S_AXI_ARREADY    = arready_r;
//������ͨ��
assign S_AXI_RDATA    = rdata_r;
assign S_AXI_RRESP    = rresp_r;
assign S_AXI_RLAST    = rlast_r;
assign S_AXI_RUSER    = 'd0;
assign S_AXI_RVALID    = rvalid_r;
assign S_AXI_RID = S_AXI_ARID;
//�û��ӿ�

// ********************************************************************************** // 
//---------------------------------------------------------------------
// ʱ���߼�
//---------------------------------------------------------------------
	//--------------------
	//д��ַͨ��
	//--------------------
//����awready_r
always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
    if (!S_AXI_ARESETN) begin
        awready_r<='d0;
    end
    else if (S_AXI_AWVALID) begin
        awready_r<='d1;
    end
    else
        awready_r<='d0;
end
//����awaddr_done
always@(*)begin
    if (bvalid_r) begin
        awaddr_done<='d0;
    end
    else if(awready_r && S_AXI_AWVALID)
        awaddr_done<='d1;
    else
        awaddr_done<=awaddr_done;
end
	//--------------------
	//д����ͨ��
	//--------------------
//����wready_r
always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
    if (!S_AXI_ARESETN) begin
        wready_r<='d0;
    end
    else if (S_AXI_WVALID) begin
        wready_r<='d0;
    end
    else
        wready_r<='d1;
end
//����wdata_done
always@(*)begin
    if (bvalid_r) begin
        wdata_done<='d0;
    end
    else if(wready_r && S_AXI_WVALID && S_AXI_WLAST)
        wdata_done<='d1;
    else
        wdata_done<=wdata_done;
end
	//--------------------
	//д��Ӧͨ��
	//--------------------
//����bvalid_r
always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
    if(!S_AXI_ARESETN)
        bvalid_r<='d0;
    else if(bvalid_r && S_AXI_BREADY)
        bvalid_r<='d0;
    else if(wdata_done && awaddr_done)
        bvalid_r<='d1;
    else
        bvalid_r<=bvalid_r;
end
	//--------------------
	//����ַͨ��
	//--------------------
//����arready_r
always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
    if (!S_AXI_ARESETN) begin
        arready_r<='d0;
    end
    else if (S_AXI_ARVALID) begin
        arready_r<='d1;
    end
    else
        arready_r<='d0;
end
	//--------------------
	//������ͨ��
	//--------------------
//����rvalid_r
always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
    if(!S_AXI_ARESETN)
        rvalid_r<='d0;
    else if (rvalid_r && rlast_r && S_AXI_RREADY) begin
        rvalid_r<='d0;
    end
    else if (S_AXI_RREADY) begin
        rvalid_r<='d1;
    end
    else
        rvalid_r<=rvalid_r;
end
//����rlast_r
always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
    if(!S_AXI_ARESETN)
        rlast_r<='d0;
    else if (read_cnt == arlen_r-'d1) begin
        rlast_r<='d1;
    end
    else
        rlast_r<='d0;
end
//����read_cnt
always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
    if(!S_AXI_ARESETN)
        read_cnt<='d0;
    else if(rlast_r)
        read_cnt<='d0;
    else if(rvalid_r && S_AXI_RREADY)
        read_cnt<=read_cnt+'d1;
    else
        read_cnt<=read_cnt;
end
//����rresp_r

//����rdata_r
endmodule