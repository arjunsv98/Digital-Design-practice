module low_power_channel (
  input   wire          clk,
  input   wire          reset,

  // Wakeup interface
  input   wire          if_wakeup_i,

  // Write interface
  input   wire          wr_valid_i,
  input   wire [7:0]    wr_payload_i,

  // Upstream flush interface
  output  wire          wr_flush_o,
  input   wire          wr_done_i,

  // Read interface
  input   wire          rd_valid_i,
  output  wire [7:0]    rd_payload_o,

  // Q-channel interface
  input   wire          qreqn_i,
  output  wire          qacceptn_o,
  output  wire          qactive_o

);

 	parameter s0=2'b00, s1=2'b01, s2=2'b10;
  reg [1:0] current_state,next_state;
  
  wire skidBuffer_ready_i;
  wire skidBuffer_valid_o;
  wire [7:0] skidBuffer_data_o;
  
  wire fifo_full;
  wire fifo_empty;
  
  always@(posedge clk or posedge reset) begin
    if(reset) begin
      current_state<=2'b00;
    end
    else begin
      current_state<=next_state;
    end   
  end
  
  always_comb begin
    case(current_state)
      s0 : begin
        if(qreqn_i==0) 
          next_state=s1;
        else
          next_state=s0;
      end
      s1:begin
        if (wr_done_i && fifo_empty) begin
          next_state=s2;
        end
        else begin
          next_state=s1;
        end
      end
      s2:begin
        if (qreqn_i==1)
          next_state=s0;
        else
          next_state=s2;
      end
      default: next_state = s0;
    endcase
  end
  
  qs_skid_buffer # (.DATA_W(8)) mySkidBuffer (
    .clk(clk),
    .reset(reset),
    .i_valid_i(skidBuffer_ready_i && wr_valid_i),
    .i_data_i(wr_payload_i),
    .i_ready_o(skidBuffer_ready_i),
    .e_ready_i(!(fifo_full)),
    .e_valid_o(skidBuffer_valid_o),
    .e_data_o(skidBuffer_data_o)
  );
  
  
  qs_fifo # (.DATA_W(8),.DEPTH (6)) myFifo (
    .clk(clk),
    .reset(reset),
    .push_i(skidBuffer_valid_o &! fifo_full),
    .push_data_i(skidBuffer_data_o),
    .pop_i(rd_valid_i),
    .pop_data_o(rd_payload_o),
    .empty_o(fifo_empty),
    .full_o(fifo_full)
  );
  
  assign qacceptn_o = (current_state==s2) ? 0 : 1;
  assign qactive_o = (current_state == s2) ? if_wakeup_i : 1'b1;
  assign wr_flush_o = (current_state==s1);

endmodule
