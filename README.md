# SPI Master-Slave Communication (Verilog)

## Overview
This project implements SPI (Serial Peripheral Interface) Master and Slave modules in Verilog HDL. The design demonstrates full-duplex communication using MOSI and MISO lines and is verified through behavioral simulation.

## Features
- SPI Master
- SPI Slave
- Full Duplex Communication
- MOSI & MISO
- Chip Select (CS)
- SPI Clock Generation
- Self-checking Testbench

## Specifications
- Language: Verilog HDL
- Tool: Xilinx Vivado 2025.1
- SPI Mode: Mode-0
- Clock Divider: 4
- Data Width: 8-bit

## Project Structure
```
spi.v
spi_tb.v
README.md
```

## Simulation
Master transmits:
- 0xA5
- 0x3C
- 0xFF
- 0x81

Slave transmits:
- 0x5A
- 0xC3
- 0x00
- 0x7E

Simulation verifies:
- MOSI Communication
- MISO Communication
- Clock Generation
- Chip Select
- Data Reception
- Error Detection

## Waveform Highlights
- SCLK
- MOSI
- MISO
- CS_N
- Master Receive Data
- Slave Receive Data
- Done Signals

## Result
Master and Slave successfully exchanged all bytes.

Errors = 0

## Future Improvements
- Configurable SPI Modes (0–3)
- Multiple Slave Support
- FIFO Buffer
- DMA Interface
- Variable Clock Divider
