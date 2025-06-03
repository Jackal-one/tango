`timescale 1ns / 1ps `default_nettype none

module tb_sdram;

  parameter ClkFreq = 26_300_000;
  parameter ClockPeriod = 1_000_000_000 / ClkFreq;

  reg rstn = 1'b0;
  reg clk = 1'b0;

  always #(ClockPeriod / 2) begin
    clk = ~clk;
  end

  wire        O_sdram_clk;
  wire        O_sdram_cke;
  wire        O_sdram_cs_n;
  wire        O_sdram_cas_n;
  wire        O_sdram_ras_n;
  wire        O_sdram_wen_n;
  wire [31:0] IO_sdram_dq;
  wire [10:0] O_sdram_addr;
  wire [ 1:0] O_sdram_ba;
  wire [ 3:0] O_sdram_dqm;

  mt48lc2m32b2 sdram (
      .Clk(O_sdram_clk),
      .Cke(O_sdram_cke),
      .Cs_n(O_sdram_cs_n),
      .Cas_n(O_sdram_cas_n),
      .Ras_n(O_sdram_ras_n),
      .We_n(O_sdram_wen_n),
      .Dq(IO_sdram_dq),
      .Addr(O_sdram_addr),
      .Ba(O_sdram_ba),
      .Dqm(O_sdram_dqm)
  );

  wire [31:0] read_data;
  reg [31:0] r_data = 32'h00000000;
  reg [31:0] r_addr = 32'h00000000;

  reg r_en = 1'b0;
  reg r_we = 1'b0;
  wire sdram_ready;
  wire sdram_data_valid;

  sdram sdram_uut (
      .i_rstn(rstn),
      .i_clk(clk),
      .i_en(r_en),
      .i_we(r_we),
      .i_addr(r_addr),
      .i_data(r_data),
      .o_data(read_data),
      .o_ready(sdram_ready),
      .o_data_valid(sdram_data_valid),

      .o_sdram_clk(O_sdram_clk),
      .o_sdram_cke(O_sdram_cke),
      .o_sdram_cs_n(O_sdram_cs_n),
      .o_sdram_cas_n(O_sdram_cas_n),
      .o_sdram_ras_n(O_sdram_ras_n),
      .o_sdram_wen_n(O_sdram_wen_n),
      .o_sdram_addr(O_sdram_addr),
      .o_sdram_ba(O_sdram_ba),
      .o_sdram_dqm(O_sdram_dqm),
      .io_sdram_dq(IO_sdram_dq)
  );

  reg [31:0] rr;

  initial begin
    $dumpfile("build/tb_sdram.vcd");
    $dumpvars(0, tb_sdram);

    #(ClockPeriod * 10);
    rstn = 1'b1;

    while (rstn == 1'b0) begin
      #(ClockPeriod);
    end

    wait (sdram_ready == 1'b1);
    wait (sdram_uut.state == sdram_uut.Refresh);
    wait (sdram_uut.state == sdram_uut.Idle);

    write_sdram(32'h0000, 32'd1);
    write_sdram(32'h0004, 32'd2);
    write_sdram(32'h0008, 32'd3);
    write_sdram(32'h000C, 32'd4);

    read_sdram(32'h0000, rr);
    read_sdram(32'h0008, rr);
    read_sdram(32'h000C, rr);
    read_sdram(32'h0004, rr);

    #(ClockPeriod * 100);

    //$fatal;
    $finish;
  end

  task write_sdram(input [31:0] addr, input [31:0] data);
    @(posedge clk);
    r_addr = addr;
    r_data = data;
    r_en   = 1'b1;
    r_we   = 1'b1;

    @(posedge clk);
    r_en = 1'b0;
    r_we = 1'b0;

    wait (sdram_uut.state == sdram_uut.Idle);
  endtask

  task read_sdram(input [31:0] addr, output [31:0] data);
    @(posedge clk);
    r_addr = addr;
    r_en   = 1'b1;
    r_we   = 1'b0;

    @(posedge clk);
    r_en = 1'b0;

    wait (sdram_uut.state == sdram_uut.Idle);
  endtask

endmodule
