/************************************************
 * Modulo conversor palabra binaria de 12 bits  *
 * en palabra BCD de 16 bits                    *
 *                                              *
 * 08.12.2011 v0.1                              *
 ************************************************/

module bin2bcdMultidigit #(
  parameter nDigits = 2,
  parameter nBits = 4
  )(
  input wire  [nBits-1:0] bin,
  input wire  [0:0] load,
  input wire  [0:0] clk,
  output reg  [0:0] ready,
  output reg  [nDigits*4-1:0] bcd
);

// wires internos
wire [nDigits*4-1:0] bcdTmp;
wire [nDigits:0] carry;
//registros
reg [nBits-1:0] shiftReg;
reg shift;

// asigna el primer carry
assign carry[0] = shiftReg[nBits-1];

// instancia el módulo que convierte cada cifra usando arrray
bin2bcdDigit dig[nDigits-1:0] (
  .Q(bcdTmp[4*nDigits-1:0]),
  .MODOUT(carry[nDigits:1]),
  .MODIN(carry[nDigits-1:0]),
  .INIT_BAR(shift),
  .CLK(clk)
);

// instancia el módulo que convierte cada cifra usando generate 
/*
genvar i;
generate
for( i=1; i<= nDigits; i=i+1) begin: bin2bcdar
  bin2bcdDigit dig (
    .Q(bcdTmp[4*i-1:4*(i-1)]),
    .MODOUT(carry[i]),
    .MODIN(carry[i-1]),
    .INIT_BAR(shift),
    .CLK(clk)
  );
end
endgenerate
*/
/*
bin2bcdDigit dig0(.Q(bcdTmp[3:0]), .MODOUT(carry[1]), .MODIN(carry[0]), .INIT_BAR(shift), .CLK(clk));
bin2bcdDigit dig1(.Q(bcdTmp[7:4]), .MODOUT(carry[2]), .MODIN(carry[1]), .INIT_BAR(shift), .CLK(clk));
*/
// maquina de estados
reg [nBits-1:0] state;

always @(posedge clk) begin
  if (state == 0) begin
    if (load) begin
      shiftReg <= bin;
      shift <= 1;
      state <= 1;
      ready <= 0;
    end else begin
      shift <= 0;
      state <= 0;
      ready <= 0;
    end
  end else if (state < nBits+1)  begin
    shiftReg <= shiftReg << 1;
    shift <= 1;
    ready <= 0;
    state <= state + 1;
  end else begin
    shift <= 0;
    state <= 0;
    ready <= 1;
    bcd <= bcdTmp;
  end
end


endmodule
