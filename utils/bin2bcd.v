module bin2bcd(
	input clock,
	input reset,
	input  binStream, 
	output overFlow,
	output [3:0] bcd
	);
	reg [3:0] bcd_reg;
	wire [3:0] bcd_p3;
	 
	assign bcd  = bcd_reg;
	assign bcd_p3 = bcd_reg + 3;
	assign overFlow = (bcd_reg >= 5) ? bcd_p3[3] : bcd_reg[3];
	
	always@(posedge clock or posedge reset) begin
		if(reset) begin 
			bcd_reg <= 0; 
		end
		else begin
			if(bcd_reg >= 5)
				bcd_reg <= {bcd_p3[2:0],binStream};
			else
				bcd_reg <= {bcd_reg[2:0],binStream};
		end
	end
endmodule
