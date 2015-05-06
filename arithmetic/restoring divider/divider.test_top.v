module divider_test_top;
  parameter clock_cycle = 100;
  parameter NF = 8;
  parameter NI = 8;
  reg clk;

  wire [NF + NI - 1:0] Q;
  wire [NI - 1:0] remainder;    //partial remainder
  wire ready;       //flag
  reg reset;
  reg [NI - 1:0] dividend; //18 bits sin signo
  reg [NI - 1:0] divisor;  //18 bits sin signo
  reg start;

  // Data for simulation
  reg [7:0] dividends [7:0];      
  reg [7:0] divisors [7:0]; 
  reg [15:0] quotients [7:0];
  reg [7:0] remainders [7:0]; 
  int i;
  
  `include "rtl/tasks.v"
  
  // DUT instantiation
  rest_divider divider(
    .Q(Q),
    .remainder(remainder),
    .ready(ready),
    .reset(reset),
    .dividend(dividend),
    .divisor(divisor),
    .start(start),
    .clk(clk)
    );
  
  // Clock generation
  initial begin 
    clk = 1'b0;
    forever begin
      #(clock_cycle/2)
        clk = ~clk;
    end
  end

  // Testbench program
  initial begin
    initialize_vectors();

    for (i = 0; i < 8; i = i+1) begin
        dividend <= dividends[i];
        divisor <= divisors[i];
        start_division();
        repeat (17) @(posedge clk);
        //$display("i = %0d", i);
        c2: assert (Q == quotients[i]) $display("Q[%0d] = %h : correct", i, quotients[i]);
        else $display("Q[%0d] = %h != %h : not correct", i, Q, quotients[i]);
        c3: assert (remainder == remainders[i]) $display("R[%0d] = %h : correct", i, remainders[i]);
        else $display("R[%0d] = %h != %h : not correct", i, remainder, remainders[i]);
        @(posedge clk);
    end

    @(posedge clk);
    $finish;
  end

endmodule

module checker (Q, remainder, ready, reset, dividend, divisor, start, clk);
  parameter NF = 8;
  parameter NI = 8;
  input clk, ready;
  input [NF + NI - 1:0] Q;
  input [NI -1 : 0] remainder;
  output reset, start;
  output [NI - 1:0] dividend, divisor;//18 bits sin signo

  c1: assert property (@ (posedge clk)
   $rose(start) |-> ##17 ready ) $display("Signal 'ready' correctly asserted after 'start'");
  else $fatal("Signal 'ready' was not asserted properly");

 // c2: assert property (@(posedge clk)
   
endmodule

module my_bindings;
// bind to module DESIGN -> connected to all instances
 bind rest_divider checker my_checker_1 (
   .Q(Q),
   .remainder(remainder),
   .ready(ready),
   .reset(reset),
   .dividend(dividend),
   .divisor(divisor),
   .start(start),
   .clk(clk)
  );
endmodule: my_bindings


