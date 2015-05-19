/*
 * Simple version of One shot module to detect edges of a debounced button
 *
 * Enhanced version including parameter fo the shift register chain. It will
 * allow to easily implement dual flop clock synchronizer.
 */

module oneShot #(
  parameter [7:0] SHIFT = 2
  ) (
  input wire  [0:0] sigIn,
  input wire  [0:0] clk,
  output reg  [0:0] sigOut
  );

reg [SHIFT-1:0] shift;
//assign sigOut = (shift == 2'b01) ? 1 : 0;

always @(posedge clk) begin
  shift <= {shift[SHIFT-2:0], sigIn};
end

always @(*) begin
  sigOut <= 1'b0;
  case ({shift[SHIFT-1], &shift[SHIFT-2:0]})
    2'b01   : sigOut <= 1'b1;
    default : sigOut <= 1'b0;
  endcase
end

endmodule
