# RISC-V AXI-Lite UART SoC

A small RISC-V based System-on-Chip (SoC) implemented in Verilog RTL, integrating the open-source PicoRV32 processor core with an AXI-based interconnect, on-chip RAM, and a memory-mapped UART.

## Project Overview

This project demonstrates a digital-design flow from RISC-V firmware execution to AXI-based peripheral access and ASIC physical-design exploration.

Main functional path:

    PicoRV32
        |
      AXI-Lite
        |
    AXI Interconnect
       / \
      /   \
   AXI RAM  AXI UART
                |
             UART TX/RX

## Main Features

- Open-source PicoRV32 RISC-V CPU integration
- AXI-Lite based SoC interconnect
- Memory-mapped AXI RAM
- AXI-connected UART TX/RX
- Address decoding for RAM and UART regions
- RISC-V firmware-driven UART transmission
- Verilator functional verification
- GTKWave waveform analysis
- Yosys RTL synthesis
- Synthesized netlist and schematic generation
- OpenLane / OpenROAD physical-design exploration using SKY130A

## Architecture

| Module | Description |
|---|---|
| `soc_top.v` | Top-level SoC integration |
| `axi_interconnect.v` | AXI address decoding, routing and response selection |
| `axi_ram.v` | AXI-connected program/data RAM |
| `axi_uart.v` | Memory-mapped AXI UART interface |
| `uart_tx.v` | UART transmitter |
| `uart_rx.v` | UART receiver |
| `picorv32a.v` | Open-source PicoRV32 RISC-V CPU core |

## Memory Map

| Address | Function |
|---|---|
| `0x00000000` region | SoC RAM / program memory |
| `0x10000000` | UART TX register |
| `0x10000004` | UART RX data register |
| `0x10000008` | UART status register |

The interconnect uses the address to determine whether a transaction is directed to RAM or UART.

Example address decoding:

    assign addr_is_ram  = (m_awaddr[31:28] == 4'h0);
    assign addr_is_uart = (m_awaddr[31:28] == 4'h1);

Therefore, `0x10000000` is identified as a UART transaction.

## Firmware Demonstration

The firmware performs a memory-mapped write to the UART transmit register:

    #define UART_TX 0x10000000
    *(volatile unsigned int *)UART_TX = 0x41;

`0x41` corresponds to the ASCII character `A`.

### Firmware Flow

    uart_test.c
        |
     RISC-V GCC
        |
    uart_test.elf
        |
    uart_test.bin
        |
    uart_test_words.hex
        |
    AXI RAM initialization
        |
    PicoRV32 executes firmware

## Verification

Verification was performed at both module and complete-SoC levels.

### Testbenches

- `tb_uart_tx.v` — UART transmitter verification
- `tb_uart_rx.v` — UART receiver verification
- `tb_axi_uart.v` — AXI UART verification
- `tb_axi_ram.v` — AXI RAM read/write verification
- `tb_axi.v` — AXI interconnect verification
- `tb_soc.v` — complete CPU-to-AXI-to-UART SoC verification

### Complete SoC Result

    DUT: AW HANDSHAKE addr=10000000
    DUT: W HANDSHAKE data=00000041
    UART TX STARTED.
    CPU successfully reached UART TX register.
    UART TX COMPLETED.

    RISC-V AXI UART TEST PASSED.

Functional path:

    RISC-V firmware
          |
       PicoRV32
          |
       AXI write
          |
    AXI Interconnect
          |
       AXI UART
          |
       UART TX

## Waveform Analysis

GTKWave was used to inspect:

- CPU AXI write-address handshake
- CPU AXI write-data handshake
- Interconnect routing to UART
- UART `tx_start`
- UART `tx_busy`
- UART serial `tx` waveform

## Yosys Synthesis

The RTL was synthesized using Yosys.

Observed generic synthesis results:

| Module / Hierarchy | Cells |
|---|---:|
| Complete `soc_top` hierarchy | 81,842 |
| `axi_ram` | 70,933 |
| `axi_uart` | 134 |
| `uart_rx` | 550 |
| `uart_tx` | 258 |
| `axi_interconnect` | 73 |

The current RAM implementation dominates the generic cell count because the memory is represented using standard-cell sequential and multiplexing logic rather than a dedicated SRAM macro.

## ASIC Physical-Design Exploration

The design was taken through the OpenLane flow using:

- OpenLane v1.0.2
- OpenROAD
- SKY130A PDK
- `sky130_fd_sc_hd` standard-cell library

### Physical-Design Stages Reached

    RTL Design
        |
    Synthesis                    ✓
        |
    Static Timing Analysis       ✓
        |
    Floorplanning                ✓
        |
    I/O Placement                ✓
        |
    Tap/Decap Insertion          ✓
        |
    Power Planning / PDN         ✓
        |
    Global Placement             ✓
        |
    Detailed Placement           ✓
        |
    Clock Tree Synthesis         ✓
        |
    Routing                      ✗ High Congestion
        |
    Final GDS                    Not generated

The OpenLane run successfully progressed through clock-tree synthesis. The routing stage stopped because of high routing congestion.

### Routing Limitation

The generic synthesis showed approximately 70,933 cells for `axi_ram`, including approximately:

- 32,768 flip-flops
- 32,840 multiplexers

Implementing the RAM as standard-cell logic creates significant placement and routing demand.

The OpenLane run reported approximately 1,045,011 final vias before reporting:

    Routing congestion too high

This is an implementation limitation of the current architecture, not a functional failure of the SoC.

## Future Improvements

- Replace the register-based RAM with an appropriate SRAM macro
- Reduce RAM size for a smaller demonstration implementation
- Optimize floorplan and utilization for improved routability
- Complete routing and physical signoff
- Generate final routed GDS after memory/physical-design optimization
- Extend firmware tests and add additional peripherals

## Tools Used

- Verilog
- RISC-V
- AXI / AXI-Lite
- UART
- Verilator
- GTKWave
- Yosys
- OpenLane
- OpenROAD
- SKY130A PDK

## Repository Structure

    riscv_axi_lite_soc/
    ├── rtl/              RTL design
    ├── ip/               Open-source PicoRV32 IP
    ├── tb/               Testbenches
    ├── sw/               RISC-V firmware and memory images
    ├── synthesis/        Yosys netlist, logs and schematics
    ├── openlane/         OpenLane configuration
    ├── docs/             Project report
    ├── sim/              Simulation artifacts
    └── README.md

## Project Report

The detailed project report is included in the repository.

`RISC_V_AXI_UART_SoC_Project_Report.pdf`

## Attribution

PicoRV32 is open-source hardware developed and maintained through the YosysHQ PicoRV32 project. It was integrated as pre-existing IP and was not developed from scratch as part of this project.

See the project report for references and additional implementation details.
