module palindrome3b (
  input   wire        clk,
  input   wire        reset,

  input   wire        x_i,

  output  wire        palindrome_o
);

  // Write your logic here...
  
  wire [1:0] counter;
  reg [1:0] counter_q;
  
  wire [1:0] bit_seen;
  reg [1:0] bit_seen_q;
  
  always @(posedge clk or posedge reset) begin
    if(reset) begin
      counter_q <= 0;
      bit_seen_q <= 0;
    end
    else begin
      counter_q <= counter;
      bit_seen_q<=bit_seen;
    end
  end
  
  assign counter= counter_q[1] ? counter_q:counter_q+1;
  
  assign bit_seen={bit_seen_q[0],x_i};
  
  assign palindrome_o= counter_q[1] && (bit_seen_q[1] == x_i);
  
  

endmodule