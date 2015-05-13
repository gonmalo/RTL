/************************************************
 * Modulo debouncer  (antireboteador)           *
 *                                              *
 * 05.07.2010 v0.1                              *
 ************************************************/

module debounce #(
  parameter ETAPAS=16
  )(
  input wire  [0:0] btn,
  input wire  [0:0] clk,
  output wire [0:0] d_btn
 );

// Add assert for ETAPAS>0
reg [ETAPAS-1:0] shift;
// Output
assign d_btn = &(shift);

always @(posedge clk)
  shift <= {shift[ETAPAS-2:0], btn};

endmodule
