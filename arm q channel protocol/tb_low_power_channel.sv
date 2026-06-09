//==============================================================
// Basic testbench for low_power_channel
// Compile with the DUT + submodules, e.g.:
//   iverilog -g2012 -o sim low_power_channel.sv qs_fifo.sv \
//            qs_skid_buffer.sv tb_low_power_channel.sv
//   vvp sim
//==============================================================
`timescale 1ns/1ps

module tb_low_power_channel;

  // DUT signals
  reg         clk, reset;
  reg         if_wakeup_i;
  reg         wr_valid_i;
  reg  [7:0]  wr_payload_i;
  wire        wr_flush_o;
  reg         wr_done_i;
  reg         rd_valid_i;
  wire [7:0]  rd_payload_o;
  reg         qreqn_i;
  wire        qacceptn_o;
  wire        qactive_o;

  integer errors = 0;

  // DUT
  low_power_channel dut (
    .clk(clk), .reset(reset),
    .if_wakeup_i(if_wakeup_i),
    .wr_valid_i(wr_valid_i), .wr_payload_i(wr_payload_i),
    .wr_flush_o(wr_flush_o), .wr_done_i(wr_done_i),
    .rd_valid_i(rd_valid_i), .rd_payload_o(rd_payload_o),
    .qreqn_i(qreqn_i), .qacceptn_o(qacceptn_o), .qactive_o(qactive_o)
  );

  // 100 MHz clock
  always #5 clk = ~clk;

  // simple check helper
  task check(input cond, input string msg);
    begin
      if (cond) $display("  [PASS] %s", msg);
      else begin $display("  [FAIL] %s", msg); errors = errors + 1; end
    end
  endtask

  // drive one write beat
  task do_write(input [7:0] d);
    begin
      @(negedge clk); wr_valid_i = 1; wr_payload_i = d;
      @(negedge clk); wr_valid_i = 0;
    end
  endtask

  initial begin
    // init
    clk = 0; reset = 1;
    if_wakeup_i = 0; wr_valid_i = 0; wr_payload_i = 0;
    wr_done_i = 0; rd_valid_i = 0; qreqn_i = 1;

    // ---- reset ----
    repeat (2) @(negedge clk);
    reset = 0;
    @(negedge clk);
    $display("TEST 1: out of reset");
    check(qacceptn_o === 1'b1, "qacceptn deasserted (=1) out of reset");
    check(qactive_o  === 1'b1, "qactive high in RUN");
    check(wr_flush_o === 1'b0, "wr_flush low in RUN");

    // wr_done can be high while running
    wr_done_i = 1;

    // ---- write some data ----
    $display("TEST 2: writes accepted in RUN");
    do_write(8'hA1);
    do_write(8'hB2);
    do_write(8'hC3);
    check(qacceptn_o === 1'b1, "still in RUN while writing");

    // ---- request low power ----
    $display("TEST 3: qreqn low -> REQUEST asserts flush");
    @(negedge clk); qreqn_i = 0;
    @(negedge clk);
    check(wr_flush_o === 1'b1, "wr_flush asserted in REQUEST");
    check(qacceptn_o === 1'b1, "qacceptn still 1 (not yet quiescent)");

    // ---- drain the FIFO so it can reach STOPPED ----
    $display("TEST 4: drain FIFO, expect STOPPED (qacceptn=0)");
    rd_valid_i = 1;
    repeat (8) @(negedge clk);
    rd_valid_i = 0;
    @(negedge clk);
    check(qacceptn_o === 1'b0, "qacceptn asserted (=0) in STOPPED");
    check(wr_flush_o === 1'b0, "wr_flush deasserted in STOPPED");

    // ---- wakeup while stopped ----
    $display("TEST 5: wakeup raises qactive while STOPPED");
    @(negedge clk); if_wakeup_i = 1;
    @(negedge clk);
    check(qactive_o  === 1'b1, "qactive high on wakeup");
    check(qacceptn_o === 1'b0, "qacceptn still 0 (controller hasn't responded)");

    // ---- controller grants exit ----
    $display("TEST 6: qreqn high -> exit to RUN");
    @(negedge clk); qreqn_i = 1;
    @(negedge clk); @(negedge clk);
    check(qacceptn_o === 1'b1, "qacceptn back to 1 in RUN");
    if_wakeup_i = 0;

    // ---- summary ----
    @(negedge clk);
    $display("=========================================");
    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d CHECK(S) FAILED", errors);
    $display("=========================================");
    $finish;
  end

  // optional waveform dump
  initial begin
    $dumpfile("tb_low_power_channel.vcd");
    $dumpvars(0, tb_low_power_channel);
  end

endmodule
