module single_cycle_arbiter #(
  parameter N = 32
) (
  input   wire          clk,
  input   wire          reset,
  input   wire [N-1:0]  req_i,
  output  wire [N-1:0]  gnt_o
);

  // Write your logic here...
  
  assign gnt_o = (req_i == 0)?  0 : (req_i & (~req_i + 1));
  
  
endmodule

