module top (
    input  i_clk,
    input  i_rst,
    input  i_uart_rx,
    output o_uart_tx,

    output o_led_0,
    output o_led_1,
    output o_led_2,
    output o_led_3
);

  localparam ClkFreq = 27_000_000;
  localparam BaudRate = 115200;

  wire i_rst_n = ~i_rst;

  wire [7:0] rx_byte;
  wire [7:0] tx_byte;

  wire tx_busy;
  wire rx_done;

  wire fifo_full;
  wire fifo_empty;

  reg tx_enable;
  reg fifo_read_en;

  uart_rx #(
      .ClkFreq (ClkFreq),
      .BaudRate(BaudRate)
  ) uart_rx_inst (
      .i_clk(i_clk),
      .i_rst_n(i_rst_n),
      .i_rx(i_uart_rx),
      .o_rx_valid(rx_done),
      .o_rx_byte(rx_byte)
  );

  uart_tx #(
      .ClkFreq (ClkFreq),
      .BaudRate(BaudRate)
  ) uart_tx_inst (
      .clk(i_clk),
      .reset_n(i_rst_n),
      .tx_enable(tx_enable),
      .tx_data(tx_byte),
      .tx(o_uart_tx),
      .tx_busy(tx_busy)
  );

  fifo #(
      .Depth(4),
      .Width(8)
  ) fifo_inst (
      .i_clk(i_clk),
      .i_rst_n(i_rst_n),
      .i_wr(rx_done),
      .i_rd(fifo_read_en),
      .i_data(rx_byte),
      .o_data(tx_byte),
      .o_full(fifo_full),
      .o_empty(fifo_empty)
  );

  always @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
      tx_enable <= 1'b0;
      fifo_read_en <= 1'b0;
    end else begin
      tx_enable <= fifo_read_en;
      fifo_read_en <= ~fifo_empty && ~tx_busy;
    end
  end

  assign o_led_0 = ~i_rst_n;
  assign o_led_1 = fifo_empty;
  assign o_led_2 = i_uart_rx;
  assign o_led_3 = o_uart_tx;

endmodule
