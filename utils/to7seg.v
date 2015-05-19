/**************************************
 *  Conversor a 7 Segmentos           *
 *  Determina segementos a encender   *
 *  para cada palabra HEX             *
 *                                    *
 *  02.05.2010      v1.0              *
 **************************************/

module to7seg(
  input wire [0:0] point,
  input wire [3:0] data_in,
  output reg [7:0] segments
  );

always @(*) begin
  // control del punto
  segments[7] = ~point ;
  // encendido de los 7 segments correspondientes
  case(data_in)
    4'h0: segments[6:0] = 7'b1000000;
    4'h1: segments[6:0] = 7'b1111001;
    4'h2: segments[6:0] = 7'b0100100;
    4'h3: segments[6:0] = 7'b0110000;
    4'h4: segments[6:0] = 7'b0011001;
    4'h5: segments[6:0] = 7'b0010010;
    4'h6: segments[6:0] = 7'b0000010;
    4'h7: segments[6:0] = 7'b1111000;
    4'h8: segments[6:0] = 7'b0000000;
    4'h9: segments[6:0] = 7'b0010000;
    4'hA: segments[6:0] = 7'b0001000;
    4'hB: segments[6:0] = 7'b0000011;
    4'hC: segments[6:0] = 7'b1000110;
    4'hD: segments[6:0] = 7'b0100001;
    4'hE: segments[6:0] = 7'b0000110;
    4'hF: segments[6:0] = 7'b0001110;
  endcase
end

endmodule

