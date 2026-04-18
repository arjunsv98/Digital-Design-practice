

module atomic_counters (
  input  wire            clk,
  input  wire            reset,
  input  wire            trig_i,
  input  wire            req_i,
  input  wire            atomic_i,
  output wire            ack_o,
  output wire[31:0]      count_o
);

  // --------------------------------------------------------
  // Internal wire and regs
  // --------------------------------------------------------
  reg  [63:0] count_q;
  wire [63:0] count;

  reg  [31:0] count_msb;

  reg         atomic_q;
  reg         req_q;

  always @(posedge clk or posedge reset)
    if (reset) begin
      atomic_q <= 1'b0;
      req_q    <= 1'b0;
    end
    else begin
      atomic_q <= atomic_i;
      req_q    <= req_i;
    end

  always @(posedge clk or posedge reset)
    if (reset)
      count_q[63:0] <= 64'h0;
    else
      count_q[63:0] <= count;

  assign count[63:0] = count_q[63:0] + {{63{1'b0}}, trig_i};

  always @(posedge clk or posedge reset)
    if (reset)
      count_msb <= 32'h0;
    else if (atomic_q)
      count_msb <= count_q[63:32];

  // -------------------------------------------------------
  // Output assignments
  // --------------------------------------------------------
  assign ack_o = req_q;
  assign count_o[31:0] = req_q ? (atomic_q ? count_q[31:0] : count_msb[31:0])
                               : 32'h0;

endmodule