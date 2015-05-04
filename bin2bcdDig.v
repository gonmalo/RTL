/************************************************
 * Modulo conversor bcd unidigito               *
 *                                              *
 * 05.07.2010 v0.1 pseudo original mfiguer      *
 ************************************************/

module bin2bcdDigit(
  input wire  [0:0] MODIN,
  input wire  [0:0] INIT_BAR,
  input wire  [0:0] CLK,
  output reg  [3:0] Q,
  output wire [0:0] MODOUT
);

assign MODOUT = (Q < 5) ? 0 : 1;

always @(posedge CLK) begin
  if (!INIT_BAR)
    Q <= 4'd0;
  else begin
    case (Q)
      4'd5: Q <= {3'd0, MODIN};
      4'd6: Q <= {3'd1, MODIN};
      4'd7: Q <= {3'd2, MODIN};
      4'd8: Q <= {3'd3, MODIN};
      4'd9: Q <= {3'd4, MODIN};
      default: Q <= {Q[2:0], MODIN};
    endcase
  end
end

endmodule
