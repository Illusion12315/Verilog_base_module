`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: Mario Blunk - electronics & IT engineering
// Engineer: Mario Blunk
//
// Create Date:   10:39:20 09/08/2011
// Design Name:   main
// Module Name:   /home/luno/ise-projects/transceiver/sim_main.v
// Project Name:  transceiver
// Target Device: XC2C384 (Coolrunner 2) 
// Tool versions: Xilinx ISE 10.1.03 (Linux)
// Description: 
//
// Verilog Test Fixture created by ISE for module: main
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module i2c_slave_scl_4B_tb;

	// Inputs
    reg                                 reset                      ;// this signal serves as marker in the waveform diagram - no further meaning
    reg                                 scl                        ;
    reg                                 rst_n_i                    ;
	// Bidirs
    tri1 sda;                                                       // sda is pulled up in real world

    wire                                ram_wr_en_o                ;
    wire               [   7: 0]        ram_wr_addr_o              ;
    wire               [  31: 0]        ram_wr_data_o              ;
    wire               [   7: 0]        ram_rd_addr_o              ;
    wire                                ram_rd_en_o                ;
    reg                [  31: 0]        ram_rd_data_i              ;
    reg                                 sys_clk                    ;
	// Outputs
    integer                             serial_data_red_from_slave  ;// 8 bit number received via I2C bus from slave

    integer                             bit_ptr                    ;

    localparam                          I2C_ADR                   = 7'h27 ;
    localparam                          I2C_ADR_error             = 7'h21 ;

//I2C_slave_sysclk_4B # (
//    .I2C_ADR                            (I2C_ADR                   ) 
// )
// I2C_slave_v2_inst0 (
//    .sys_clk_i                          (sys_clk                   ),
//    .rst_n_i                            (rst_n_i                   ),
//    .ram_wr_en_o                        (ram_wr_en_o               ),
//    .ram_wr_addr_o                      (ram_wr_addr_o             ),
//    .ram_wr_data_o                      (ram_wr_data_o             ),
//    .ram_rd_en_o                        (ram_rd_en_o               ),
//    .ram_rd_addr_o                      (ram_rd_addr_o             ),
//    .ram_rd_data_i                      (ram_rd_data_i             ),
//    .SCL                                (scl                       ),
//    .SDA                                (sda                       ) 
// );
I2C_slave_scl_4B # (
    .I2C_ADR                            (I2C_ADR                   ) 
  )
  I2C_slave_scl_4B_inst (
    .sys_clk_i                          (sys_clk                   ),
    .rst_n_i                            (rst_n_i                   ),
    .ram_wr_en_o                        (ram_wr_en_o               ),
    .ram_wr_addr_o                      (ram_wr_addr_o             ),
    .ram_wr_data_o                      (ram_wr_data_o             ),
    .ram_rd_en_o                        (ram_rd_en_o               ),
    .ram_rd_addr_o                      (ram_rd_addr_o             ),
    .ram_rd_data_i                      (ram_rd_data_i             ),
    .SCL                                (scl                       ),
    .SDA                                (sda                       ) 
  );

    reg                [  31: 0]        ram                 [0:255]  ;

always@(posedge sys_clk)begin
    if (ram_wr_en_o) begin
        ram[ram_wr_addr_o] <= ram_wr_data_o;
    end
end

always@(posedge sys_clk)begin
    if(ram_rd_en_o)
        ram_rd_data_i <= ram[ram_rd_addr_o];
end

always #2.5  sys_clk = ! sys_clk;

    initial begin
		// Initialize Inputs
        sys_clk = 0;
        scl = 1;
        rst_n_i = 0;
        #50
        rst_n_i = 1;
        release sda;
        reset = 1;

		// Wait 100 ns for global reset to finish
        #100;
		// Add stimulus here
		
		
        reset = 0;                                                  // indicate start of write access in waveform diagram
        #10;
        reset = 1;


		// WRITE ACCESS TO SLAVE
        start;
        #50;
        tx_slave_address_wr(I2C_ADR);                               // slave address is hard coded in line 19 of UUT
        tx_slave_data(8'h00);                                       // tx 8Dh to slave
        tx_slave_data(8'hf0);                                       // tx 8Dh to slave
        tx_slave_data(8'hf1);                                       // tx 8Dh to slave
        tx_slave_data(8'hf2);                                       // tx 8Dh to slave
        tx_slave_data(8'hf3);                                       // tx 8Dh to slave
		// slave parallel output should be 8Dh now
        stop;

        
        start;
        #50;
        tx_slave_address_wr(I2C_ADR);                               // slave address is hard coded in line 19 of UUT
        tx_slave_data(8'h12);                                       // tx 8Dh to slave
        tx_slave_data(8'h00);                                       // tx 8Dh to slave
        tx_slave_data(8'h01);                                       // tx 8Dh to slave
        tx_slave_data(8'h02);                                       // tx 8Dh to slave
        tx_slave_data(8'h03);                                       // tx 8Dh to slave
		// slave parallel output should be 8Dh now
        stop;
				
				
        reset = 0;                                                  // indicate start of read access in waveform diagram
        #10;
        reset = 1;
		
		
		// READ ACCESS TO SLAVE
        start;
        #50;
        tx_slave_address_rd(I2C_ADR);                               // slave address is hard coded in line 19 of UUT
        tx_slave_data(8'h00);                                       // tx 8Dh to slave
        rx_slave_data(serial_data_red_from_slave);                  // NOTE: data red is equal to data written previously.
        rx_slave_data(serial_data_red_from_slave);                  // NOTE: data red is equal to data written previously.
        rx_slave_data(serial_data_red_from_slave);                  // NOTE: data red is equal to data written previously.
        rx_slave_data(serial_data_red_from_slave);                  // NOTE: data red is equal to data written previously.
																 // data is red from UUT internal register "mem" , not from parallel IO port !
																 // modify line 80 (reg [7:0] mem = 8'h7E;) to change initial data	
        stop;
        #50;

        reset = 0;                                                  // indicate end of simulation
        #10;
        reset = 1;

    end
      
	// tasks
				
    task start;
        begin
			//scl and sda are assumed already high;
            #50 force sda = 0;
            #50 scl = 0;
        end
    endtask

    task stop;
        begin
			//scl assumed already low;			
            #50 force sda = 0;
            #50 scl = 1;
            #50 release sda;
            #50;
        end
    endtask
		
    task tx_slave_address_wr;
		//scl and sda are assumed already low;			
    input                               integer slave_address      ;
    integer                             clock_ct                   ;
		 // first bit to send is MSB of a total of 7 address bits !
        begin                                                       // do 7 clock cycles
            bit_ptr=7;
            for (clock_ct = 0 ; clock_ct < 7 ; clock_ct = clock_ct + 1)
                begin
                    #50 force sda = slave_address[bit_ptr];         //NOTE: forcing sda H is no elegant way since sda is of type "tri1"
                    bit_ptr = bit_ptr - 1;                          // be ready for next address bit
                    #50 scl = 1;
                    #50 scl = 0;
                end
        #50 force sda = 0;                                          //WRITE access requested
        #50 scl = 1;                                                //do 8th clock cycle 
        #50 scl = 0;

        ackn_cycle;
        end
    endtask

    task tx_slave_address_rd;
		//scl and sda are assumed already low;			
    input                               integer slave_address      ;
    integer                             clock_ct                   ;
		// integer  // first bit to send is MSB of a total of 7 address bits !
        begin                                                       // do 7 clock cycles
            bit_ptr=7;
            for (clock_ct = 0 ; clock_ct < 7 ; clock_ct = clock_ct + 1)
                begin
                    #50 force sda = slave_address[bit_ptr];         //NOTE: forcing sda H is no elegant way since sda is of type "tri1"
                    bit_ptr = bit_ptr - 1;                          // be ready for next address bit
                    #50 scl = 1;
                    #50 scl = 0;
                end
        #50 force sda = 1;                                          //READ access requested
        #50 scl = 1;                                                //do 8th clock cycle 
        #50 scl = 0;

        ackn_cycle;
        end
    endtask

    task tx_slave_data;
		//scl and sda are assumed already low;			
    input                               integer slave_data         ;
    integer                             clock_ct                   ;
		// integer  // first bit to send is MSB of a total of 8 data bits !
        begin                                                       // do 8 clock cycles
            bit_ptr=8;
            for (clock_ct = 0 ; clock_ct < 8 ; clock_ct = clock_ct + 1)
                begin
                    #50 force sda = slave_data[bit_ptr];            //NOTE: forcing sda H is no elegant way since sda is of type "tri1"
                    bit_ptr = bit_ptr - 1;                          // be ready for next data bit
                    #50 scl = 1;
                    #50 scl = 0;
                end

        ackn_cycle;
        end
    endtask
	
    task rx_slave_data;
		//scl assumed already low;			
		//sda assumed already released (H) by previous ackn_cycle
    output             [   7: 0]        slave_data                 ;
    integer                             clock_ct                   ;
		// integer  // first bit to receive is MSB of a total of 8 data bits !
        begin                                                       // do 8 clock cycles
            bit_ptr=7;
            for (clock_ct = 0 ; clock_ct < 8 ; clock_ct = clock_ct + 1)
                begin
                    #50 scl = 1;
                    slave_data[bit_ptr] = sda;
                    bit_ptr = bit_ptr - 1;                          // be ready for next data bit
                    #50 scl = 0;
                end

        no_ackn_cycle;
        end
    endtask

    task ackn_cycle;
        begin
            #50 release sda;                                        //ackn from slave expected -> slave drives L on ACK
            #50 scl = 1;                                            //do 9th clock cycle 
            #50 scl = 0;
			//slave releases sda line now
        end
    endtask

    task no_ackn_cycle;
        begin
			//tx a notackn to slave -> sda remains released (H)
            #50 scl = 1;                                            //do 9th clock cycle 
            #50 scl = 0;
        end
    endtask

endmodule

