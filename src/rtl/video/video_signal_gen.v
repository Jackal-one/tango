module video_signal_gen #(
    parameter HRes = 480,
    parameter VRes = 272,
    parameter HFrontPorch = 2,
    parameter HSyncPulse = 41,
    parameter HBackPorch = 2,
    parameter VFrontPorch = 2,
    parameter VSyncPulse = 10,
    parameter VBackPorch = 2
) (
    input wire clk,
    input wire rstn,
    output reg hsync,
    output reg vsync,
    output reg de,
    output reg [9:0] sx,
    output reg [9:0] sy
);

  localparam HSyncStart = HRes + HFrontPorch;
  localparam HSyncEnd = HSyncStart + HSyncPulse;
  localparam HTotal = HSyncEnd + HBackPorch;

  localparam VSyncStart = VRes + VFrontPorch;
  localparam VSyncEnd = VSyncStart + VSyncPulse;
  localparam VTotal = VSyncEnd + VBackPorch;

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      sx <= 0;
      sy <= 0;
    end else begin
      if (sx == HTotal - 1) begin
        sx <= 0;
        sy <= sy == VTotal - 1 ? 0 : sy + 1;
      end else begin
        sx <= sx + 1;
      end
    end
  end

  assign hsync = ~(sx >= HSyncStart && sx < HSyncEnd);
  assign vsync = ~(sy >= VSyncStart && sy < VSyncEnd);
  assign de = (sx < HRes) && (sy < VRes);

endmodule
