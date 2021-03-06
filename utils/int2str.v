module int2str #(parameter pBitWidth=16, pBins=4) (
	input iClock,
	input iReset,
	input [pBitWidth-1:0] iBinary,
	output [2*4*pBins-1:0] oString,
	output oDone
	);

	wire [pBins-1:0] of;
	reg [$clog2(pBitWidth)-1:0] state;
	reg [pBitWidth-1:0]iBinary_Latched;
	wire [4*pBins-1:0] oBCD;

	// State control
	always@(posedge iClock or posedge iReset) begin
		if(iReset) begin
			state <= 0;
		end
		else begin
			case(state)
				pBitWidth-1: state <=0;
			   	default: state <= state + 1;	
			endcase
		end
	end
	
	// Output Control
	assign oDone = (state == pBitWidth-1) ? 1 : 0;
	
	always@(posedge iClock or posedge iReset) begin
		if(iReset) begin
			iBinary_Latched <= iBinary;
		end
		else begin
			if(state == pBitWidth-1 )
				iBinary_Latched <= iBinary; 
			else 
				iBinary_Latched <= {iBinary_Latched[pBitWidth-2:0],1'b0};
		end
	end

	// BCD Array
	assign oString[7:0] = { 4'h3, oBCD[3:0]};
	bin2bcd \bcd_array[0].uBCD (
		.clock(iClock), 
		.reset(iReset),  
		.binStream(iBinary_Latched[pBitWidth-1]),  
		.overFlow(of[0]),
		.bcd(oBCD[pBitWidth/4-1:0])
	);
	
	genvar c;
	generate
	for(c=1; c < pBitWidth/4; c=c+1 ) begin : bcd_array
		assign oString[(c+1)*8-1:c*8] = {4'h3, oBCD[(c+1)*4-1:c*4]};
		bin2bcd uBCD (
			.clock(iClock), 
			.reset(iReset),  
			.binStream(of[c-1]),  
			.overFlow(of[c]),
			.bcd(oBCD[(c+1)*4-1:c*4])
		);
	end
	endgenerate
	endmodule
