/******************************************
 * Manejador para Iluminar 2 visores      *
 *                                        *
 * 02.05.2010      v1.0                   *
 * 18.05.2010      v1.1                   *
 * 27.11.2011      v0.9 (-0.2)            *
 ******************************************/

module displayDrv #(
  parameter NDIGITS = 2
  )(
  input wire  [4*(NDIGITS)-1:0] bcd_bus,
  input wire  [NDIGITS-1:0]     points,
  input wire  [0:0]             clk,
  output wire [NDIGITS-1:0]     catodes,
  output wire [7:0]             segments
  );

// contador y dato auxiliar
reg [NDIGITS-1:0] pos;

wire [7:0] int_segments [NDIGITS-1:0];

//se ingresa la palabra HEX correspondiente y regresa el bus de segmentos a ilumniar
genvar i;
generate
  for( i=NDIGITS; i>0; i=i-1) begin: seg_driver
    to7seg convertidor (
      .data_in(bcd_bus[4*i-1:4*(i-1)]), 
      .segments(int_segments[i-1]), 
      .point(points[i-1])
    );
  end
endgenerate

always @(posedge clk) begin
  if (pos < NDIGITS-1)
    pos <= pos + 1'b1;
  else 
    pos <= 1'b0;
end

assign segments = int_segments[pos];
assign point    = points[pos];
assign catodes  = ~(1'b1 << pos);

endmodule

