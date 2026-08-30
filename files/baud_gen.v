// baud_gen.v
// Tao 2 tin hieu tick:
//   tick_x16 : xung o toc do 16 x baud_rate (dung de RX oversample)
//   tick     : xung o dung toc do baud_rate (dung cho TX dich bit)
// tick luon trung voi 1 trong 16 canh cua tick_x16 nen 2 khoi TX/RX dong bo voi nhau.

module baud_gen #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire clk,
    input  wire rst_n,
    output reg  tick,
    output reg  tick_x16
);
    // moi bit UART keo dai CLK_FREQ/BAUD_RATE chu ky clock.
    // chia lam 16 phan bang nhau de RX lay mau o giua bit.
    localparam integer DIVISOR16 = CLK_FREQ / (BAUD_RATE * 16);

    reg [31:0] cnt16;
    reg [3:0]  sub_cnt; // dem 0..15

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt16    <= 0;
            sub_cnt  <= 0;
            tick     <= 0;
            tick_x16 <= 0;
        end else begin
            tick     <= 0;
            tick_x16 <= 0;
            if (cnt16 == DIVISOR16 - 1) begin
                cnt16    <= 0;
                tick_x16 <= 1;
                if (sub_cnt == 15) begin
                    sub_cnt <= 0;
                    tick    <= 1;
                end else begin
                    sub_cnt <= sub_cnt + 1;
                end
            end else begin
                cnt16 <= cnt16 + 1;
            end
        end
    end
endmodule
