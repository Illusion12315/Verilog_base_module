`timescale 1 ns / 1 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: chen xiongzhi
// 
// Create Date: 2024/3/3
// Design Name: 
// Module Name: m_axi2ram_rd_and_wr
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
module m_axi2ram_rd_and_wr #(
    parameter                           C_M_TARGET_SLAVE_BASE_ADDR= 32'h40000000,// Base address of targeted slave
    parameter                           C_M_AXI_BURST_LEN         = 16,// Burst Length. Supports 1, 2, 4, 8, 16, 32, 64, 128, 256 burst lengths
    parameter                           C_M_AXI_ID_WIDTH          = 1,// Thread ID Width
    parameter                           C_M_AXI_ADDR_WIDTH        = 32,// Width of Address Bus
    parameter                           C_M_AXI_DATA_WIDTH        = 32,// Width of Data Bus
    parameter                           C_M_AXI_AWUSER_WIDTH      = 0,// Width of User Write Address Bus
    parameter                           C_M_AXI_ARUSER_WIDTH      = 0,// Width of User Read Address Bus
    parameter                           C_M_AXI_WUSER_WIDTH       = 0,// Width of User Write Data Bus
    parameter                           C_M_AXI_RUSER_WIDTH       = 0,// Width of User Read Data Bus
    parameter                           C_M_AXI_BUSER_WIDTH       = 0// Width of User Response Bus
) (
    //-------------------------customrize---------------------------//
    input                               wr_start_i                 ,
    input              [C_M_AXI_ADDR_WIDTH-1: 0]wr_addr_i          ,
    input              [C_M_AXI_DATA_WIDTH-1: 0]wr_data_i          ,
    output                              wr_data_respond_o          ,
    output                              wr_burst_done_o            ,

    input                               rd_start_i                 ,
    input              [C_M_AXI_ADDR_WIDTH-1: 0]rd_addr_i          ,
    output             [C_M_AXI_DATA_WIDTH-1: 0]rd_data_o          ,
    output                              rd_data_valid_o            ,
    output                              rd_burst_done_o            ,
    //----------------------m AXI MM interface---------------------//
    input  wire                         M_AXI_ACLK                 ,// Global Clock Signal.
    input  wire                         M_AXI_ARESETN              ,// Global Reset Singal. This Signal is Active Low
    // aw channel(write address)
    output wire        [C_M_AXI_ID_WIDTH-1: 0]M_AXI_AWID           ,// Master Interface Write Address ID
    output wire        [C_M_AXI_ADDR_WIDTH-1: 0]M_AXI_AWADDR       ,// Master Interface Write Address
    output wire        [   7: 0]        M_AXI_AWLEN                ,// Burst length. The burst length gives the exact number of transfers in a burst
    output wire        [   2: 0]        M_AXI_AWSIZE               ,// Burst size. This signal indicates the size of each transfer in the burst
    output wire        [   1: 0]        M_AXI_AWBURST              ,// Burst type. The burst type and the size information,  determine how the address for each transfer within the burst is calculated.
    output wire                         M_AXI_AWLOCK               ,// Lock type. Provides additional information about the atomic characteristics of the transfer.
    output wire        [   3: 0]        M_AXI_AWCACHE              ,// Memory type. This signal indicates how transactions are required to progress through a system.
    output wire        [   2: 0]        M_AXI_AWPROT               ,// Protection type. This signal indicates the privilege and security level of the transaction, and whether the transaction is a data access or an instruction access.
    output wire        [   3: 0]        M_AXI_AWQOS                ,// Quality of Service, QoS identifier sent for each write transaction.
    output wire        [C_M_AXI_AWUSER_WIDTH-1: 0]M_AXI_AWUSER     ,// Optional User-defined signal in the write address channel.
    output wire                         M_AXI_AWVALID              ,// Write address valid. This signal indicates that the channel is signaling valid write address and control information.
    input  wire                         M_AXI_AWREADY              ,// Write address ready. This signal indicates that the slave is ready to accept an address and associated control signals
    // w channel(write data)
    output wire        [C_M_AXI_DATA_WIDTH-1: 0]M_AXI_WDATA        ,// Master Interface Write Data.
    output wire        [C_M_AXI_DATA_WIDTH/8-1: 0]M_AXI_WSTRB      ,// Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bits of the write data bus.
    output wire                         M_AXI_WLAST                ,// Write last. This signal indicates the last transfer in a write burst.
    output wire        [C_M_AXI_WUSER_WIDTH-1: 0]M_AXI_WUSER       ,// Optional User-defined signal in the write data channel.
    output wire                         M_AXI_WVALID               ,// Write valid. This signal indicates that valid write data and strobes are available
    input  wire                         M_AXI_WREADY               ,// Write ready. This signal indicates that the slave can accept the write data.
    // b channel
    input  wire        [C_M_AXI_ID_WIDTH-1: 0]M_AXI_BID            ,// Master Interface Write Response.
    input  wire        [   1: 0]        M_AXI_BRESP                ,// Write response. This signal indicates the status of the write transaction.
    input  wire        [C_M_AXI_BUSER_WIDTH-1: 0]M_AXI_BUSER       ,// Optional User-defined signal in the write response channel
    input  wire                         M_AXI_BVALID               ,// Write response valid. This signal indicates that the channel is signaling a valid write response.
    output wire                         M_AXI_BREADY               ,// Response ready. This signal indicates that the master can accept a write response.
    // ar channel(read address)
    output wire        [C_M_AXI_ID_WIDTH-1: 0]M_AXI_ARID           ,// Master Interface Read Address.
    output wire        [C_M_AXI_ADDR_WIDTH-1: 0]M_AXI_ARADDR       ,// Read address. This signal indicates the initial address of a read burst transaction.
    output wire        [   7: 0]        M_AXI_ARLEN                ,// Burst length. The burst length gives the exact number of transfers in a burst
    output wire        [   2: 0]        M_AXI_ARSIZE               ,// Burst size. This signal indicates the size of each transfer in the burst
    output wire        [   1: 0]        M_AXI_ARBURST              ,// Burst type. The burst type and the size information,  determine how the address for each transfer within the burst is calculated.
    output wire                         M_AXI_ARLOCK               ,// Lock type. Provides additional information about the atomic characteristics of the transfer.
    output wire        [   3: 0]        M_AXI_ARCACHE              ,// Memory type. This signal indicates how transactions are required to progress through a system.
    output wire        [   2: 0]        M_AXI_ARPROT               ,// Protection type. This signal indicates the privilege and security level of the transaction, and whether the transaction is a data access or an instruction access.
    output wire        [   3: 0]        M_AXI_ARQOS                ,// Quality of Service, QoS identifier sent for each read transaction
    output wire        [C_M_AXI_ARUSER_WIDTH-1: 0]M_AXI_ARUSER     ,// Optional User-defined signal in the read address channel.
    output wire                         M_AXI_ARVALID              ,// Write address valid. This signal indicates that the channel is signaling valid read address and control information
    input  wire                         M_AXI_ARREADY              ,// Read address ready. This signal indicates that the slave is ready to accept an address and associated control signals
    // r channel(read data)
    input  wire        [C_M_AXI_ID_WIDTH-1: 0]M_AXI_RID            ,// Read ID tag. This signal is the identification tag for the read data group of signals generated by the slave.
    input  wire        [C_M_AXI_DATA_WIDTH-1: 0]M_AXI_RDATA        ,// Master Read Data
    input  wire        [   1: 0]        M_AXI_RRESP                ,// Read response. This signal indicates the status of the read transfer
    input  wire                         M_AXI_RLAST                ,// Read last. This signal indicates the last transfer in a read burst
    input  wire        [C_M_AXI_RUSER_WIDTH-1: 0]M_AXI_RUSER       ,// Optional User-defined signal in the read address channel.
    input  wire                         M_AXI_RVALID               ,// Read valid. This signal indicates that the channel is signaling the required read data.
    output wire                         M_AXI_RREADY                // Read ready. This signal indicates that the master can accept the read data and response information.
);
// ********************************************************************************** // 
//---------------------------------------------------------------------
// function called clogb2 that returns an integer which has the value of the ceiling of the log base 2
// for example, b = 8, a = clogb2(b) = 4
//---------------------------------------------------------------------
function integer clogb2;
    input                               integer bit_depth          ;
    for (clogb2 = 0; bit_depth>0; clogb2=clogb2+1) begin
        bit_depth = bit_depth >> 1;
    end
endfunction
// ********************************************************************************** // 
//---------------------------------------------------------------------
// regs and wires and localparams
//---------------------------------------------------------------------
    localparam                          integer C_TRANSACTIONS_NUM= clogb2(C_M_AXI_BURST_LEN-1);// C_TRANSACTIONS_NUM is the width of the index counter for  number of write or read transaction.
    reg                [C_M_AXI_ADDR_WIDTH-1: 0]axi_awaddr_r       ;
    reg                                 axi_awvalid_r              ;

    reg                [C_M_AXI_DATA_WIDTH-1: 0]axi_wdata_r        ;
    reg                                 axi_wlast_r                ;
    reg                                 axi_wvalid_r               ;

    reg                                 axi_bready_r               ;

    reg                [C_M_AXI_ADDR_WIDTH-1: 0]axi_araddr_r       ;
    reg                                 axi_arvalid_r              ;

    reg                                 axi_rready_r               ;

    wire               [C_TRANSACTIONS_NUM+2: 0]burst_size_bytes   ;
    reg                [C_TRANSACTIONS_NUM: 0]write_index          ;
    reg                [C_TRANSACTIONS_NUM: 0]read_index           ;

    // reg                                 wr_start_i  ;
    // reg                                 rd_start_i  ;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// assigns
//---------------------------------------------------------------------
//I/O Connections. Write Address (AW)
    assign                              M_AXI_AWID                = 'b0;//I/O Connections. Write Address (AW)
    assign                              M_AXI_AWADDR              = C_M_TARGET_SLAVE_BASE_ADDR + axi_awaddr_r;//The AXI address is a concatenation of the target base address + active offset range
    assign                              M_AXI_AWLEN               = C_M_AXI_BURST_LEN - 1;//Burst LENgth is number of transaction beats, minus 1
    assign                              M_AXI_AWSIZE              = clogb2((C_M_AXI_DATA_WIDTH/8)-1);//Size should be C_M_AXI_DATA_WIDTH, in 2^SIZE bytes, otherwise narrow bursts are used
    assign                              M_AXI_AWBURST             = 2'b01;//INCR burst type is usually used, except for keyhole bursts
    assign                              M_AXI_AWLOCK              = 1'b0;
    assign                              M_AXI_AWCACHE             = 4'b0010;//Update value to 4'b0011 if coherent accesses to be used via the Zynq ACP port. Not Allocated, Modifiable, not Bufferable. Not Bufferable since this example is meant to test memory, not intermediate cache. 
    assign                              M_AXI_AWPROT              = 3'h0;
    assign                              M_AXI_AWQOS               = 4'h0;
    assign                              M_AXI_AWUSER              = 1'b1;
    assign                              M_AXI_AWVALID             = axi_awvalid_r;
//Write Data(W)
    assign                              M_AXI_WDATA               = axi_wdata_r;
    assign                              M_AXI_WSTRB               = {(C_M_AXI_DATA_WIDTH/8){1'b1}};//All bursts are complete and aligned in this example
    assign                              M_AXI_WLAST               = axi_wlast_r;
    assign                              M_AXI_WUSER               = 1'b0;
    assign                              M_AXI_WVALID              = axi_wvalid_r;
//Write Response (B)
    assign                              M_AXI_BREADY              = axi_bready_r;
//Read Address (AR)
    assign                              M_AXI_ARID                = 1'b0;
    assign                              M_AXI_ARADDR              = C_M_TARGET_SLAVE_BASE_ADDR + axi_araddr_r;
    assign                              M_AXI_ARLEN               = C_M_AXI_BURST_LEN - 1;//Burst LENgth is number of transaction beats, minus 1
    assign                              M_AXI_ARSIZE              = clogb2((C_M_AXI_DATA_WIDTH/8)-1);//Size should be C_M_AXI_DATA_WIDTH, in 2^n bytes, otherwise narrow bursts are used
    assign                              M_AXI_ARBURST             = 2'b01;//INCR burst type is usually used, except for keyhole bursts
    assign                              M_AXI_ARLOCK              = 1'b0;
    assign                              M_AXI_ARCACHE             = 4'b0010;//Update value to 4'b0011 if coherent accesses to be used via the Zynq ACP port. Not Allocated, Modifiable, not Bufferable. Not Bufferable since this example is meant to test memory, not intermediate cache. 
    assign                              M_AXI_ARPROT              = 3'h0;
    assign                              M_AXI_ARQOS               = 4'h0;
    assign                              M_AXI_ARUSER              = 1'b1;
    assign                              M_AXI_ARVALID             = axi_arvalid_r;
//Read and Read Response (R)
    assign                              M_AXI_RREADY              = axi_rready_r;

//Burst size in bytes
    assign                              burst_size_bytes          = C_M_AXI_BURST_LEN * C_M_AXI_DATA_WIDTH/8;

//ram interface
    assign                              wr_data_respond_o         = M_AXI_WREADY && axi_wvalid_r;
    assign                              rd_burst_done_o           = M_AXI_BVALID && axi_bready_r;
    assign                              rd_data_o                 = M_AXI_RDATA;
    assign                              rd_data_valid_o           = M_AXI_RVALID && axi_rready_r;
    assign                              rd_burst_done_o           = M_AXI_RLAST;
// ********************************************************************************** // 
//---------------------------------------------------------------------
// main code
//---------------------------------------------------------------------
//--------------------
//Write Address Channel
//--------------------
always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)begin
    if(!M_AXI_ARESETN)
        axi_awvalid_r <= 'd0;
    else if (M_AXI_AWREADY && axi_awvalid_r)
        axi_awvalid_r <= 'd0;
    else if (wr_start_i)
        axi_awvalid_r <= 'd1;
    else
        axi_awvalid_r <= axi_awvalid_r;
end
// Next address after AWREADY indicates previous address acceptance
always@(*)begin
    axi_awaddr_r = wr_addr_i;
end
// always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)begin
//     if(!M_AXI_ARESETN)
//         axi_awaddr_r <= 'd0;
//     else if (M_AXI_AWREADY && axi_awvalid_r)
//         axi_awaddr_r <= axi_awaddr_r + burst_size_bytes;
//     else
//         axi_awaddr_r <= axi_awaddr_r;
// end
//--------------------
//Write Data Channel
//--------------------
always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)begin
    if(!M_AXI_ARESETN)
        axi_wvalid_r <= 'd0;
    else if (axi_wlast_r)
        axi_wvalid_r <= 'd0;
    else if (wr_start_i)
        axi_wvalid_r <= 'd1;
    else
        axi_wvalid_r <= axi_wvalid_r;
end

always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)begin
    if(!M_AXI_ARESETN)
        write_index <= 'd0;
    else if (wr_start_i)
        write_index <= 'd0;
    else if (write_index == C_M_AXI_BURST_LEN-1 && M_AXI_WREADY && axi_wvalid_r)
        write_index <= 'd0;
    else if (M_AXI_WREADY && axi_wvalid_r)
        write_index <= write_index + 'd1;
    else
        write_index <= write_index;
end

always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)begin
    if(!M_AXI_ARESETN)
        axi_wlast_r <= 'd0;
    else if (((write_index == C_M_AXI_BURST_LEN-2 && C_M_AXI_BURST_LEN >= 2) && M_AXI_WREADY && axi_wvalid_r) || (C_M_AXI_BURST_LEN == 1 ))
        axi_wlast_r <= 'd1;
    else
        axi_wlast_r <= 'd0;
end

always@(*)begin
    axi_wdata_r = wr_data_i;
end
// always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)begin
//     if(!M_AXI_ARESETN)
//         axi_wdata_r <= 'd0;
//     else if (M_AXI_WREADY && axi_wvalid_r)
//         axi_wdata_r <= axi_wdata_r + 'd1;
//     else
//         axi_wdata_r <= axi_wdata_r;
// end
//----------------------------
//Write Response (B) Channel
//----------------------------
always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)begin
    if(!M_AXI_ARESETN)
        axi_bready_r <= 'd0;
    else if (M_AXI_BVALID && axi_bready_r)
        axi_bready_r <= 'd0;
    else if (M_AXI_BVALID)
        axi_bready_r <= 'd1;
    else
        axi_bready_r <= axi_bready_r;
end
//----------------------------
//Read Address Channel
//----------------------------
always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)begin
    if(!M_AXI_ARESETN)
        axi_arvalid_r <= 'd0;
    else if (M_AXI_ARREADY && axi_arvalid_r)
        axi_arvalid_r <= 'd0;
    else if (rd_start_i)
        axi_arvalid_r <= 'd1;
    else
        axi_arvalid_r <= axi_arvalid_r;
end
// Next address after ARREADY indicates previous address acceptance
always@(*)begin
    axi_araddr_r = rd_addr_i;
end
// always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)begin
//     if(!M_AXI_ARESETN)
//         axi_araddr_r <= 'd0;
//     else if (M_AXI_ARREADY && axi_arvalid_r)
//         axi_araddr_r <= axi_araddr_r + burst_size_bytes;
//     else
//         axi_araddr_r <= axi_araddr_r;
// end
//--------------------------------
//Read Data (and Response) Channel
//--------------------------------
always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)begin
    if(!M_AXI_ARESETN)
        axi_rready_r <= 'd0;
    else if (M_AXI_RVALID) begin
        if (M_AXI_RLAST && axi_rready_r)
            axi_rready_r <= 'd0;
        else
            axi_rready_r <= 'd1;
    end
    else
        axi_rready_r <= axi_rready_r;
end
// Burst length counter. Uses extra counter register bit to indicate terminal count to reduce decode logic   
// always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN)begin
//     if(!M_AXI_ARESETN)
//         read_index <= 'd0;
//     else if (M_AXI_RLAST)
//         read_index <= 'd0;
//     else if (M_AXI_RVALID && axi_rready_r && (read_index != C_M_AXI_BURST_LEN-1))
//         read_index <= read_index + 'd1;
//     else
//         read_index <= read_index;
// end

endmodule