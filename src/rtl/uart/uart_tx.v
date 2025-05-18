module uart_tx #(
    parameter ClkFreq  = 10_000_000,
    parameter BaudRate = 115200
) (
    input        clk,
    input        reset_n,
    input        tx_enable,
    input  [7:0] tx_data,
    output       tx,
    output       tx_busy
);

  localparam BaudsPerBit = ClkFreq / BaudRate;
  localparam BaudsCntWidth = $clog2(BaudsPerBit);

  reg [BaudsCntWidth-1:0] bauds_cnt;
  reg [7:0] r_data;
  reg [3:0] bit_cnt;
  reg bit_flag;
  reg state;
  reg r_tx;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      r_data <= 8'd0;
      state  <= 1'b0;
    end else begin
      if (~state && tx_enable) begin
        r_data <= tx_data;
        state  <= 1'b1;
      end else if (bit_flag && bit_cnt == 4'd9) begin
        state <= 1'b0;
      end
    end
  end

  always @(posedge clk or negedge reset_n) begin
    if (~reset_n) begin
      bauds_cnt <= 'd0;
    end else if (state) begin
      if (bauds_cnt == BaudsPerBit) begin
        bauds_cnt <= 'd0;
      end else begin
        bauds_cnt <= bauds_cnt + 1'b1;
      end
    end
  end

  always @(posedge clk or negedge reset_n) begin
    if (~reset_n) begin
      bit_flag <= 1'b0;
    end else if (state && bauds_cnt == 'd0) begin
      bit_flag <= 1'b1;
    end else begin
      bit_flag <= 1'b0;
    end
  end

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      bit_cnt <= 1'b0;
    end else if (state) begin
      if (bit_flag) begin
        bit_cnt <= bit_cnt + 1'b1;
        if (bit_cnt == 4'd9) begin
          bit_cnt <= 1'b0;
        end
      end
    end
  end

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      r_tx <= 1'b1;
    end else if (state) begin
      if (bit_flag) begin
        case (bit_cnt)
          4'd0: r_tx <= 1'b0;
          4'd1: r_tx <= r_data[0];
          4'd2: r_tx <= r_data[1];
          4'd3: r_tx <= r_data[2];
          4'd4: r_tx <= r_data[3];
          4'd5: r_tx <= r_data[4];
          4'd6: r_tx <= r_data[5];
          4'd7: r_tx <= r_data[6];
          4'd8: r_tx <= r_data[7];
          4'd9: r_tx <= 1'b1;
          default: r_tx <= 1'b1;
        endcase
      end
    end else begin
      r_tx <= 1'b1;
    end
  end

  assign tx = r_tx;
  assign tx_busy = state;

endmodule
