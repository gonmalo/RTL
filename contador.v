/******************************************
 *  Contador (Nbits) Bidireccional        *
 *                                        *
 *  19.11.2011      v1.0                  *
 ******************************************/

module contador #(
  parameter WIDTH = 4
  )(
  input wire  [0:0] nxt,
  input wire  [0:0] dir,
  input wire  [0:0] rst,
  output wire [0:0] empty,
  output wire [0:0] full,
  output reg  [WIDTH-1:0] cuenta
 );

assign empty = ~|cuenta;
assign full = &cuenta;

// contador con rst asinc
always @(posedge nxt, posedge rst) begin
  // Caso de reset se llevan las salidas a 0
  if(rst)
    cuenta <= {WIDTH {1'b0}} ;
  else begin
  // Se incrementa o decrementa en 1, según corresponda
    if(dir)
      cuenta <= full ? cuenta : cuenta + 1'b1;
    else
      cuenta <= empty ? cuenta : cuenta - 1'b1;
  end
end

endmodule
