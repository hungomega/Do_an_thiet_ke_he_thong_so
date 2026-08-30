// uart_top.v
// Wrapper memory-mapped don gian: sau nay ghep truc tiep vao address decoder cua SoC.
//   addr_offset == 0 : ghi  -> TXDATA (gui byte)
//                        doc  -> STATUS {30'b0, rx_ready, tx_busy}
//   addr_offset == 1 : doc  -> RXDATA (byte nhan duoc)

module uart_top #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire        clk,
    input  wire        rst_n,

    // giao dien don gian hoa thay cho bus CPU that (se thay bang bus chuan sau)
    input  wire        we,           // write enable
    input  wire [0:0]  addr_offset,
    input  wire [7:0]  wdata,
    output reg  [31:0] rdata,

    output wire        tx_pin,
    input  wire        rx_pin
);
    wire tick, tick_x16;
    wire tx_busy, rx_ready;
    wire [7:0] rx_data;

    baud_gen #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_baud (
        .clk(clk), .rst_n(rst_n), .tick(tick), .tick_x16(tick_x16)
    );

    uart_tx u_tx (
        .clk(clk), .rst_n(rst_n), .tick(tick),
        .tx_start(we && addr_offset == 1'b0),
        .tx_data(wdata),
        .tx_busy(tx_busy),
        .tx(tx_pin)
    );

    uart_rx u_rx (
        .clk(clk), .rst_n(rst_n), .tick_x16(tick_x16),
        .rx(rx_pin),
        .rx_ready(rx_ready),
        .rx_data(rx_data)
    );

    always @(*) begin
        case (addr_offset)
            1'b0: rdata = {30'b0, rx_ready, tx_busy}; // STATUS
            1'b1: rdata = {24'b0, rx_data};            // RXDATA
            default: rdata = 32'b0;
        endcase
    end
endmodule
