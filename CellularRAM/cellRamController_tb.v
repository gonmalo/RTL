`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Author: Ronald Valenzuela
//
// Create Date:   18:15:10 05/02/2015
// Design Name:   cellRamController
// Module Name:   C:/Users/ronaldv/Documents/Xilinx/cordic/RTL/cellRamController_tb.v
// Project Name:  cordic
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: cellRamController
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
// Find RAM behavioral model at 
// http://www.micron.com/parts/psram/cellularram/mt45w8mw16bgx-701-it?pc=%7bBD8A72EA-2DC2-4B88-846E-7B59997A2D97%7d
// 
////////////////////////////////////////////////////////////////////////////////
`define PERIOD 20

module cellRamController_tb #( 
	parameter [2:0]
		OP_NULL=3'd0,
		OP_READ_CTRL=3'd1,
		OP_WRITE_CTRL=3'd2,
		OP_ASYNC_READ=3'd3, 
		OP_ASYNC_WRITE=3'd4
	)
;

	// Inputs
	reg iClock;
	reg iReset;
	reg [2:0] wOP; 
	reg [22:0] iAddr;
	reg [15:0] iData;

	// Outputs
	wire oReady;
	wire oClock;
	wire oADV_n;
	wire oCRE;
	wire oCE_n;
	wire oOE_n;
	wire oWE_n;
	wire oLB_n;
	wire oUB_n;
	wire oWait;
	wire [22:0] orAddr;

	// Bidirs
	wire [15:0] dq;

	// Instantiate the Unit Under Test (UUT)
	cellRamController uut (
		.iClock(iClock), 
		.iReset(iReset), 
		.wOP(wOP), 
		.iAddr(iAddr), 
		.iData(iData), 
		.oReady(oReady), 
		.oClock(oClock), 
		.oADV_n(oADV_n), 
		.oCRE(oCRE), 
		.oWait(oWait), 
		.oCE_n(oCE_n), 
		.oOE_n(oOE_n), 
		.oWE_n(oWE_n), 
		.oLB_n(oLB_n), 
		.oUB_n(oUB_n), 
		.orAddr(orAddr), 
		.dq(dq)
	);
	
    // component instantiation
    cellram uMem (
        .clk    (oClock),
        .adv_n  (oADV_n),
        .cre    (oCRE),
        .o_wait (oWait),
        .ce_n   (oCE_n),
        .oe_n   (oOE_n),
        .we_n   (oWE_n),
        .ub_n   (oLB_n),
        .lb_n   (oUB_n),
        .addr   (orAddr),
        .dq     (dq)
    );
	always 
		#(`PERIOD/2) iClock = ~ iClock;
	
	////////////////////////////////////////////////////////////////////////////////
	// TASKS BEGIN
	////////////////////////////////////////////////////////////////////////////////
	
	// Initial Conditions
	task reset_env;
	begin
		iClock = 0;
		iReset = 0;
		wOP = 0; 		
		iAddr=0;
	end
	endtask
	
	// RESET 	
	task reset_dut;
	begin
		#(`PERIOD) iReset = 1;
		#(`PERIOD) iReset = 0;
		while(!uut.oReady) begin
			#(`PERIOD);
		end
	end
	endtask
		
	// CONTROL REGISTER READ TEST
	task read_control_regs;
	begin
		while(!uut.oReady) begin
			#(`PERIOD);
		end
		wOP=OP_READ_CTRL; 
		iAddr=0;
		iAddr[19:18]=2'b10;  // BCR
		#(`PERIOD);
		while(!uut.oReady) begin
			#(`PERIOD);
		end
		@(posedge iClock) $display("%t, BCR %x\n",$time, uut.dq); 
		iAddr[19:18]=2'b00; // RCR
		#(`PERIOD);
		while(!uut.oReady) begin
			#(`PERIOD);
		end 
		@(posedge iClock)$display("%t, RCR %x\n",$time,uut.dq); 
		iAddr[19:18]=2'b01; //DIDR
			#(`PERIOD);
		wOP=OP_NULL; 
		while(!uut.oReady) begin
			#(`PERIOD);
		end 
		@(posedge iClock) $display("%t, DIDR %x\n",$time,uut.dq);
	end
	endtask
	
		// ASYNC READ
	task async_read_addr;
	input [22:0] address;
	begin 
	//while(!uut.oReady) begin
	//	#(`PERIOD);
	//end  
	@(posedge iClock) begin
		iAddr = address; 
		wOP=OP_ASYNC_READ; 
	end
	#(`PERIOD);
	#(`PERIOD);
	@(posedge iClock)	wOP=OP_NULL; 
	end 
	endtask
	
	// ASYNC WRITE
	task async_write_addr;
	input [22:0] address;
	input [15:0] data;
	begin
		while(!uut.oReady) begin
			#(`PERIOD);
		end  
		iAddr = address;
		iData = data;
		wOP=OP_ASYNC_WRITE; 
			#(`PERIOD);
			#(`PERIOD);
		wOP=OP_NULL; 
	end 
	endtask
	
	// READ TEST
	integer i;
	task async_read_test;
	input [31:0] limit;
	begin
		for(i=0;i<limit; i=i+1) begin
			async_read_addr(i); 
			while(!uut.oReady) begin
				#(`PERIOD);
			end  
			//@(posedge iClock) $display("%t, READ 0x%x 0x%x\n",$time, iAddr, uut.dq);
		end
	end
	endtask
	
	// WRITE TEST
	task async_write_test;
	input [31:0] limit;
	begin
		for(i=0;i<limit; i=i+1) begin
			async_write_addr(i,i);
			#(`PERIOD);
			while(!uut.oReady) begin
				#(`PERIOD);
			end  
		end
	end
	endtask
	
	////////////////////////////////////////////////////////////////////////////////
	// SIM BEGIN
	////////////////////////////////////////////////////////////////////////////////
	
	initial begin
		// Initialize Inputs
		reset_env;
		reset_dut;
		// Wait 100 ns for global reset to finish
		#100;
        
		read_control_regs();  
		async_write_test(10); 
		async_read_test(10); 
		#(30*`PERIOD);
		$finish;
	end
      
endmodule

