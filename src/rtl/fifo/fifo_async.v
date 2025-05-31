`default_nettype none

module fifo_async #(
    parameter Depth = 8,
    parameter Width = 8
) (
    input wire i_wr_clk,
    input wire i_wr_rstn,
    input wire i_wr_en,
    input wire [Width-1:0] i_wr_data,

    input wire i_rd_clk,
    input wire i_rd_rstn,
    input wire i_rd_en,

    output wire [Width-1:0] o_rd_data,
    output reg o_full,
    output reg o_empty
);

  localparam AW = $clog2(Depth);
  localparam DW = Width;

  reg [DW-1:0] mem[0:Depth-1];

  reg [AW:0] write_ptr, read_ptr;
  wire [AW-1:0] write_addr = write_ptr[AW-1:0];
  wire [AW-1:0] read_addr = read_ptr[AW-1:0];

  reg [AW:0] write_ptr_gray, read_ptr_gray;
  reg [AW:0] write_ptr_gray_sync1, read_ptr_gray_sync1;
  reg [AW:0] write_ptr_gray_sync2, read_ptr_gray_sync2;

  // write clock domain

  always @(posedge i_wr_clk or negedge i_wr_rstn) begin
    if (~i_wr_rstn) begin
      read_ptr_gray_sync1 <= 0;
      read_ptr_gray_sync2 <= 0;
    end else begin
      read_ptr_gray_sync1 <= read_ptr_gray;
      read_ptr_gray_sync2 <= read_ptr_gray_sync1;
    end
  end

  wire [AW:0] write_ptr_next = write_ptr + (i_wr_en & ~o_full);
  wire [AW:0] write_ptr_gray_next = (write_ptr_next >> 1) ^ write_ptr_next;

  always @(posedge i_wr_clk or negedge i_wr_rstn) begin
    if (~i_wr_rstn) begin
      write_ptr <= 0;
      write_ptr_gray <= 0;
    end else begin
      write_ptr <= write_ptr_next;
      write_ptr_gray <= write_ptr_gray_next;
    end
  end

  always @(posedge i_wr_clk or negedge i_wr_rstn)
    if (~i_wr_rstn) begin
      o_full <= 1'b0;
    end else begin
      o_full <= (write_ptr_gray[AW:AW-1] == ~read_ptr_gray_sync2[AW:AW-1])
				&& (write_ptr_gray[AW-2:0]==read_ptr_gray_sync2[AW-2:0]);
    end

  always @(posedge i_wr_clk) begin
    if (i_wr_en && ~o_full) begin
      mem[write_addr] <= i_wr_data;
    end
  end

  // read clock domain

  always @(posedge i_rd_clk or negedge i_rd_rstn) begin
    if (~i_rd_rstn) begin
      write_ptr_gray_sync1 <= 0;
      write_ptr_gray_sync2 <= 0;
    end else begin
      write_ptr_gray_sync1 <= write_ptr_gray;
      write_ptr_gray_sync2 <= write_ptr_gray_sync1;
    end
  end

  wire [AW:0] read_ptr_next = read_ptr + (i_rd_en & ~o_empty);
  wire [AW:0] read_ptr_gray_next = (read_ptr_next >> 1) ^ read_ptr_next;

  always @(posedge i_rd_clk or negedge i_rd_rstn) begin
    if (~i_rd_rstn) begin
      read_ptr <= 0;
      read_ptr_gray <= 0;
    end else begin
      read_ptr <= read_ptr_next;
      read_ptr_gray <= read_ptr_gray_next;
    end
  end

  always @(posedge i_rd_clk or negedge i_rd_rstn) begin
    if (~i_rd_rstn) begin
      o_empty <= 1'b1;
    end else begin
      o_empty <= (write_ptr_gray_sync2 == read_ptr_gray);
    end
  end

  assign o_rd_data = mem[read_addr];

endmodule

`default_nettype wire
