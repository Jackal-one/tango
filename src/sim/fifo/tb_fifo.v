`timescale 1ns / 10ps

`define ASSERT(cond, msg) \
  if (!(cond)) begin \
    $display("assert: %s", msg); \
    $fatal; \
  end

module tb_fifo;

  parameter ClkFreq = 27_000_000;
  parameter ClockPeriod = 1_000_000_000 / ClkFreq;

  reg clk = 1'b0;
  reg rstn = 1'b0;

  reg [7:0] data_in;
  wire [7:0] data_out;

  reg wrtite_en = 1'b0;
  reg read_en = 1'b0;
  wire full;
  wire empty;

  wire tx_uart;
  wire tx_busy;

  wire debug = ~empty && read_en;

  fifo #(
      .Depth(2),
      .Width(8)
  ) fifo_uut (
      .i_clk(clk),
      .i_rst_n(rstn),
      .i_wr(wrtite_en),
      .i_rd(read_en),
      .i_data(data_in),
      .o_data(data_out),
      .o_full(full),
      .o_empty(empty)
  );

  always #(ClockPeriod / 2) clk <= ~clk;

initial begin
    $dumpfile("build/tb_fifo.vcd");
    $dumpvars(0, tb_fifo);
end

  initial begin
    reset(10);

    #(ClockPeriod * 50);
    $finish;
  end

  initial begin
    wait (rstn == 1'b1);

    write(8'hAA);
    write(8'hBB);
    write(8'hCC);
    write(8'hDD);
    write(8'hEE);
    write(8'hFF);
  end

  initial begin
    wait (rstn == 1'b1);

    read();
    read();
    read();
    read();
    read();
    read();
    read();
    read();
    read();
    read();
    read();
    read();
    read();
  end

  task write(input [7:0] data);
    begin
      @(posedge clk); 
      wrtite_en = 1'b1;
      data_in = data;
      @(posedge clk); 
      wrtite_en = 1'b0;
    end
  endtask

  task read();
    begin
       @(posedge clk); 
      read_en = 1'b1 & ~empty;
      @(posedge clk); 
      read_en = 1'b0;
    end
  endtask

  task reset(input integer n);
    begin
      #(ClockPeriod * n);
      rstn = 1'b1;
      wait (rstn == 1'b1);
    end
  endtask

endmodule
