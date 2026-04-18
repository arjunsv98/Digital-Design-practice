module events_to_apb (
  input   wire         clk,
  input   wire         reset,
  input   wire         event_a_i,
  input   wire         event_b_i,
  input   wire         event_c_i,
  output  wire         apb_psel_o,
  output  wire         apb_penable_o,
  output  wire [31:0]  apb_paddr_o,
  output  wire         apb_pwrite_o,
  output  wire [31:0]  apb_pwdata_o,
  input   wire         apb_pready_i
);
 
  parameter IDLE   = 2'b00;
  parameter SETUP  = 2'b01;
  parameter ACCESS = 2'b10;
  parameter GAP    = 2'b11;
 
  reg [1:0] current_state;
  reg [1:0] next_state;
 
  reg [31:0] apb_paddr_q;
  reg [31:0] apb_pwdata_q;
 
  reg [3:0] event_a;
  reg [3:0] event_b;
  reg [3:0] event_c;
 
  // ── State register ──────────────────────────────────────────
  always @(posedge clk or posedge reset) begin
    if (reset)
      current_state <= IDLE;
    else
      current_state <= next_state;
  end
 
  // ── Counter block ────────────────────────────────────────────
  // In ACCESS+PREADY: subtract what was sent, preserve new events
  // Otherwise: increment on each event pulse independently
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      event_a <= 0;
      event_b <= 0;
      event_c <= 0;
    end
    else begin
			if (current_state == ACCESS && apb_pready_i) begin
    		if (apb_paddr_q == 32'hABBA0000) begin
        	event_a <= event_a - apb_pwdata_q[3:0] + event_a_i;
        	if (event_b_i) event_b <= event_b + 1;  // still counting
        	if (event_c_i) event_c <= event_c + 1;  // still counting
    		end
    		else if (apb_paddr_q == 32'hBAFF0000) begin
        	event_b <= event_b - apb_pwdata_q[3:0] + event_b_i;
        	if (event_a_i) event_a <= event_a + 1;
        	if (event_c_i) event_c <= event_c + 1;  // still counting ✅
    		end
   		 else if (apb_paddr_q == 32'hCAFE0000) begin
        	event_c <= event_c - apb_pwdata_q[3:0] + event_c_i;
        	if (event_a_i) event_a <= event_a + 1;
        	if (event_b_i) event_b <= event_b + 1;
    	 end
			end
      else begin
        if (event_a_i) event_a <= event_a + 1;
        if (event_b_i) event_b <= event_b + 1;
        if (event_c_i) event_c <= event_c + 1;
      end      
    end
  end
 
  // ── Addr/data latch block ────────────────────────────────────
  // Case 1: fresh event arriving in IDLE
  //         use event_x + 1 because counter not yet incremented
  // Case 2: returning from GAP with pending counts
  //         use counter directly, already fully settled
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      apb_paddr_q  <= 0;
      apb_pwdata_q <= 0;
    end
    else begin
      if (event_a_i && current_state == IDLE) begin
        apb_paddr_q  <= 32'hABBA0000;
        apb_pwdata_q <= {28'b0,event_a} + 1 + 32'b0;
      end
      else if (event_b_i && current_state == IDLE) begin
        apb_paddr_q  <= 32'hBAFF0000;
        apb_pwdata_q <= {28'b0,event_b} + 1 + 32'b0;
      end
      else if (event_c_i && current_state == IDLE) begin
        apb_paddr_q  <= 32'hCAFE0000;
        apb_pwdata_q <= {28'b0,event_c} + 1 + 32'b0;
      end
      else if (current_state == GAP) begin
        if (event_a > 0) begin
          apb_paddr_q  <= 32'hABBA0000;
          apb_pwdata_q <= {28'b0,event_a};
        end
        else if (event_b > 0) begin
          apb_paddr_q  <= 32'hBAFF0000;
          apb_pwdata_q <= {28'b0,event_b};
        end
        else if (event_c > 0) begin
          apb_paddr_q  <= 32'hCAFE0000;
          apb_pwdata_q <= {28'b0,event_c};
        end
      end
    end
  end
 
  // ── Next state logic ─────────────────────────────────────────
  always @(*) begin
    case (current_state)
      IDLE: begin
        if (event_a_i || event_b_i || event_c_i)
          next_state = SETUP;
        else
          next_state = IDLE;
      end
 
      SETUP: begin
        next_state = ACCESS;
      end
 
      ACCESS: begin
        if (apb_pready_i)
          next_state = GAP;
        else
          next_state = ACCESS;
      end
 
      GAP: begin
        // skip IDLE if pending counts, data already latched this cycle
        if (event_a > 0 || event_b > 0 || event_c > 0)
          next_state = SETUP;
        else
          next_state = IDLE;
      end
 
      default: next_state = IDLE;
    endcase
  end
 
  // ── Output assignments ───────────────────────────────────────
  assign apb_psel_o    = (current_state == SETUP || current_state == ACCESS);
  assign apb_penable_o = (current_state == ACCESS);
  assign apb_pwrite_o  = 1'b1;
  assign apb_paddr_o   = apb_paddr_q;
  assign apb_pwdata_o  = apb_pwdata_q;
 
endmodule