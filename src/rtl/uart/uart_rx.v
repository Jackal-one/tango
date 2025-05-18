

module uart_rx #(
    parameter ClkFreq  = 10_000_000,
    parameter BaudRate = 115200
) (
    input i_clk,
    input i_rst_n,
    input i_rx,
    output o_rx_valid,
    output [7:0] o_rx_byte
);

  localparam BaudsPerBit = ClkFreq / (BaudRate);
  localparam BaudsCntWidth = $clog2(BaudsPerBit);

  reg [BaudsCntWidth-1:0] r_baud_cnt;
  reg [7:0] r_rx_byte;
  reg [3:0] r_bit_cnt;

  reg r_rx_t;
  reg r_rx_t1;
  reg r_rx_t2;

  reg r_state;
  reg r_rx_vd;
  reg r_bit_flag;

  wire w_nedge = (r_rx_t2 && ~r_rx_t1);

  always @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
      r_rx_t  <= 1'b1;
      r_rx_t1 <= 1'b1;
      r_rx_t2 <= 1'b1;
    end else begin
      r_rx_t  <= i_rx;
      r_rx_t1 <= r_rx_t;
      r_rx_t2 <= r_rx_t1;
    end
  end

  always @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
      r_rx_vd <= 0;
      r_baud_cnt <= 0;
      r_bit_flag <= 0;
      r_bit_cnt <= 0;
      r_state <= 0;
    end else begin
      r_bit_flag <= 1'b0;
      r_rx_vd <= 1'b0;

      if (!r_state && w_nedge) begin
        r_state <= 1'b1;
        r_baud_cnt <= BaudsPerBit / 2;
      end else if (r_state) begin
        if (r_baud_cnt == BaudsPerBit) begin
          r_baud_cnt <= 0;
          r_bit_flag <= 1'b1;
        end else begin
          r_baud_cnt <= r_baud_cnt + 1;
        end

        if (r_bit_flag) begin
          r_bit_cnt <= r_bit_cnt + 1;
        end

        if (r_bit_cnt == 4'd9 && r_bit_flag) begin
          if (r_rx_t2 == 1'b1) begin
            r_rx_vd <= 1'b1;
          end

          r_state   <= 1'b0;
          r_bit_cnt <= 0;
        end
      end
    end
  end

  always @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
      r_rx_byte <= 0;
    end else if (r_state) begin
      case (r_bit_cnt)
        4'd1: r_rx_byte[0] <= r_rx_t2;
        4'd2: r_rx_byte[1] <= r_rx_t2;
        4'd3: r_rx_byte[2] <= r_rx_t2;
        4'd4: r_rx_byte[3] <= r_rx_t2;
        4'd5: r_rx_byte[4] <= r_rx_t2;
        4'd6: r_rx_byte[5] <= r_rx_t2;
        4'd7: r_rx_byte[6] <= r_rx_t2;
        4'd8: r_rx_byte[7] <= r_rx_t2;
        default: r_rx_byte <= r_rx_byte;
      endcase
    end
  end

  assign o_rx_byte  = r_rx_byte;
  assign o_rx_valid = r_rx_vd;

endmodule
