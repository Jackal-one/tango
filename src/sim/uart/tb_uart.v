`timescale 1ns / 10ps

`define ASSERT(cond, msg) \
  if (!(cond)) begin \
    $display("assert: %s", msg); \
    $fatal; \
  end

module tb_uart;

  parameter ClkFreq = 27_000_000;
  parameter ClockPeriod = 1_000_000_000 / ClkFreq;

  parameter BaudRate = 115200;
  parameter BaudCnt = ClkFreq / BaudRate;
  parameter BaudPeriod = ClockPeriod * BaudCnt;

  reg clk = 0;
  reg rstn = 0;

  wire rx_uart;
  wire rx_valid;
  wire [7:0] rx_data;

  reg tx_enable;
  wire tx_uart;
  wire tx_busy;
  reg [7:0] tx_data;

  assign rx_uart = tx_uart;

  uart_tx #(
      .ClkFreq (ClkFreq),
      .BaudRate(BaudRate)
  ) uart_tx_uut (
      .clk(clk),
      .reset_n(rstn),
      .tx_enable(tx_enable),
      .tx_data(tx_data),
      .tx(tx_uart),
      .tx_busy(tx_busy)
  );

  uart_rx #(
      .ClkFreq (ClkFreq),
      .BaudRate(BaudRate)
  ) uart_rx_uut (
      .i_clk(clk),
      .i_rst_n(rstn),
      .i_rx(rx_uart),
      .o_rx_valid(rx_valid),
      .o_rx_byte(rx_data)
  );

  always #(ClockPeriod / 2) clk <= ~clk;

  initial begin
    $dumpfile("build/tb_uart.vcd");
    $dumpvars(0, tb_uart);

    #(ClockPeriod * 10);
    rstn = 1'b1;

    wait (rstn == 1'b1);
    uart_echo_test(15);

    $finish;
  end

  task uart_echo_test(input integer n);
    integer i;

    begin
      $display("uart_echo_test");
      for (i = 0; i < n; i = i + 1) begin
        tx_data = $random % 256;
        tx_enable <= 1'b1;
        #(ClockPeriod);

        tx_enable <= 1'b0;
        #(ClockPeriod);
        
        `ASSERT(tx_busy == 1'b1, "tx_busy is not 1");
        `ASSERT(rx_valid == 1'b0, "rx_valid is not 0");

        wait (rx_valid == 1'b1);

        `ASSERT(tx_busy == 1'b0, "tx_busy is not 0");
        `ASSERT(rx_data == tx_data, "rx_data is not equal to tx_data");
      end
    end
  endtask

endmodule
