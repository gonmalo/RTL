`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   10:58:32 05/01/2015
// Design Name:   contador
// Module Name:   C:/Users/gonzalof/Desktop/FPGA/DASD/T2/Codigo/contador_tb.v
// Project Name:  Codigo
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: contador
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module contador_tb;

	// Inputs
	reg [0:0] nxt;
	reg [0:0] dir;
	reg [0:0] rst;

	// Outputs
	wire [0:0] empty;
	wire [0:0] full;
	wire [1:0] cuenta;

	// Instantiate the Unit Under Test (UUT)
	contador #(2) uut (
		.nxt(nxt), 
		.dir(dir), 
		.rst(rst), 
		.empty(empty), 
		.full(full), 
		.cuenta(cuenta)
	);
	
	integer i;
	initial begin
	// Initialize Inputs
	nxt = 0;
	dir = 0;
	rst = 0;

	// Wait 100 ns for global reset to finish
	#100;
        
	// Add stimulus here
	rst = 1;
	#2 rst = 0;
	
	dir = 1;
	for(i=0; i<11; i=i+1) begin
	  if(i>5) dir = 0;
	  #2 nxt = 1;
	  #2 nxt = 0;
	end
	
	end
      
endmodule

