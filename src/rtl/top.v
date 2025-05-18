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

  reg tx_enable;
  wire tx_busy;
  wire rx_done;
  wire [7:0] rx_byte;

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
      .tx_data(rx_byte),
      .tx(o_uart_tx),
      .tx_busy(tx_busy)
  );

  always @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
      tx_enable <= 1'b0;
    end else begin
      tx_enable <= rx_done && ~tx_busy;
    end
  end

  assign o_led_0 = ~i_rst_n;
  assign o_led_1 = ~tx_busy;
  assign o_led_2 = i_uart_rx;
  assign o_led_3 = o_uart_tx;

endmodule
