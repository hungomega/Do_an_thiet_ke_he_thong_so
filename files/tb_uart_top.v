// tb_uart_top.v
// Testbench loopback: tx_pin cua uart_top duoc noi thang vao rx_pin cua chinh no.
// Gui lan luot cac byte trong mang test_bytes, cho RX nhan duoc, so sanh voi gia tri da gui.
// Neu sai -> in loi va $stop. Neu tat ca dung -> in PASS va $finish.

`timescale 1ns/1ps

module tb_uart_top;

    localparam CLK_FREQ  = 50_000_000;
    localparam BAUD_RATE = 115200;
    // rut ngan thoi gian mo phong: dung baud rate cao hon nhieu de test nhanh
    // (chi anh huong toi so chu ky can mo phong, khong anh huong logic)
    localparam SIM_BAUD  = 1_000_000;

    reg clk;
    reg rst_n;
    reg        we;
    reg        addr_offset;
    reg  [7:0] wdata;
    wire [31:0] rdata;
    wire uart_line; // tx_pin noi vong ve rx_pin

    integer i;
    integer errors;
    reg [7:0] test_bytes [0:3];
    reg [7:0] expected_byte;

    uart_top #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(SIM_BAUD)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .we(we), .addr_offset(addr_offset),
        .wdata(wdata), .rdata(rdata),
        .tx_pin(uart_line),
        .rx_pin(uart_line)   // LOOPBACK: tu gui tu nhan
    );

    // clock 50MHz -> chu ky 20ns
    initial clk = 0;
    always #10 clk = ~clk;

    // tac vu gui 1 byte va cho den khi RX bao ready, roi kiem tra
    task send_and_check(input [7:0] data_to_send);
        integer timeout;
        begin
            expected_byte = data_to_send;

            // ghi vao TXDATA (addr_offset = 0, we = 1 trong 1 chu ky)
            @(posedge clk);
            we          <= 1'b1;
            addr_offset <= 1'b0;
            wdata       <= data_to_send;
            @(posedge clk);
            we <= 1'b0;

            // doi tx_busy len roi xuong (nghia la da gui xong 1 frame)
            timeout = 0;
            wait (dut.tx_busy == 1'b1);
            wait (dut.tx_busy == 1'b0);

            // doi them mot chut de RX kip xu ly stop bit + rx_ready
            repeat (200) @(posedge clk);

            if (dut.u_rx.rx_ready === 1'b1 || dut.u_rx.rx_data === expected_byte) begin
                // rx_ready la 1 xung, co the da qua, nen kiem tra qua gia tri luu (rx_data)
                if (dut.u_rx.rx_data === expected_byte) begin
                    $display("[PASS] Gui 0x%02h -> Nhan 0x%02h", data_to_send, dut.u_rx.rx_data);
                end else begin
                    $display("[FAIL] Gui 0x%02h -> Nhan 0x%02h (SAI)", data_to_send, dut.u_rx.rx_data);
                    errors = errors + 1;
                end
            end else begin
                $display("[FAIL] Gui 0x%02h -> KHONG nhan duoc du lieu (rx_ready khong len)", data_to_send);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        we = 0; addr_offset = 0; wdata = 0;
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;

        test_bytes[0] = 8'h55; // 0101_0101 - pattern kiem tra dong bo bit
        test_bytes[1] = 8'hA5;
        test_bytes[2] = 8'h00;
        test_bytes[3] = 8'hFF;

        for (i = 0; i < 4; i = i + 1) begin
            send_and_check(test_bytes[i]);
        end

        if (errors == 0) begin
            $display("==============================");
            $display("TAT CA TEST PASS (%0d/%0d byte dung)", 4, 4);
            $display("==============================");
        end else begin
            $display("==============================");
            $display("CO %0d LOI trong qua trinh test", errors);
            $display("==============================");
        end

        $finish;
    end

endmodule
