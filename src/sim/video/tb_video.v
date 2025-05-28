`timescale 1ns / 10ps

module tb_video;

  parameter ClkFreq = 9_000_000;
  parameter ClockPeriod = 1_000_000_000 / ClkFreq;

  reg rstn = 1'b0;
  reg clk = 1'b0;

  wire clk_9Mhz;
  wire clk_locked;

  always #(ClockPeriod / 2) begin
    clk = ~clk;
  end

  wire hsync;
  wire vsync;
  wire [9:0] sx;
  wire [9:0] sy;

  video_signal_gen #(
      .HRes(480),
      .VRes(272),
      .HFrontPorch(2),
      .HSyncPulse(41),
      .HBackPorch(2),
      .VFrontPorch(2),
      .VSyncPulse(10),
      .VBackPorch(2)
  ) video_signal_gen_uut (
      .clk(clk),
      .rstn(rstn),
      .hsync(hsync),
      .vsync(vsync),
      .sx(sx),
      .sy(sy)
  );

  initial begin
    $dumpfile("build/tb_video.vcd");
    $dumpvars(0, tb_video);
  end

  initial begin
    rstn = 1'b0;
    #(ClockPeriod * 10);
    rstn = 1'b1;

    wait (vsync == 1'b0);
    #(20_000_000);

    $finish;
  end

endmodule
