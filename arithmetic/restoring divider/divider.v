module rest_divider(Q, remainder, ready, dividend, divisor, start, reset, clk);
  parameter NF = 8; //número de bits de la parte fraccionaria
  parameter NI = 8; //número de bits de la parte entero
  
  output reg [NF + NI - 1:0] Q;    //quotient (3 for int, 9 for frac)
  output [NI - 1:0] remainder;    //remainder
  output reg ready;       //flag
  input [NI - 1:0] dividend; //18 bits sin signo
  input [NI - 1:0] divisor;  //18 bits sin signo
  input start;
  input reset;
  input clk;

  reg [NF + NI - 1:0] D; //divisor (pre-scaled)
  reg [NF + NI - 1:0] R;    //remainder
  reg state;
  reg [3:0] n;
  //auxiliary variable for comparison between 2*R and D
  wire signed [NF + NI - 1 + 1:0] Z; //it must be same width as D, plus one bit for sign
  
  assign Z = {R, 1'b0} - D; // 2*R - D = R << 1 - D
  assign remainder = R[NF + NI - 1 : NI];

  initial begin
    D = 0;
    R = 0;
    state = 0;
    n = 0;
    Q = 0;
    ready = 0;
  end
  
  always @(posedge clk) begin
    case (state)
      0: begin    
        if (start) begin
                D <= {divisor, 8'd0}; // prescaling
                R <= dividend;  // initially, R = dividend (X) 
                state <= 1;
        end
        else
                state <= 0;
        ready <= 0;
        n <= 0;
      end
      1: begin
        if (Z[NF + NI]) begin //if sign-bit = 1 (if R < 0)
                R <= R << 1; // R = 2R
                Q[NI + NF - 1 - n] <= 0; //q(NI + NF - 1 - n) = 0;
        end
        else begin
                R <= Z[NF + NI - 1:0]; // R = Z (without sign... this assumes Z > 0)
                Q[NI + NF  -1 - n] <= 1; //q(NI + NF - 1 - n) = 1;                      
        end
        if (n == NI + NF - 1) begin
                state <= 0; //return to state 0 (finish)
                ready <= 1; //activate flag
        end
        else begin 
                n <= n + 1; //increment counter (Q index) 
                state <= 1; //stay in state 1
        end     
      end
    endcase
  end
endmodule
