// Task
task initialize_vectors;
  $readmemh("init/dividends.txt", dividends);
  $readmemh("init/divisors.txt", divisors);
  $readmemh("init/quotients.txt", quotients);
  $readmemh("init/remainders.txt", remainders);
endtask

task start_division;

  start <= 1'b1;
  @(posedge clk);
  start <= 1'b0;
endtask

