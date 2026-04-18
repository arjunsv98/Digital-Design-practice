module div_by_three (
  input   wire    clk,
  input   wire    reset,

  input   wire    x_i,

  output  wire    div_o

);

  // --------------------------------------------------------
  // Internal wire and regs
  // --------------------------------------------------------
  
  localparam s0=2'b00;
  localparam s1=2'b01;
  localparam s2=2'b10;
  
  reg div;
  
  reg [1:0] curr_state;
  reg [1:0] next_state;
  
  always @(posedge clk or posedge reset) begin
    if(reset) begin
      curr_state<=s0;
    end
    else begin
      curr_state<=next_state;
    end
  end
  
always_comb begin   
  case (curr_state)   
      s0: begin
        if(x_i) begin
          next_state=s1;
           div=0;
        end
        else begin
           next_state=s0;
          div = 1;
        end
      end
      s1: begin
        if(!x_i) begin
          next_state=s2;
          div = 0;
        end
        else begin
          next_state=s0;
          div = 1;
        end
      end    
      s2: begin
        if(x_i) begin
          next_state=s2;
          div = 0;
        end
        else begin
          next_state=s1;
          div = 0;
        end
      end    
      default: begin
        next_state=s0;
      end   
    endcase  
  end
  
  assign div_o =div;

endmodule