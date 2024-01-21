`timescale 1 ns / 1 ps

module s_axi_lite_myself #(
    parameter                           REG_NUM = 4                ,
    parameter                           C_S_AXI_DATA_WIDTH = 32    ,// Width of S_AXI data bus
    parameter                           C_S_AXI_ADDR_WIDTH = 8      // Width of S_AXI address bus
) (
    //-------------------------customrize---------------------------//
    // output wire                         sw_reset_n                 ,
    //-----------------------axi lite interface---------------------//
    input  wire                         S_AXI_ACLK                 ,// Global Clock Signal
    input  wire                         S_AXI_ARESETN              ,// Global Reset Signal. This Signal is Active LOW

    input  wire        [C_S_AXI_ADDR_WIDTH-1 : 0]S_AXI_AWADDR               ,// Write address (issued by master, acceped by Slave)
    input  wire        [   2:0]         S_AXI_AWPROT               ,// Write channel Protection type. This signal indicates the privilege and security level of the transaction, and whether the transaction is a data access or an instruction access. 
    input  wire                         S_AXI_AWVALID              ,// Write address valid. This signal indicates that the master signaling valid write address and control information.
    output wire                         S_AXI_AWREADY              ,// Write address ready. This signal indicates that the slave is ready to accept an address and associated control signals.

    input  wire        [C_S_AXI_DATA_WIDTH-1 : 0]S_AXI_WDATA                ,// Write data (issued by master, acceped by Slave) 
    input  wire        [(C_S_AXI_DATA_WIDTH/8)-1 : 0]S_AXI_WSTRB                ,// Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bits of the write data bus.
    input  wire                         S_AXI_WVALID               ,// Write valid. This signal indicates that valid write  data and strobes are available.
    output wire                         S_AXI_WREADY               ,// Write ready. This signal indicates that the slave  can accept the write data.

    output wire        [   1:0]         S_AXI_BRESP                ,// Write response. This signal indicates the status of the write transaction.
    output wire                         S_AXI_BVALID               ,// Write response valid. This signal indicates that the channel is signaling a valid write response.
    input  wire                         S_AXI_BREADY               ,// Response ready. This signal indicates that the master can accept a write response.

    input  wire        [C_S_AXI_ADDR_WIDTH-1 : 0]S_AXI_ARADDR               ,// Read address (issued by master, acceped by Slave)
    input  wire        [   2:0]         S_AXI_ARPROT               ,// Protection type. This signal indicates the privilege and security level of the transaction, and whether the transaction is a data access or an instruction access.
    input  wire                         S_AXI_ARVALID              ,// Read address valid. This signal indicates that the channel is signaling valid read address and control information.
    output wire                         S_AXI_ARREADY              ,// Read address ready. This signal indicates that the slave is ready to accept an address and associated control signals.

    output wire        [C_S_AXI_DATA_WIDTH-1 : 0]S_AXI_RDATA                ,// Read data (issued by slave)
    output wire        [   1:0]         S_AXI_RRESP                ,// Read response. This signal indicates the status of the read transfer.
    output wire                         S_AXI_RVALID               ,// Read valid. This signal indicates that the channel is signaling the required read data.
    input  wire                         S_AXI_RREADY                // Read ready. This signal indicates that the master can accept the read data and response information.
    );
// ********************************************************************************** // 
//---------------------------------------------------------------------
// regs
//---------------------------------------------------------------------
reg                    [C_S_AXI_DATA_WIDTH-1:0]ram_reg_r[0:REG_NUM-1];

reg                                     axi_awready_r              ;
reg                                     axi_wready_r               ;
reg                                     axi_bvalid_r               ;
reg                                     axi_arready_r              ;
reg                                     axi_rvalid_r               ;

integer i;

assign S_AXI_BRESP = 2'b00;                                         // 'OKAY' response work error responses in future
assign S_AXI_RRESP = 2'b00;                                         // 'OKAY' response work error responses in future
// ********************************************************************************** // 
//---------------------------------------------------------------------
// handshakes
//---------------------------------------------------------------------
reg                                     aw_handshake_done          ;
reg                                     w_handshake_done           ;

assign S_AXI_AWREADY = axi_awready_r;
assign S_AXI_WREADY = axi_wready_r;
assign S_AXI_BVALID = axi_bvalid_r;
assign S_AXI_ARREADY = axi_arready_r;
assign S_AXI_RVALID = axi_rvalid_r;
//------------------------------
// write channel
//------------------------------
// define aw_ready
always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
    if(!S_AXI_ARESETN)
        axi_awready_r <= 'd0;
    else if (S_AXI_AWVALID && ~axi_awready_r)
        axi_awready_r <= 'd1;
    else
        axi_awready_r <= 'd0;
end
// define w_ready
always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
    if(!S_AXI_ARESETN)
        axi_wready_r <= 'd0;
    else if (S_AXI_WVALID && ~axi_wready_r)
        axi_wready_r <= 'd1;
    else
        axi_wready_r <= 'd0;
end
// define aw_handshake_done
always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
    if(!S_AXI_ARESETN)
        aw_handshake_done <= 'd0;
    else if (axi_bvalid_r && S_AXI_BREADY)
        aw_handshake_done <= 'd0;
    else if (axi_awready_r && S_AXI_AWVALID)
        aw_handshake_done <= 'd1;
    else
        aw_handshake_done <= aw_handshake_done;
end
// define w_handshake_done
always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
    if(!S_AXI_ARESETN)
        w_handshake_done <= 'd0;
    else if (axi_bvalid_r && S_AXI_BREADY)
        w_handshake_done <= 'd0;
    else if (axi_wready_r && S_AXI_WVALID)
        w_handshake_done <= 'd1;
    else
        w_handshake_done <= w_handshake_done;
end
// define axi_bvalid_r
always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
    if(!S_AXI_ARESETN)
        axi_bvalid_r <= 'd0;
    else if (aw_handshake_done && w_handshake_done && ~axi_bvalid_r)
        axi_bvalid_r <= 'd1;
    else
        axi_bvalid_r <= 'd0;
end
//------------------------------
// read channel
//------------------------------
reg                                     ar_handshake_done          ;
// define axi_arready_r
always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
    if(!S_AXI_ARESETN)
        axi_arready_r <= 'd0;
    else if (S_AXI_ARVALID && ~axi_arready_r)
        axi_arready_r <= 'd1;
    else
        axi_arready_r <= 'd0;
end
// define ar_handshake_done
always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
    if(!S_AXI_ARESETN)
        ar_handshake_done <= 'd0;
    else if (axi_rvalid_r && S_AXI_RREADY)
        ar_handshake_done <= 'd0;
    else if (axi_arready_r && S_AXI_ARVALID)
        ar_handshake_done <= 'd1;
    else
        ar_handshake_done <= ar_handshake_done;
end
// define axi_rvalid_r
always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
    if(!S_AXI_ARESETN)
        axi_rvalid_r <= 'd0;
    else if (ar_handshake_done && ~axi_rvalid_r)
        axi_rvalid_r <= 'd1;
    else
        axi_rvalid_r <= 'd0;
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// axi_lite to ram_ctrl
//---------------------------------------------------------------------
//------------------------------
// ram read channel
//------------------------------
reg                                     ram_wr_en_r                ;
reg                    [C_S_AXI_ADDR_WIDTH-1 : 0]ram_wr_addr_r              ;
reg                    [C_S_AXI_DATA_WIDTH-1 : 0]ram_wr_data_r              ;
// define wr_addr
always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
    if(!S_AXI_ARESETN)
        ram_wr_addr_r <= 'd0;
    else if (axi_awready_r && S_AXI_AWVALID)
        ram_wr_addr_r <= S_AXI_AWADDR;
    else
        ram_wr_addr_r <= ram_wr_addr_r;
end
// define wr_data
always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
    if(!S_AXI_ARESETN)
        ram_wr_data_r <= 'd0;
    else if (axi_awready_r && S_AXI_AWVALID)
        ram_wr_data_r <= S_AXI_WDATA;
    else
        ram_wr_data_r <= ram_wr_data_r;
end
// define wr_en
always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
    if(!S_AXI_ARESETN)
        ram_wr_en_r <= 'd0;
    else if (S_AXI_BREADY && axi_bvalid_r)
        ram_wr_en_r <= 'd1;
    else
        ram_wr_en_r <= 'd0;
end
//------------------------------
// ram write channel
//------------------------------
wire                                    ram_rd_en_r                ;
reg                    [C_S_AXI_ADDR_WIDTH-1 : 0]ram_rd_addr_r              ;
reg                    [C_S_AXI_DATA_WIDTH-1 : 0]ram_rd_data_r              ;

assign S_AXI_RDATA = ram_rd_data_r;

assign ram_rd_en_r = axi_rvalid_r & S_AXI_RREADY;

always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
    if(!S_AXI_ARESETN)
        ram_rd_addr_r <= 'd0;
    else if (axi_arready_r && S_AXI_ARVALID)
        ram_rd_addr_r <= S_AXI_ARADDR;
    else
        ram_rd_addr_r <= ram_rd_addr_r;
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// reg_file
//---------------------------------------------------------------------
// Write Register File
always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
    if(!S_AXI_ARESETN) begin
        for (i = 0; i<REG_NUM; i=i+1) begin
            ram_reg_r[i] <= 32'd0;
        end
    end
    else if (ram_wr_en_r)
        ram_reg_r[ram_wr_addr_r[C_S_AXI_ADDR_WIDTH-1:2]] <= ram_wr_data_r;
    else begin
        for (i = 0; i<REG_NUM; i=i+1) begin
            ram_reg_r[i] <= ram_reg_r[i];
        end
    end
end
// ********************************************************************************** // 
//---------------------------------------------------------------------
// Start of Register File Code
//---------------------------------------------------------------------    
// 0x00(DWORD)/0x00(Byte)
// assign sw_reset_n = !ram_reg_r[0][0];
// 0x01(DWORD)/0x04(Byte)
// 0x02(DWORD)/0x08(Byte)
// 0x03(DWORD)/0x0C(Byte)
// 0x04(DWORD)/0x10(Byte)
// 0x05(DWORD)/0x14(Byte)
// 0x06(DWORD)/0x18(Byte)





// Read Register File
always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
    if(!S_AXI_ARESETN)
        ram_rd_data_r <= 'd0;
    else if (ram_rd_addr_r[C_S_AXI_ADDR_WIDTH-1:2] < REG_NUM)
        case (ram_rd_addr_r[C_S_AXI_ADDR_WIDTH-1:2])
            'd0: ram_rd_data_r <= {32{1'd1}};
            default: ram_rd_data_r <= ram_reg_r[ram_rd_addr_r[C_S_AXI_ADDR_WIDTH-1:2]];
        endcase
    else
        ram_rd_data_r <= 32'hAAAA_5555;
end
endmodule