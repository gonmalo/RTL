`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   20:55:33 04/30/2015
// Design Name:   slower_clk
// Module Name:   C:/Users/gonzalof/Desktop/FPGA/DASD/T2/Codigo/slow_clk_tb.v
// Project Name:  Codigo
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: slower_clk
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module slow_clk_tb;

	// Inputs
	reg [0:0] clk;
	reg [0:0] rst;

	// Outputs
	wire [0:0] clk_slow;

	// Instantiate the Unit Under Test (UUT)
	slower_clk #(2) uut (
		.clk(clk), 
		.rst(rst), 
		.clk_slow(clk_slow)
	);

  //always  #2  clk =  ! clk;

  initial begin
 		// Initialize Inputs
		clk = 0;
		rst = 1;

		// Wait 100 ns for global reset to finish
		//#100;
        
		// Add stimulus here
		#10 rst = 0;
		
		#1000 $finish;

	end
  initial begin
	//generador del clk
	forever begin
		#2 clk = ~clk ;
	end
end	
endmodule

