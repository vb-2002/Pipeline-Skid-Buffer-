`timescale 1ns/1ps

module pipe_skid_buffer_tb;

  // Parameters
  parameter DWIDTH = 8;

  // DUT Interface Signals
  logic clk;
  logic rstn;
  logic [DWIDTH-1:0] i_data;
  logic              i_valid;
  logic              o_ready;
  logic [DWIDTH-1:0] o_data;
  logic              o_valid;
  logic              i_ready;

  // DUT Instantiation
  pipe_skid_buffer #(.DWIDTH(DWIDTH)) dut (
    .clk     (clk),
    .rstn    (rstn),
    .i_data  (i_data),
    .i_valid (i_valid),
    .o_ready (o_ready),
    .o_data  (o_data),
    .o_valid (o_valid),
    .i_ready (i_ready)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;  // 100 MHz

  // Reset generation
  initial begin
    rstn = 0;
    #20;
    rstn = 1;
  end

  // Stimulus variables
  logic [DWIDTH-1:0] data;
  int send_count = 0;
  int recv_count = 0;

  // Task to drive input
  task send(input [DWIDTH-1:0] val);
    begin
      @(posedge clk);
      i_data  <= val;
      i_valid <= 1;
      while (!o_ready) @(posedge clk); // wait until ready
      @(posedge clk);
      i_valid <= 0;
    end
  endtask

  // Task to accept data
  always @(posedge clk) begin
    if (o_valid && i_ready) begin
      $display("[%0t] Received data: %0d", $time, o_data);
      recv_count++;
    end
  end

  // Test sequence
  initial begin
    // Init signals
    i_valid = 0;
    i_data  = 0;
    i_ready = 1;

    wait(rstn);

    // Send 4 words with no backpressure
    repeat (4) begin
      send(send_count);
      send_count++;
    end

    // Insert downstream backpressure to trigger SKID state
    i_ready = 0;
    send(99); // this should push pipeline into SKID
    #10;
    i_ready = 1;

    // Continue streaming
    repeat (3) begin
      send(send_count);
      send_count++;
    end

    #100;
    $display("Test complete: sent=%0d received=%0d", send_count, recv_count);
    $finish;
  end

endmodule
