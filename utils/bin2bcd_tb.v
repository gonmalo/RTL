`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   09:43:56 04/29/2015
// Design Name:   bin2bcd
// Module Name:   C:/Users/ronaldv/Documents/Xilinx/cordic/bin2bcd_tb.v
// Project Name:  cordic
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: bin2bcd
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////
`define PERIOD 50
module bin2bcd_tb;

	// Inputs
	reg clock;
	reg reset;
	reg binStream;
	reg [15:0] binary;
	// Outputs  
	wire w1,w2,w3;
	wire [3:0] uni;
	wire [3:0] dec;
	wire [3:0] cen;
	wire [3:0] mil;

	integer i,j, seed; 

	// Instantiate the Unit Under Test (UUT)
	bin2bcd uut_uni (
		.clock(clock), 
		.reset(reset),  
		.binStream(binStream),  
		.overFlow(w1),
		.bcd(uni)
	);
	bin2bcd uut_dec (
		.clock(clock), 
		.reset(reset), 
		.binStream(w1),  
		.overFlow(w2),
		.bcd(dec)
	);
	bin2bcd uut_cen (
		.clock(clock), 
		.reset(reset), 
		.binStream(w2),  
		.overFlow(w3),
		.bcd(cen)
	);
	bin2bcd uut_mil (
		.clock(clock), 
		.reset(reset), 
		.binStream(w3),  
		.overFlow(),
		.bcd(mil)
	);
	always 
		#(`PERIOD/2) clock = ~ clock;
	
	task reset_dut;
	begin
		#(`PERIOD) reset = 1;
		#(`PERIOD) reset = 0;
	end
	endtask
	task reset_env;
	begin
		clock = 0;
		reset = 0;
		binStream = 0;
		binary=8'd0;
		seed=0;
	end
	endtask
	initial begin
		// Initialize Inputs
		reset_env;
		reset_dut;
		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		for(j=0;j<10;j=j+1) begin
		   reset_dut;
			// Use concatenator operator to get positive random numbers {}
			binary={$random(seed)} % 10000;
			for(i=15;i>=0;i=i-1) begin
				binStream = binary[i];
				#(`PERIOD);
			end
			$display("%d: %d - %d - %d - %d\n", binary, uut_mil.bcd, uut_cen.bcd, uut_dec.bcd, uut_uni.bcd);
		end
		$finish;
	end
endmodule

