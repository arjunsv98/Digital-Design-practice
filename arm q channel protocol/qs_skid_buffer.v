module qs_skid_buffer #(
  parameter DATA_W = 8
)(
  input   wire                clk,
  input   wire                reset,
  input   wire                i_valid_i,
  input   wire [DATA_W-1:0]   i_data_i,
  output  wire                i_ready_o,
  input   wire                e_ready_i,
  output  wire                e_valid_o,
  output  wire [DATA_W-1:0]   e_data_o
);
  reg buffered;
  reg [DATA_W-1:0] buffered_value;

  always@(posedge clk or posedge reset) begin
    if(reset) begin
      buffered<=0;
      buffered_value<=0;
    end
    else if(i_valid_i && i_ready_o && !(e_ready_i && e_valid_o)) begin
      buffered<=1;
      buffered_value<=i_data_i;
    end
    else if(!(i_valid_i && i_ready_o) && (e_ready_i && e_valid_o)) begin
      buffered<=0;
      buffered_value<=0;
    end
  end
  assign i_ready_o = (buffered == 0);
  assign e_valid_o = (buffered == 0)?i_valid_i:buffered;
  assign e_data_o = (buffered == 0)?i_data_i:buffered_value;
endmodule