module seq_generator (
  input   wire        clk,
  input   wire        reset,

  output  wire [31:0] seq_o
);

  // Write your logic here...
  reg [31:0] seq_q0;
  reg [31:0] seq_q1;
  reg [31:0] seq_q2;
  reg [31:0] seq_result;
  
 always @(posedge clk or posedge reset) begin
    if(reset) begin
       seq_q0<=1;
  		 seq_q1<=1;
 		   seq_q2<=0;
    end
    else begin
      seq_q2<=seq_q1;
      seq_q1<=seq_q0;
      seq_q0<=seq_q2+seq_q1;
    end
  end
  
  assign seq_o = seq_q2;
endmodule
