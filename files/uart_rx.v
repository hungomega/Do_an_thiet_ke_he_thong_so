// uart_rx.v
// Lay mau RX o giua moi bit bang tick_x16 (oversample 16x) de chong lech pha.

module uart_rx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tick_x16,
    input  wire       rx,
    output reg        rx_ready,   // 1 xung khi co byte moi hop le
    output reg [7:0]  rx_data
);
    localparam IDLE  = 2'd0,
               START = 2'd1,
               DATA  = 2'd2,
               STOP  = 2'd3;

    reg [1:0] state;
    reg [3:0] sample_cnt;
    reg [3:0] bit_idx;
    reg [7:0] shift_reg;
    reg       rx_sync0, rx_sync1; // dong bo hoa tin hieu ngoai (double flop)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync0 <= 1'b1;
            rx_sync1 <= 1'b1;
        end else begin
            rx_sync0 <= rx;
            rx_sync1 <= rx_sync0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            rx_ready   <= 1'b0;
            sample_cnt <= 4'd0;
            bit_idx    <= 4'd0;
        end else begin
            rx_ready <= 1'b0; // mac dinh, chi len 1 dung 1 chu ky khi co du lieu
            case (state)
                IDLE: begin
                    if (!rx_sync1) begin // phat hien canh xuong = start bit
                        state      <= START;
                        sample_cnt <= 4'd0;
                    end
                end

                START: if (tick_x16) begin
                    if (sample_cnt == 4'd7) begin // giua start bit
                        if (!rx_sync1) begin      // xac nhan van la start (chong nhieu)
                            state      <= DATA;
                            sample_cnt <= 4'd0;
                            bit_idx    <= 4'd0;
                        end else begin
                            state <= IDLE;         // nhieu gia, quay lai IDLE
                        end
                    end else begin
                        sample_cnt <= sample_cnt + 4'd1;
                    end
                end

                DATA: if (tick_x16) begin
                    if (sample_cnt == 4'd15) begin
                        shift_reg  <= {rx_sync1, shift_reg[7:1]}; // dich LSB truoc
                        sample_cnt <= 4'd0;
                        if (bit_idx == 4'd7) begin
                            state <= STOP;
                        end else begin
                            bit_idx <= bit_idx + 4'd1;
                        end
                    end else begin
                        sample_cnt <= sample_cnt + 4'd1;
                    end
                end

                STOP: if (tick_x16) begin
                    if (sample_cnt == 4'd15) begin
                        rx_data  <= shift_reg;
                        rx_ready <= 1'b1;
                        state    <= IDLE;
                    end else begin
                        sample_cnt <= sample_cnt + 4'd1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
