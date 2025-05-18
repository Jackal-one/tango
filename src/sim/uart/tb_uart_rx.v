`timescale 1ns / 10ps

module tb_uart_rx;

  parameter c_CLK_FREQ_HZ = 27_000_000;
  parameter c_CLOCK_PERIOD_NS = 1_000_000_000 / c_CLK_FREQ_HZ;

  parameter c_BAUD_RATE = 115200;
  parameter c_BAUD_CNT = c_CLK_FREQ_HZ / c_BAUD_RATE;
  parameter c_BAUD_PERIOD_NS = c_CLOCK_PERIOD_NS * c_BAUD_CNT;

  reg r_clk = 0;
  reg r_rst = 0;
  reg r_rx_data;
  wire r_rx_vd;
  reg [7:0] r_data = 8'd85;
  wire [7:0] r_rx_byte;

  reg tx_enable = 1'b0;
  wire [7:0] tx_data = r_rx_byte;
  wire tx;
  wire tx_busy;

  uart_rx #(
      .ClkFreq (c_CLK_FREQ_HZ),
      .BaudRate(c_BAUD_RATE)
  ) uart_rx_uut (
      .i_clk(r_clk),
      .i_rst_n(~r_rst),
      .i_rx(r_rx_data),
      .o_rx_valid(r_rx_vd),
      .o_rx_byte(r_rx_byte)
  );

  uart_tx #(
      .ClkFreq (c_CLK_FREQ_HZ),
      .BaudRate(c_BAUD_RATE)
  ) uart_tx_uut (
      .clk(r_clk),
      .reset_n(~r_rst),
      .tx_enable(tx_enable),
      .tx_data(tx_data),
      .tx(tx),
      .tx_busy(tx_busy)
  );

  always @(posedge r_clk) begin
    tx_enable <= r_rx_vd && ~tx_busy;
  end

  always #(c_CLOCK_PERIOD_NS / 2) begin
    r_clk <= ~r_clk;
  end

  task send_uart_word(input [7:0] word);
    integer ii;
    begin
      r_rx_data <= 1'b0;
      #(c_BAUD_PERIOD_NS);

      for (ii = 0; ii < 8; ii = ii + 1) begin
        r_rx_data <= word[ii];
        #(c_BAUD_PERIOD_NS);
      end

      r_rx_data <= 1'b1;
      #(c_BAUD_PERIOD_NS);
    end
  endtask

  initial begin
    r_rx_data = 1'b1;
    r_rst = 1'b1;
    #(100);
    r_rst = 1'b0;
  end

  initial begin
    $dumpfile("build/tb_uart_rx.vcd");
    $dumpvars(0, tb_uart_rx);



    #(1000);
    send_uart_word(104);
    send_uart_word(23);
    send_uart_word(126);
    send_uart_word(85);

    #(c_BAUD_PERIOD_NS * 10);

    $display("Received byte: %b", r_rx_byte);

    #(500 * c_CLOCK_PERIOD_NS);
    $finish;
  end

endmodule
