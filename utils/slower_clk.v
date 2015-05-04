/************************************
 *  Divisor de frecuencia del clk   *
 *                                  *
 *  04.05.2010      v1.1            *
 ************************************/
module slower_clk #(
  parameter POT=17
  )(
  input wire [0:0] clk,
  input wire [0:0] rst,
  output reg [0:0] clk_slow
 );

// registro auxiliar
reg [POT:0] amortiguador;

// Agregar un assert! POT > 0
// se divide el clock por una potencia de 2^POT
always@(posedge clk) begin
  if(rst) begin
    clk_slow <= 1'b0;
	 amortiguador <= {POT+1 {1'b0}};
  end else begin
  amortiguador <= amortiguador + 1'b1;
    if(amortiguador[POT] == 1'b1) begin
      clk_slow <= ~clk_slow;
      amortiguador <= {POT+1 {1'b0}};
    end
  end
end

endmodule
