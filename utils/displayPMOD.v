module displayPMOD #(
  parameter [2:0] NDIGITS = 2,
  parameter [2:0] NBITS = 4
  ) (
  input wire  [NBITS-1:0]   binary_in,
  input wire  [0:0]         clk,
  output wire [0:0]         catodes,  // Shared pin on PMOD
  output wire [7:0]         segments
  );

wire [0:0]  cat_out,
            seg_out,
            conv_ready,
            clk_slow2,
            clk_slow;

reg [0:0]   conv_load;

wire [NBITS*NDIGITS-1:0]  conv_bcd;
wire [6:0]                seg_tmp;
wire [NDIGITS-1:0]        catodes_tmp;

slower_clk #(.POT(16)) clk_divider2(
  .clk(clk),
  .rst(1'b0),
  .clk_slow(clk_slow2)
  );

bin2bcdMultidigit #(
  .nDigits(NDIGITS),
  .nBits(NBITS)
  ) converter(
  .bin(binary_in),
  .load(conv_load),
  .clk(clk),
  .ready(conv_ready),
  .bcd(conv_bcd)
);

displayDrv #(.NDIGITS(NDIGITS)) seven_seg(
  .bcd_bus(conv_bcd),
  .points(1'b0),
  .clk(clk_slow2),
  .catodes(catodes_tmp),
  .segments(seg_tmp)
);

assign catodes = catodes_tmp[0];
assign segments = ~seg_tmp;

always @ (posedge clk) begin
  conv_load <= conv_ready ? 1'b1 : 1'b0;
end

endmodule
