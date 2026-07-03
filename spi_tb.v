//=====================================================================
// SPI Testbench
// Connects spi_master and spi_slave back-to-back and performs several
// full-duplex byte exchanges to demonstrate the protocol on the waveform.
//=====================================================================
`timescale 1ns/1ps

module spi_tb;

    localparam CLK_DIV = 4;

    reg        clk;
    reg        rst_n;
    reg        start;
    reg  [7:0] m_tx_data;
    wire [7:0] m_rx_data;
    wire       m_done;

    wire       sclk;
    wire       mosi;
    wire       miso;
    wire       cs_n;

    reg  [7:0] s_tx_data;
    wire [7:0] s_rx_data;
    wire       s_done;

    spi_master #(.CLK_DIV(CLK_DIV)) DUT_MASTER (
        .clk    (clk),
        .rst_n  (rst_n),
        .start  (start),
        .tx_data(m_tx_data),
        .rx_data(m_rx_data),
        .done   (m_done),
        .sclk   (sclk),
        .mosi   (mosi),
        .miso   (miso),
        .cs_n   (cs_n)
    );

    spi_slave DUT_SLAVE (
        .clk    (clk),
        .rst_n  (rst_n),
        .sclk   (sclk),
        .mosi   (mosi),
        .miso   (miso),
        .cs_n   (cs_n),
        .tx_data(s_tx_data),
        .rx_data(s_rx_data),
        .done   (s_done)
    );

    initial clk = 1'b0;
    always #10 clk = ~clk;   // 50 MHz

    integer errors = 0;
    reg [7:0] exp_master_rx, exp_slave_rx;

    task do_transfer(input [7:0] master_sends, input [7:0] slave_sends);
        begin
            s_tx_data     = slave_sends;   // preload what the slave will return
            exp_master_rx = slave_sends;
            exp_slave_rx  = master_sends;

            @(posedge clk);
            m_tx_data = master_sends;
            start     = 1'b1;
            @(posedge clk);
            start = 1'b0;
            wait (m_done == 1'b1);
            @(posedge clk);

            if (m_rx_data !== exp_master_rx) begin
                errors = errors + 1;
                $display("T=%0t ERROR master_rx: expected=%h got=%h", $time, exp_master_rx, m_rx_data);
            end else
                $display("T=%0t PASS master received 0x%h from slave", $time, m_rx_data);

            if (s_rx_data !== exp_slave_rx) begin
                errors = errors + 1;
                $display("T=%0t ERROR slave_rx: expected=%h got=%h", $time, exp_slave_rx, s_rx_data);
            end else
                $display("T=%0t PASS slave received 0x%h from master", $time, s_rx_data);
        end
    endtask

    initial begin
        $dumpfile("spi_tb.vcd");
        $dumpvars(0, spi_tb);

        rst_n     = 1'b0;
        start     = 1'b0;
        m_tx_data = 8'h00;
        s_tx_data = 8'h00;
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (5) @(posedge clk);

        do_transfer(8'hA5, 8'h5A);
        repeat (10) @(posedge clk);

        do_transfer(8'h3C, 8'hC3);
        repeat (10) @(posedge clk);

        do_transfer(8'hFF, 8'h00);
        repeat (10) @(posedge clk);

        do_transfer(8'h81, 8'h7E);
        repeat (10) @(posedge clk);

        if (errors == 0)
            $display("\n*** SPI TEST PASSED: all bytes exchanged correctly ***\n");
        else
            $display("\n*** SPI TEST FAILED: %0d mismatch(es) ***\n", errors);

        $finish;
    end

    initial begin
        $monitor("T=%0t cs_n=%b sclk=%b mosi=%b miso=%b | m_done=%b m_rx=%h | s_done=%b s_rx=%h",
                   $time, cs_n, sclk, mosi, miso, m_done, m_rx_data, s_done, s_rx_data);
    end

endmodule