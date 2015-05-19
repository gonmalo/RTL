module rotary_encoder (
  input wire  [0:0] clk,
  input wire  [2:0] rotary_in,
  output reg  [0:0] rotary_moved,
  output reg  [0:0] rotary_dir
  );

reg [0:0] rotary_a, rotary_b, rotary_p,
          rotary_q1, rotary_q2;

always @(posedge clk) begin
   rotary_a  <= rotary_in[0];
   rotary_b  <= rotary_in[1];
   rotary_p  <= rotary_in[2];
end
 
always @(posedge clk) begin
    rotary_q1 <= 1'b0;
    rotary_q2 <= 1'b0;
  case({rotary_a, rotary_b})
  2'b00: begin
    //rotary_q1 <= 1'b0;
    rotary_q2 <= rotary_q2;
  end 
  2'b01: begin
    rotary_q1 <= rotary_q1;
    //rotary_q2 <= 1'b0;
  end 
  2'b10: begin
    rotary_q1 <= rotary_q1;
    rotary_q2 <= 1'b1;
  end
  2'b11: begin
    rotary_q1 <= 1'b1;
    rotary_q2 <= rotary_q2;
  end
  default: begin
    rotary_q1 <= rotary_q1;
    rotary_q2 <= rotary_q2;
  end
  endcase
end 

oneShot #(.SHIFT(2)) edge_detector(
  .sigIn(rotary_q1),
  .clk(clk),
  .sigOut(prev_rotary_q1)
  );

always @(posedge clk) begin
  rotary_moved  <= 1'b0;
  rotary_dir    <= 1'b0;

  if(prev_rotary_q1) begin
    rotary_moved  <= 1'b1;
    rotary_dir    <= rotary_q2;
  end else
    rotary_dir    <= rotary_dir;
end

endmodule

