//`include "cellRam\cellram_parameters.vh"

`define tPU 150e3
`define tCO 85
`define tRC 85
`define tWC 85
`define tAVS 5

module cellRamController #(parameter clockPeriod=20,
	parameter [2:0] 
		CM_INIT=3'd0,
		CM_READY=3'd1,
		CM_READ_CTRL=3'd2,
		CM_WRITE_CTRL=3'd3,
		CM_ASYNC_READ=3'd4,
		CM_ASYNC_WRITE=3'd5,
	parameter [2:0]
		OP_NULL=3'd0,
		OP_READ_CTRL=3'd1,
		OP_WRITE_CTRL=3'd2,
		OP_ASYNC_READ=3'd3, 
		OP_ASYNC_WRITE=3'd4
	)(
	// Controller Signals
	input iClock,
	input iReset,
	input [2:0] wOP,
	input [22:0] iAddr,
	input [15:0] iData,
	output oReady, 		// Power Up Done
	// Ram Interface
   output oClock, 
   output oADV_n, 		// Address Valid Bar
   output oCRE, 			// Control Register Enable
   input oWait, 			// Data Valid Feedback
   output oCE_n, 			// Chip Enable Bar 
   output oOE_n, 			// Output Enable bar
   output oWE_n, 			// Write Enable bar
   output oLB_n, 			// Lower Byte Enable Bar
   output oUB_n, 			// Upper Byte Enable Bar 
   output reg [22:0] orAddr, 	// Address 
   inout [15:0] dq 		// Data In/Out
); 

// Resources
reg rCE_n;
reg rCRE;
reg rADV_n;
reg rOE_n;
reg rWE_n;
reg rLB_n;
reg rUB_n;
// Output Buffers 
// (Check that this map to tri-state IO buffers)
assign dq = ( oOE_n & !oWE_n) ? data_out : 16'bzzzz_zzzz_zzzz_zzzz ;
reg [15:0] data_in;
reg [15:0] data_out;

// Drive Control Outputs
//assign oClock = (state != CM_INIT) ? iClock : 1'bz;
// Async
assign oClock = (state != CM_INIT) ? 1'b0 : 1'bz;
assign oReady = (state == CM_READY) ? 1 : 0;
assign oCE_n = (state == CM_INIT) ? 1 : rCE_n;
assign oCRE = rCRE;
assign oADV_n = rADV_n;
assign oOE_n = rOE_n;
assign oWE_n = rWE_n;
assign oLB_n = rLB_n;
assign oUB_n = rUB_n;

always@(posedge iClock or posedge iReset) begin
	if(iReset) begin
		rCE_n <= #(2) 1; // 2ns hold on all 
		rWE_n <= #(2) 1;
		rOE_n <= #(2) 1;
		rCRE <= #(2) 0;
		rADV_n <= #(2) 1; 
		rLB_n <= #(2) 1; 
		rUB_n <= #(2) 1; 
		orAddr <= #(2) 0;
	end
	else begin
		case(state)
			CM_READ_CTRL: begin
				case(timer)
					0:begin
						rCE_n <= #(2) 0;	
						rCRE <= #(2) 1;
						orAddr[22:0] <= iAddr;
						rADV_n <= #(2) 0; // Before rising need to 5ns since orAddr changed
						rLB_n <= #(2) 0; 
						rUB_n <= #(2) 0; 
						end
					//clockPeriod*`tAVS: begin // After tAVS, 5ns we can raise ADV
					// ASSERT 1 cycle is enough if period is more than 5ns
					1: begin
						rADV_n <= #(2) 1;
						end
					//clockPeriod*`tAVS: begin // Addr needs to hold  2ns tAVH
					// ASSERT 1 cycle is enough if period is more than 5ns
					// tOP: Output enable to Valid Output is 20ns
					2: begin
						rCRE <= #(2) 0;
						rOE_n <= 0;
						rLB_n <= #(2) 0; 
						rUB_n <= #(2) 0; 
						// tOP: Output enable to Valid Output is 20ns so 1 cycle
						end
					(`tCO/clockPeriod+1): begin
						// 85ns from CE_n + 1 cycle for sampling
						//rCRE <= #(2) 1;
						//rOE_n <= 1; 
						end
					endcase 
			end
			CM_WRITE_CTRL: begin
			end
			CM_ASYNC_READ: begin
				case(timer)
					0:begin
						rCE_n <= #(2) 0;	
						rWE_n <= #(2) 1;	
						rOE_n <= 0;
						orAddr[22:0] <= iAddr;
						rLB_n <= #(2) 0; 
						rUB_n <= #(2) 0; 
						rADV_n <= #(2) 0;
						end 
					(`tRC/clockPeriod+1):begin
						rCE_n <= #(2) 1;	
						rWE_n <= #(2) 1;	  
						rLB_n <= #(2) 1; 
						rUB_n <= #(2) 1; 
						rADV_n <= #(2) 1;
						rOE_n <= #(2) 1;
						end
					endcase 
			end
			CM_ASYNC_WRITE: begin
				case(timer)
					0:begin
						rCE_n <= #(2) 0;	
						rWE_n <= #(2) 0;	
						rOE_n <= 1;
						orAddr[22:0] <= iAddr;
						data_out <= iData; 
						rLB_n <= #(2) 0; 
						rUB_n <= #(2) 0; 
						rADV_n <= #(2) 0;
						end 
					(`tWC/clockPeriod+1):begin
						rCE_n <= #(2) 1;	
						rWE_n <= #(2) 1;	  
						rLB_n <= #(2) 1; 
						rUB_n <= #(2) 1; 
						rADV_n <= #(2) 1;
						end
					endcase 
			end
			default: begin
				rCRE <= 0; 
				rCE_n <= #(2) 1;
				rOE_n <= #(2) 1;
			end
		endcase
	end
end

// State Machine
reg [2:0] state; // State Variable
reg [12:0] timer; 
//wire [3:0] wOP;  
always@(posedge iClock or posedge iReset) begin
	if(iReset) begin
		// Go to init
		state <= CM_INIT;
		timer <= 0;
	end
	else begin 
		case(state) 
			CM_INIT: begin
			// RAM Initialization (tPU=150us)
				timer <= timer + 1;
				if (timer == (`tPU/clockPeriod)) begin 
					state <= CM_READY; 
				end
				end
			CM_READY: begin
					timer <= 0;
					case(wOP)
						OP_READ_CTRL: state <= CM_READ_CTRL; 
						OP_WRITE_CTRL: state <= CM_WRITE_CTRL;
						OP_ASYNC_READ: state <= CM_ASYNC_READ; 
						OP_ASYNC_WRITE: state <= CM_ASYNC_WRITE;
						default: state <= CM_READY;	
					endcase
				end
			CM_READ_CTRL: begin
					timer <= timer + 1;
					case(timer) 
						5: state <= CM_READY;
					endcase
				end
			CM_ASYNC_READ: begin
					timer <= timer + 1;
					case(timer) 
						(`tRC/clockPeriod+1): state <= CM_READY;
					endcase
				end
			CM_ASYNC_WRITE: begin
					timer <= timer + 1;
					case(timer) 
						(`tWC/clockPeriod+1): state <= CM_READY; 
					endcase
				end
			default: begin 
				state <=  CM_INIT;
				timer <= 0;
				end
		endcase
	end
end
endmodule