module apb_uart_rx 
(
    input logic clk,
    input logic n_rst,
    input logic serial_in,
    input logic psel,
    input logic [2:0] paddr,
    input logic penable,
    input logic pwrite,
    input logic [7:0] pwdata,
    output logic [7:0] prdata,
    output logic pslverr
);
    logic [3:0] data_size;
    // logic [13:0] data_period;

    logic data_ready;
    logic [7:0] rx_data;
    logic data_read;
    logic overrun_error;
    logic framing_error;
    logic [13:0] bit_period;

    rcv_block uart
    (
        .clk(clk),
        .n_rst(n_rst),
        .data_size(data_size[3:0]),
        .data_period(bit_period),
        .serial_in(serial_in),
        .data_read(data_read),
        .rx_data(rx_data),
        .data_ready(data_ready),
        .overrun_error(overrun_error),
        .framing_error(framing_error)
    );

    apb_slave slave
    (
        .clk(clk),
        .n_rst(n_rst),
        .rx_data(rx_data),
        .data_ready(data_ready),
        .overrun_error(overrun_error),
        .framing_error(framing_error),
        .data_read(data_read),
        .psel(psel),
        .paddr(paddr),
        .penable(penable),
        .pwrite(pwrite),
        .pwdata(pwdata),
        .prdata(prdata),
        .pslverr(pslverr),
        .data_size(data_size),
        .bit_period(bit_period)
    );


endmodule