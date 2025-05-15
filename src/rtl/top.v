module top (
    input i_clk,
    input i_rstn,
    input i_uart_rx,
    output o_uart_tx,

    output o_led_0,
    output o_led_1,
    output o_led_2,
    output o_led_3
);

    wire w_rx_vd;
    wire [7:0] w_rx_byte;

    uart_rx #(
        .ClkFreq(10_000_000),
        .BaudRate(115200)
    ) uart_rx_inst (
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .i_rx(i_uart_rx),
        .o_rx_valid(w_rx_vd),
        .o_rx_byte(w_rx_byte)
    );

    assign o_led_0 = i_rstn;
    assign o_led_1 = ~i_rstn;
    assign o_led_2 = i_uart_rx;
    assign o_led_3 = w_rx_vd;

endmodule