/*
 * Simple version of One shot module to detec edges of a debounced button
 *
 */

module oneShot(
  input wire  [0:0] sigIn,
  input wire  [0:0] clk,
  output wire [0:0] sigOut
  );

  reg [1:0] shift;
  sigOut <= (shift == 2'b01) ? 1 : 0;

  always @(posedge clk) begin
    shift <= {shift[0], sigIn};

endmodule
