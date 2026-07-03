//=====================================================================
// SPI RTL - Master and Slave (Mode 0: CPOL=0, CPHA=0)
// For simulation in Xilinx Vivado
// Full-duplex 8-bit transfer, MSB first
//=====================================================================

//---------------------------------------------------------------------
// SPI Master
//---------------------------------------------------------------------
module spi_master #(
    parameter CLK_DIV = 4     // sclk toggles every CLK_DIV system clocks
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,       // pulse high for 1 clk to begin a transfer
    input  wire [7:0] tx_data,     // byte to send to the slave
    output reg  [7:0] rx_data,     // byte received from the slave
    output reg         done,       // 1-clk pulse when transfer complete
    output reg          sclk,      // serial clock
    output reg          mosi,      // master out slave in
    input  wire         miso,      // master in slave out
    output reg          cs_n       // active-low chip select
);
    localparam S_IDLE = 2'd0, S_XFER = 2'd1, S_DONE = 2'd2;

    reg [1:0] state;
    reg [2:0] bit_cnt;      // counts completed falling edges (0-7)
    reg [7:0] shift_tx;
    reg [7:0] shift_rx;
    reg [7:0] clk_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= S_IDLE;
            sclk     <= 1'b0;
            mosi     <= 1'b0;
            cs_n     <= 1'b1;
            done     <= 1'b0;
            bit_cnt  <= 3'd0;
            clk_cnt  <= 8'd0;
            shift_tx <= 8'd0;
            shift_rx <= 8'd0;
            rx_data  <= 8'd0;
        end else begin
            done <= 1'b0;
            case (state)
                S_IDLE: begin
                    sclk <= 1'b0;
                    cs_n <= 1'b1;
                    if (start) begin
                        shift_tx <= tx_data;
                        mosi     <= tx_data[7];  // setup MSB before first rising edge
                        cs_n     <= 1'b0;
                        bit_cnt  <= 3'd0;
                        clk_cnt  <= 8'd0;
                        state    <= S_XFER;
                    end
                end

                S_XFER: begin
                    if (clk_cnt == CLK_DIV-1) begin
                        clk_cnt <= 8'd0;
                        sclk    <= ~sclk;
                        if (sclk == 1'b0) begin
                            // about to rise -> sample MISO on rising edge
                            shift_rx <= {shift_rx[6:0], miso};
                        end else begin
                            // about to fall -> shift out next MOSI bit
                            if (bit_cnt == 3'd7) begin
                                state <= S_DONE;
                            end else begin
                                bit_cnt  <= bit_cnt + 1'b1;
                                shift_tx <= shift_tx << 1;
                                mosi     <= shift_tx[6];
                            end
                        end
                    end else
                        clk_cnt <= clk_cnt + 1'b1;
                end

                S_DONE: begin
                    cs_n    <= 1'b1;
                    sclk    <= 1'b0;
                    rx_data <= shift_rx;
                    done    <= 1'b1;
                    state   <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule


//---------------------------------------------------------------------
// SPI Slave
//---------------------------------------------------------------------
module spi_slave (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       sclk,
    input  wire       mosi,
    output reg        miso,
    input  wire       cs_n,
    input  wire [7:0] tx_data,     // byte the slave will send back to master
    output reg  [7:0] rx_data,     // byte received from the master
    output reg        done         // 1-clk pulse when a full byte has been exchanged
);
    reg [2:0] bit_cnt;
    reg [7:0] shift_tx;
    reg [7:0] shift_rx;
    reg       sclk_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sclk_d <= 1'b0;
        else
            sclk_d <= sclk;
    end

    wire sclk_rising  = (sclk == 1'b1) && (sclk_d == 1'b0);
    wire sclk_falling = (sclk == 1'b0) && (sclk_d == 1'b1);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt  <= 3'd0;
            shift_tx <= 8'd0;
            shift_rx <= 8'd0;
            rx_data  <= 8'd0;
            miso     <= 1'b0;
            done     <= 1'b0;
        end else begin
            done <= 1'b0;
            if (cs_n) begin
                // deselected: preload next byte to send, ready for next transfer
                bit_cnt  <= 3'd0;
                shift_tx <= tx_data;
                miso     <= tx_data[7];
            end else begin
                if (sclk_rising) begin
                    shift_rx <= {shift_rx[6:0], mosi};
                end
                if (sclk_falling) begin
                    if (bit_cnt == 3'd7) begin
                        rx_data  <= shift_rx;
                        done     <= 1'b1;
                        bit_cnt  <= 3'd0;
                        shift_tx <= tx_data;
                        miso     <= tx_data[7];
                    end else begin
                        bit_cnt  <= bit_cnt + 1'b1;
                        shift_tx <= shift_tx << 1;
                        miso     <= shift_tx[6];
                    end
                end
            end
        end
    end
endmodule