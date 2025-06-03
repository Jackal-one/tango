`default_nettype none

module sdram #(
    parameter ClkFreq = 133_000_000
) (
    input  wire        i_rstn,
    input  wire        i_clk,
    input  wire [21:0] i_addr,
    input  wire [31:0] i_data,
    input  wire        i_en,
    input  wire        i_we,
    output wire [31:0] o_data,
    output wire        o_data_valid,
    output wire        o_ready,

    output wire        o_sdram_clk,
    output wire        o_sdram_cke,
    output wire        o_sdram_cs_n,
    output wire        o_sdram_cas_n,
    output wire        o_sdram_ras_n,
    output wire        o_sdram_wen_n,
    output wire [10:0] o_sdram_addr,
    output wire [ 1:0] o_sdram_ba,
    output wire [ 3:0] o_sdram_dqm,
    inout  wire [31:0] io_sdram_dq
);

  wire sdram_power_down = 1'b0;
  wire sdram_selfrefresh = 1'b0;
  wire sdram_precharge_ctrl = 1'b1;
  wire [3:0] sdram_dqm = 4'b0000;
  wire [7:0] sdram_data_len = 8'h00;

  wire [21:0] sdram_bank_row = {i_addr[20:10], i_addr[9:8], 8'h00};
  wire [21:0] sdram_bank_col = {11'h000, i_addr[9:8], i_addr[7:0]};

  wire [31:0] sdram_data;
  wire sdram_init_done;
  wire sdram_cmd_ack;

  reg [21:0] r_sdram_addr;
  reg [2:0] r_sdram_cmd;
  reg r_sdram_cmd_en;
  reg r_sdram_data_valid;

  SDRAM_Controller_HS_Top sdram_controller_hs_inst (
      .O_sdram_clk(o_sdram_clk),
      .O_sdram_cke(o_sdram_cke),
      .O_sdram_cs_n(o_sdram_cs_n),
      .O_sdram_cas_n(o_sdram_cas_n),
      .O_sdram_ras_n(o_sdram_ras_n),
      .O_sdram_wen_n(o_sdram_wen_n),
      .O_sdram_dqm(o_sdram_dqm),
      .O_sdram_addr(o_sdram_addr),
      .O_sdram_ba(o_sdram_ba),
      .IO_sdram_dq(io_sdram_dq),

      .I_sdrc_precharge_ctrl(sdram_precharge_ctrl),
      .I_sdram_power_down(sdram_power_down),
      .I_sdram_selfrefresh(sdram_selfrefresh),
      .I_sdrc_dqm(sdram_dqm),
      .I_sdrc_data_len(sdram_data_len),

      .I_sdrc_rst_n(i_rstn),
      .I_sdrc_clk(i_clk),
      .I_sdram_clk(i_clk),
      .I_sdrc_cmd_en(r_sdram_cmd_en),
      .I_sdrc_cmd(r_sdram_cmd),
      .I_sdrc_addr(r_sdram_addr),
      .I_sdrc_data(i_data),

      .O_sdrc_data(sdram_data),
      .O_sdrc_init_done(sdram_init_done),
      .O_sdrc_cmd_ack(sdram_cmd_ack)
  );

  localparam ClkPerRefresh = ClkFreq / 64_000;
  localparam ClkPerRefreshWidth = $clog2(ClkPerRefresh);
  reg [ClkPerRefreshWidth-1:0] r_refresh_cnt;

  localparam CmdRefresh = 3'b001;
  localparam CmdActivate = 3'b011;
  localparam CmdPrecharge = 3'b010;
  localparam CmdWrite = 3'b100;
  localparam CmdRead = 3'b101;

  localparam Idle = 4'b0000;
  localparam Refresh = 4'b0001;
  localparam Write = 4'b0010;
  localparam Write2 = 4'b0011;
  localparam Read = 4'b0100;
  localparam Read2 = 4'b0101;
  localparam Read3 = 4'b0110;
  reg [3:0] state;

  always @(posedge i_clk or negedge i_rstn) begin
    if (~i_rstn) begin
      r_refresh_cnt <= ClkPerRefresh - 1;
      r_sdram_cmd_en <= 1'b0;
      r_sdram_cmd <= 3'b000;
      r_sdram_addr <= 0;
      state <= Idle;

    end else if (sdram_init_done) begin
      case (state)
        Idle: begin

          if (r_refresh_cnt == ClkPerRefresh - 1) begin
            r_sdram_cmd_en <= 1'b1;
            r_sdram_cmd <= CmdRefresh;
            state <= Refresh;
          end else begin
            r_refresh_cnt <= r_refresh_cnt + 1;

            if (i_en) begin
              r_sdram_cmd_en <= 1'b1;
              r_sdram_cmd <= CmdActivate;
              r_sdram_addr <= sdram_bank_row;
              state <= i_we ? Write : Read;
            end
          end
        end

        Refresh: begin
          r_sdram_cmd_en <= 1'b0;
          if (sdram_cmd_ack) begin
            r_refresh_cnt <= 0;
            state <= Idle;
          end
        end

        Write: begin
          r_sdram_cmd_en <= 1'b0;
          if (sdram_cmd_ack) begin
            r_sdram_cmd_en <= 1'b1;
            r_sdram_cmd <= CmdWrite;
            r_sdram_addr <= sdram_bank_col;
            state <= Write2;
          end
        end

        Write2: begin
          r_sdram_cmd_en <= 1'b0;
          if (sdram_cmd_ack) begin
            state <= Idle;
          end
        end

        Read: begin
          r_sdram_cmd_en <= 1'b0;
          if (sdram_cmd_ack) begin
            r_sdram_cmd_en <= 1'b1;
            r_sdram_cmd <= CmdRead;
            r_sdram_addr <= sdram_bank_col;
            state <= Read2;
          end
        end

        Read2: begin
          r_sdram_cmd_en <= 1'b0;
          if (sdram_cmd_ack) begin
            state <= Read3;
          end
        end

        Read3: begin
          state <= Idle;
        end

      endcase
    end
  end

  assign o_data_valid = state == Read3;
  assign o_ready = sdram_init_done;
  assign o_data = sdram_data;

endmodule

`default_nettype wire
