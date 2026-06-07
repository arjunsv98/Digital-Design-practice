module qs_fifo #(
  parameter DATA_W = 4,
  parameter DEPTH  = 4
)(
  input  wire               clk,
  input  wire               reset,          // active-high, async
  input  wire               push_i,
  input  wire [DATA_W-1:0]  push_data_i,
  input  wire               pop_i,
  output wire [DATA_W-1:0]  pop_data_o,
  output wire               empty_o,
  output wire               full_o
);
  parameter PTR_WIDTH = $clog2(DEPTH);
  reg [PTR_WIDTH:0] w_ptr, r_ptr;       // extra MSB to distinguish full from empty
  reg [DATA_W-1:0]  fifo[DEPTH];
  reg [DATA_W-1:0]  data_out;
  wire wrap_around;

  // Write pointer + memory, async active-high reset
  always@(posedge clk or posedge reset) begin
    if(reset) begin
      w_ptr <= 0;
    end else if(push_i & !full_o) begin
      fifo[w_ptr[PTR_WIDTH-1:0]] <= push_data_i;
      w_ptr <= w_ptr + 1;
    end
  end

  // Read pointer + data_out, async active-high reset
  always@(posedge clk or posedge reset) begin
    if(reset) begin
      r_ptr    <= 0;
      data_out <= 0;
    end else if(pop_i & !empty_o) begin
      data_out <= fifo[r_ptr[PTR_WIDTH-1:0]];
      r_ptr <= r_ptr + 1;
    end
  end

  assign pop_data_o  = data_out;
  assign wrap_around = w_ptr[PTR_WIDTH] ^ r_ptr[PTR_WIDTH];
  assign full_o      = wrap_around & (w_ptr[PTR_WIDTH-1:0] == r_ptr[PTR_WIDTH-1:0]);
  assign empty_o     = (w_ptr == r_ptr);
endmodule