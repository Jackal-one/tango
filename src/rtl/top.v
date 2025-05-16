module top (
    input i_clk,
    input i_rst,
    input i_uart_rx,
    output o_uart_tx,

    output o_led_0,
    output o_led_1,
    output o_led_2,
    output o_led_3
);

    wire w_rx_vd;
    wire [7:0] w_rx_byte;

    wire i_rst_n = ~i_rst;

    uart_rx #(
        .ClkFreq(10_000_000),
        .BaudRate(115200)
    ) uart_rx_inst (
        .i_clk(i_clk),
        .i_rst_n(~i_rst),
        .i_rx(i_uart_rx),
        .o_rx_valid(w_rx_vd),
        .o_rx_byte(w_rx_byte)
    );

    reg r_rx_recv;

    always @(posedge i_clk or negedge i_rst_n) begin
        if(~i_rst_n) begin
            r_rx_recv <= 1'b0;
        end else if(w_rx_vd) begin
            r_rx_recv <= ~r_rx_recv;
        end
    end

    assign o_led_0 = ~i_rst;
    assign o_led_1 = ~w_rx_vd;
    assign o_led_2 = i_uart_rx;
    assign o_led_3 = ~r_rx_recv;

endmodule