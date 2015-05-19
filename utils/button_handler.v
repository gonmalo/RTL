/*
 * Button handler module
 * 05.04.2015 - gonzalof
 */

module button_handler #(
  parameter NBUTTONS    = 1,
  parameter CLKPOTDIV   = 21,
  parameter DBSTAGES    = 16,
  parameter EDGESATGES  = 2
  )(
  input  wire [0:0] clk,
  input  wire [NBUTTONS-1:0] btn_in,
  output wire [NBUTTONS-1:0] btn_out
  );

wire [0:0]  clk_slow;
wire [NBUTTONS-1:0] btn_deb;

slower_clk #(.POT(CLKPOTDIV)) clk_divider(
  .clk(clk),
  .rst(1'b0),
  .clk_slow(clk_slow)
  );

genvar i;
generate
  for( i=0; i<NBUTTONS; i=i+1) begin:botonera
    if(DBSTAGES>1) begin
      debounce #(.ETAPAS(DBSTAGES)) the_debouncer(
        .btn(btn_in[i]),
        .clk(clk_slow),
        .d_btn(btn_deb[i])
      );
    end else begin
      assign btn_deb[i] = btn_in[i];
    end

    if(EDGESATGES>1) begin
      oneShot #(.SHIFT(EDGESATGES)) edge_catcher(
        .sigIn(btn_deb[i]),
        .clk(clk),
        .sigOut(btn_out[i])
      );
    end else begin
      assign btn_out[i] = btn_deb[i];
    end
  end
endgenerate

endmodule
