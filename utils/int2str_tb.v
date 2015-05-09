`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   20:36:24 04/29/2015
// Design Name:   int2str
// Module Name:   C:/Users/ronaldv/Documents/Xilinx/cordic/int2str_tb.v
// Project Name:  cordic
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: int2str
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////
`define PERIOD 50

module int2str_tb;

	// Inputs
	reg iClock;
	reg iReset;
	reg [15:0] iBinary;

	// Outputs
	wire [15:0] oString;
	wire oDone;

	integer i,j, seed; 
	// Instantiate the Unit Under Test (UUT)
	int2str uut (
		.iClock(iClock), 
		.iReset(iReset), 
		.iBinary(iBinary), 
		.oString(oString), 
		.oDone(oDone)
	);
	
	always 
		#(`PERIOD/2) iClock = ~ iClock;
	
		task reset_dut;
	begin
		#(`PERIOD) iReset = 1;
		#(`PERIOD) iReset = 0;
	end
	endtask
	task reset_env;
	begin
		iClock = 0;
		iReset = 0; 
		iBinary=8'd0;
		seed=0;
	end
	endtask
	
	initial begin
		// Initialize Inputs
		reset_env; 
		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here 
		for(j=0;j<10;j=j+1) begin
			// Use concatenator operator to get positive random numbers {}
			iBinary={$random(seed)} % 10000; 
		   reset_dut;
			//for(i=15;i>=0;i=i-1) begin
				//binStream = binary[i];
			while(uut.oDone != 1) begin
				#(`PERIOD);
			end
			#(`PERIOD);
			//end
			$display("%d: %d - %d - %d - %d\n", iBinary, uut.bcd_array[3].uBCD.bcd, uut.bcd_array[2].uBCD.bcd, uut.bcd_array[1].uBCD.bcd, uut.bcd_array[0].uBCD.bcd );
		end
		$finish;
	end
      
endmodule

