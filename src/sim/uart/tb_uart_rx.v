`timescale 1ns/10ps

module tb_uart_rx;

    parameter c_CLK_FREQ_HZ = 10_000_000;
    parameter c_CLOCK_PERIOD_NS = 100;
    parameter c_BAUD_RATE = 115200;
    parameter c_BAUD_PERIOD_NS = 8680;
    parameter c_CLKS_PER_BIT_RX = c_CLK_FREQ_HZ / (c_BAUD_RATE * 8);

    reg r_clk = 0;
    reg r_rst = 0;
    reg r_rx_data;
    wire r_rx_vd;
    reg [7:0] r_data = 8'd85;
    wire [7:0] r_rx_byte;

    uart_rx #(
        .ClkFreq(c_CLK_FREQ_HZ),
        .BaudRate(c_BAUD_RATE)
    ) uart_rx_uut(
        .i_clk(r_clk),
        .i_rstn(~r_rst),
        .i_rx(r_rx_data),
        .o_rx_valid(r_rx_vd),
        .o_rx_byte(r_rx_byte)
    );

    initial begin
        r_rx_data = 1'b1;
        r_rst = 1'b1;
        #(100);
        r_rst = 1'b0;
    end

    always #(c_CLOCK_PERIOD_NS / 2) begin
        r_clk <= ~r_clk;
    end

    task send_uart_word(input [7:0] word);
        integer ii;
        begin
            r_rx_data <= 1'b0;
            #(c_BAUD_PERIOD_NS);

            for (ii = 0; ii < 8; ii = ii + 1) begin
                r_rx_data <= word[ii];
                #(c_BAUD_PERIOD_NS);
            end

            r_rx_data <= 1'b1;
            #(c_BAUD_PERIOD_NS);
        end
    endtask

    initial begin
        $dumpfile("build/tb_uart_rx.vcd");
        $dumpvars(0, tb_uart_rx);

        #(20000);
        send_uart_word(35);
        send_uart_word(85);
        send_uart_word(60);
        send_uart_word(1);
        send_uart_word(127);
        send_uart_word(255);
        send_uart_word(2);
        send_uart_word(9);

        $display("Received byte: %b", r_rx_byte);

        #(500 * c_CLOCK_PERIOD_NS);
        $finish;
    end

endmodule