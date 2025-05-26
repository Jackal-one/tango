module fifo #(
    parameter Depth = 8,
    parameter Width = 8
) (
    input              i_clk,
    input              i_rst_n,
    input              i_wr,
    input              i_rd,
    input  [Width-1:0] i_data,
    output [Width-1:0] o_data,
    output             o_full,
    output             o_empty
);

  localparam PtrMSB = $clog2(Depth);
  localparam AddrMSB = PtrMSB - 1;

  reg [PtrMSB:0] r_read_ptr;
  reg [PtrMSB:0] r_write_ptr;

  reg [Width-1:0] r_fifo[0:Depth-1];
  reg [Width-1:0] r_read_data;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
      r_write_ptr <= 0;
    end else begin
      if (i_wr && ~o_full) begin
        r_fifo[r_write_ptr[AddrMSB:0]] <= i_data;
        r_write_ptr <= r_write_ptr + 1;
      end
    end
  end

  always @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
      r_read_ptr <= 0;
    end else begin
      if (i_rd && ~o_empty) begin
        r_read_data <= r_fifo[r_read_ptr[AddrMSB:0]];
        r_read_ptr  <= r_read_ptr + 1;
      end
    end
  end

  assign o_data = r_read_data;
  assign o_empty = (r_read_ptr == r_write_ptr) ? 1'b1 : 1'b0;
  assign o_full = (r_write_ptr[AddrMSB:0] == r_read_ptr[AddrMSB:0]) &
                    (r_write_ptr[PtrMSB] ^ r_read_ptr[PtrMSB]) ?
                    1'b1 : 1'b0;

endmodule
