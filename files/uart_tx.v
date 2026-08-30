// uart_tx.v
// Frame: 1 start bit (0) - 8 data bit (LSB truoc) - 1 stop bit (1)

module uart_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tick,       // 1 xung / bit period (tu baud_gen)
    input  wire       tx_start,   // pulse 1 chu ky de bat dau gui
    input  wire [7:0] tx_data,
    output reg        tx_busy,
    output reg        tx
);
    reg [3:0] bit_cnt;
    reg [9:0] shift_reg; // {stop=1, data[7:0], start=0}

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_busy   <= 1'b0;
            tx        <= 1'b1;  // duong idle muc cao
            bit_cnt   <= 4'd0;
            shift_reg <= 10'b11_1111_1111;
        end else if (tx_start && !tx_busy) begin
            shift_reg <= {1'b1, tx_data, 1'b0};
            tx_busy   <= 1'b1;
            bit_cnt   <= 4'd0;
        end else if (tx_busy && tick) begin
            tx        <= shift_reg[0];
            shift_reg <= {1'b1, shift_reg[9:1]};
            bit_cnt   <= bit_cnt + 4'd1;
            if (bit_cnt == 4'd9) begin
                tx_busy <= 1'b0;
            end
        end
    end
endmodule
