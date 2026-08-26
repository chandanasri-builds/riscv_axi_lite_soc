# RISC-V AXI-Lite UART SoC

A small RISC-V based System-on-Chip (SoC) implemented in Verilog RTL, integrating the open-source PicoRV32 processor core with an AXI-based interconnect, on-chip RAM, and a memory-mapped UART.

## Project Overview

The project demonstrates a complete digital-design flow from RISC-V firmware execution to AXI-based peripheral access and ASIC physical-design exploration.

The main functional path is:

```text
                    +------------------+
                    |    PicoRV32      |
                    |   RISC-V CPU     |
                    +--------+---------+
                             |
                          AXI-Lite
                             |
                    +--------v---------+
                    | AXI Interconnect |
                    | Address Decode   |
                    +----+--------+----+
                         |        |
                  +------v--+  +--v-------+
                  | AXI RAM  |  | AXI UART |
                  +---------+  +-----+-----+
                                     |
                                  UART TX/RX

Main Features
Open-source PicoRV32 RISC-V CPU integration
AXI-Lite based SoC interconnect
Memory-mapped AXI RAM
AXI-connected UART TX/RX
Address decoding for RAM and UART regions
RISC-V firmware-driven UART transmission
Verilator functional verification
GTKWave waveform analysis
Yosys RTL synthesis
Synthesized netlist and schematic generation
OpenLane / OpenROAD physical-design exploration using SKY130A
Architecture

The SoC contains the following major blocks:
| Module               | Description                                          |
| -------------------- | ---------------------------------------------------- |
| `soc_top.v`          | Top-level SoC integration                            |
| `axi_interconnect.v` | AXI address decoding, routing and response selection |
| `axi_ram.v`          | AXI-connected program/data RAM                       |
| `axi_uart.v`         | Memory-mapped AXI UART interface                     |
| `uart_tx.v`          | UART transmitter                                     |
| `uart_rx.v`          | UART receiver                                        |
| `picorv32a.v`        | Open-source PicoRV32 RISC-V CPU core                 |

Memory Map

| Address             | Function                 |
| ------------------- | ------------------------ |
| `0x00000000` region | SoC RAM / program memory |
| `0x10000000`        | UART TX register         |
| `0x10000004`        | UART RX data register    |
| `0x10000008`        | UART status register     |

The interconnect uses the upper address bits to distinguish the major regions.

For example:

assign addr_is_ram  = (m_awaddr[31:28] == 4'h0);
assign addr_is_uart = (m_awaddr[31:28] == 4'h1);

Therefore, an address such as 0x10000000 is identified as a UART transaction.

Firmware Demonstration

The firmware performs a memory-mapped write to the UART transmit register:

#define UART_TX 0x10000000

*(volatile unsigned int *)UART_TX = 0x41;

0x41 corresponds to the ASCII character A.

The firmware was compiled for RV32I and converted into a word-oriented hexadecimal memory image used to initialize the RAM.

Firmware Flow
uart_test.c
    ↓
RISC-V GCC
    ↓
uart_test.elf
    ↓
uart_test.bin
    ↓
uart_test_words.hex
    ↓
AXI RAM initialization
    ↓
PicoRV32 executes firmware
Verification

Verification was performed at both module and complete-SoC levels.

Testbenches
tb_uart_tx.v — UART transmitter verification
tb_uart_rx.v — UART receiver verification
tb_axi_uart.v — AXI UART verification
tb_axi_ram.v — AXI RAM read/write verification
tb_axi.v — AXI interconnect verification
tb_soc.v — complete CPU-to-AXI-to-UART SoC verification
Complete SoC Result

The final SoC simulation demonstrated:

DUT: AW HANDSHAKE addr=10000000
DUT: W HANDSHAKE data=00000041
UART TX STARTED.
CPU successfully reached UART TX register.
UART TX COMPLETED.

RISC-V AXI UART TEST PASSED.

This verifies the functional path:

RISC-V firmware
      ↓
PicoRV32
      ↓
AXI write
      ↓
AXI Interconnect
      ↓
AXI UART
      ↓
UART TX
Waveform Analysis

GTKWave was used to inspect:

CPU AXI write-address handshake
CPU AXI write-data handshake
Interconnect routing to UART
UART tx_start
UART tx_busy
UART serial tx waveform

The waveform confirms that the CPU-generated write to 0x10000000 carries 0x00000041 and results in UART transmission.

Yosys Synthesis

The RTL was synthesized using Yosys.

Observed generic synthesis results:

Module / Hierarchy	Cells
Complete soc_top hierarchy	81,842
axi_ram	70,933
axi_uart	134
uart_rx	550
uart_tx	258
axi_interconnect	73

The current RAM implementation dominates the generic cell count because the memory is represented using standard-cell sequential and multiplexing logic rather than a dedicated SRAM macro.

Generated synthesis artifacts include:

synthesis/soc_synth.v
synthesis/synth.log
synthesis/synth.ys
synthesis/axi_interconnect.svg
synthesis/soc_top.svg
ASIC Physical-Design Exploration

The design was taken through the OpenLane flow using:

OpenLane v1.0.2
OpenROAD
SKY130A PDK
sky130_fd_sc_hd standard-cell library
Stages Reached
RTL Design
    ↓
Synthesis               ✓
    ↓
Static Timing Analysis  ✓
    ↓
Floorplanning           ✓
    ↓
I/O Placement           ✓
    ↓
Tap/Decap Insertion     ✓
    ↓
Power Planning / PDN    ✓
    ↓
Global Placement        ✓
    ↓
Detailed Placement      ✓
    ↓
Clock Tree Synthesis    ✓
    ↓
Routing                 ✗ High Congestion
    ↓
Final GDS               Not generated

The OpenLane run successfully progressed through CTS. The routing stage stopped because of high routing congestion.

Routing Limitation

The generic synthesis showed approximately 70,933 cells for axi_ram, including approximately:

32,768 flip-flops
32,840 multiplexers

Implementing the RAM as standard-cell logic creates significant placement and routing demand.

The OpenLane run reported approximately 1,045,011 final vias before reporting:

Routing congestion too high

This is an implementation limitation of the current architecture, not a functional failure of the SoC.

Future Improvements

Possible future improvements include:

Replace the register-based RAM with an appropriate SRAM macro
Reduce memory size for a smaller demonstration implementation
Optimize floorplan/utilization for improved routability
Complete routing and physical signoff
Generate final routed GDS after memory/physical-design optimization
Extend firmware tests and add additional peripherals
Tools Used
Verilog
RISC-V
AXI / AXI-Lite
UART
Verilator
GTKWave
Yosys
OpenLane
OpenROAD
SKY130A PDK


