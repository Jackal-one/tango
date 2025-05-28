module top (
    input  i_clk,
    input  i_rst,
    input  i_uart_rx,
    output o_uart_tx,

    output o_video_clk,
    output o_video_de,
    output [4:0] o_video_r,
    output [5:0] o_video_g,
    output [4:0] o_video_b,

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

  wire clk_9Mhz;
  wire clk_locked;
  wire hsync;
  wire vsync;
  wire [9:0] sx;
  wire [9:0] sy;

  reg [23:0] video_data;

  assign o_video_clk = clk_9Mhz;
  assign o_video_r   = sx[8:4];
  assign o_video_g   = sy[9:4];
  assign o_video_b   = video_data[9:5];

  always @(posedge clk_9Mhz or negedge i_rst_n) begin
    if (~i_rst_n) begin
      video_data <= 0;
    end else if (~vsync) begin
      video_data <= video_data + 1;
    end
  end

  Gowin_rPLL rpll_inst (
      .clkout(clk_9Mhz),
      .lock  (clk_locked),
      .reset (~i_rst_n),
      .clkin (i_clk)
  );

  video_signal_gen #(
      .HRes(480),
      .VRes(272),
      .HFrontPorch(2),
      .HSyncPulse(41),
      .HBackPorch(2),
      .VFrontPorch(2),
      .VSyncPulse(10),
      .VBackPorch(2)
  ) video_signal_gen_inst (
      .clk(clk_9Mhz),
      .rstn(i_rst_n),
      .hsync(hsync),
      .vsync(vsync),
      .de(o_video_de),
      .sx(sx),
      .sy(sy)
  );

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
