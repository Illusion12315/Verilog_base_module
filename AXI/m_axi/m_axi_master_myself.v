`timescale 1 ns / 1 ps

module m_axi_master_myself #(
    parameter                           C_M_TARGET_SLAVE_BASE_ADDR = 32'h40000000,// Base address of targeted slave
    parameter                           C_M_AXI_BURST_LEN = 16     ,// Burst Length. Supports 1, 2, 4, 8, 16, 32, 64, 128, 256 burst lengths
    parameter                           C_M_AXI_ID_WIDTH = 1       ,// Thread ID Width
    parameter                           C_M_AXI_ADDR_WIDTH = 32    ,// Width of Address Bus
    parameter                           C_M_AXI_DATA_WIDTH = 32    ,// Width of Data Bus
    parameter                           C_M_AXI_AWUSER_WIDTH = 0   ,// Width of User Write Address Bus
    parameter                           C_M_AXI_ARUSER_WIDTH = 0   ,// Width of User Read Address Bus
    parameter                           C_M_AXI_WUSER_WIDTH	= 0    ,// Width of User Write Data Bus
    parameter                           C_M_AXI_RUSER_WIDTH	= 0    ,// Width of User Read Data Bus
    parameter                           C_M_AXI_BUSER_WIDTH	= 0     // Width of User Response Bus
) (
    //-------------------------customrize---------------------------//
    
    //----------------------m AXI MM interface---------------------//
    input  wire                         M_AXI_ACLK                 ,// Global Clock Signal.
    input  wire                         M_AXI_ARESETN              ,// Global Reset Singal. This Signal is Active Low
    // aw channel(write address)
    output wire        [C_M_AXI_ID_WIDTH-1:0]M_AXI_AWID                 ,// Master Interface Write Address ID
    output wire        [C_M_AXI_ADDR_WIDTH-1:0]M_AXI_AWADDR               ,// Master Interface Write Address
    output wire        [   7:0]         M_AXI_AWLEN                ,// Burst length. The burst length gives the exact number of transfers in a burst
    output wire        [   2:0]         M_AXI_AWSIZE               ,// Burst size. This signal indicates the size of each transfer in the burst
    output wire        [   1:0]         M_AXI_AWBURST              ,// Burst type. The burst type and the size information,  determine how the address for each transfer within the burst is calculated.
    output wire                         M_AXI_AWLOCK               ,// Lock type. Provides additional information about the atomic characteristics of the transfer.
    output wire        [   3:0]         M_AXI_AWCACHE              ,// Memory type. This signal indicates how transactions are required to progress through a system.
    output wire        [   2:0]         M_AXI_AWPROT               ,// Protection type. This signal indicates the privilege and security level of the transaction, and whether the transaction is a data access or an instruction access.
    output wire        [   3:0]         M_AXI_AWQOS                ,// Quality of Service, QoS identifier sent for each write transaction.
    output wire        [C_M_AXI_AWUSER_WIDTH-1:0]M_AXI_AWUSER               ,// Optional User-defined signal in the write address channel.
    output wire                         M_AXI_AWVALID              ,// Write address valid. This signal indicates that the channel is signaling valid write address and control information.
    input  wire                         M_AXI_AWREADY              ,// Write address ready. This signal indicates that the slave is ready to accept an address and associated control signals
    // w channel(write data)
    output wire        [C_M_AXI_DATA_WIDTH-1:0]M_AXI_WDATA                ,// Master Interface Write Data.
    output wire        [C_M_AXI_DATA_WIDTH/8-1:0]M_AXI_WSTRB                ,// Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bits of the write data bus.
    output wire                         M_AXI_WLAST                ,// Write last. This signal indicates the last transfer in a write burst.
    output wire        [C_M_AXI_WUSER_WIDTH-1:0]M_AXI_WUSER                ,// Optional User-defined signal in the write data channel.
    output wire                         M_AXI_WVALID               ,// Write valid. This signal indicates that valid write data and strobes are available
    input  wire                         M_AXI_WREADY               ,// Write ready. This signal indicates that the slave can accept the write data.
    // b channel
    input  wire        [C_M_AXI_ID_WIDTH-1:0]M_AXI_BID                  ,// Master Interface Write Response.
    input  wire        [   1:0]         M_AXI_BRESP                ,// Write response. This signal indicates the status of the write transaction.
    input  wire        [C_M_AXI_BUSER_WIDTH-1:0]M_AXI_BUSER                ,// Optional User-defined signal in the write response channel
    input  wire                         M_AXI_BVALID               ,// Write response valid. This signal indicates that the channel is signaling a valid write response.
    output wire                         M_AXI_BREADY               ,// Response ready. This signal indicates that the master can accept a write response.
    // ar channel(read address)
    output wire        [C_M_AXI_ID_WIDTH-1:0]M_AXI_ARID                 ,// Master Interface Read Address.
    output wire        [C_M_AXI_ADDR_WIDTH-1:0]M_AXI_ARADDR               ,// Read address. This signal indicates the initial address of a read burst transaction.
    output wire        [   7:0]         M_AXI_ARLEN                ,// Burst length. The burst length gives the exact number of transfers in a burst
    output wire        [   2:0]         M_AXI_ARSIZE               ,// Burst size. This signal indicates the size of each transfer in the burst
    output wire        [   1:0]         M_AXI_ARBURST              ,// Burst type. The burst type and the size information,  determine how the address for each transfer within the burst is calculated.
    output wire                         M_AXI_ARLOCK               ,// Lock type. Provides additional information about the atomic characteristics of the transfer.
    output wire        [   3:0]         M_AXI_ARCACHE              ,// Memory type. This signal indicates how transactions are required to progress through a system.
    output wire        [   2:0]         M_AXI_ARPROT               ,// Protection type. This signal indicates the privilege and security level of the transaction, and whether the transaction is a data access or an instruction access.
    output wire        [   3:0]         M_AXI_ARQOS                ,// Quality of Service, QoS identifier sent for each read transaction
    output wire        [C_M_AXI_ARUSER_WIDTH-1:0]M_AXI_ARUSER               ,// Optional User-defined signal in the read address channel.
    output wire                         M_AXI_ARVALID              ,// Write address valid. This signal indicates that the channel is signaling valid read address and control information
    input  wire                         M_AXI_ARREADY              ,// Read address ready. This signal indicates that the slave is ready to accept an address and associated control signals
    // r channel(read data)
    input  wire        [C_M_AXI_ID_WIDTH-1:0]M_AXI_RID                  ,// Read ID tag. This signal is the identification tag for the read data group of signals generated by the slave.
    input  wire        [C_M_AXI_DATA_WIDTH-1:0]M_AXI_RDATA                ,// Master Read Data
    input  wire        [   1:0]         M_AXI_RRESP                ,// Read response. This signal indicates the status of the read transfer
    input  wire                         M_AXI_RLAST                ,// Read last. This signal indicates the last transfer in a read burst
    input  wire        [C_M_AXI_RUSER_WIDTH-1:0]M_AXI_RUSER                ,// Optional User-defined signal in the read address channel.
    input  wire                         M_AXI_RVALID               ,// Read valid. This signal indicates that the channel is signaling the required read data.
    output wire                         M_AXI_RREADY                // Read ready. This signal indicates that the master can accept the read data and response information.
);




endmodule