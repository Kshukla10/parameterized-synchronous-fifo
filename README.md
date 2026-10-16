# Parameterized Synchronous FIFO in Verilog

A synchronous First-In, First-Out (FIFO) buffer implemented in Verilog HDL and verified using Xilinx Vivado.

## Project Overview

This project implements a parameterized synchronous FIFO for temporary data storage and ordered retrieval. It demonstrates RTL design, sequential logic, pointer management, status flag generation, self-checking verification, and FPGA implementation analysis.

## Features

- Configurable data width and FIFO depth
- Single-clock synchronous operation
- Read and write pointer management with wraparound
- Full and empty status flags
- Occupancy counter
- Protection against overflow and underflow
- Registered data output
- Simultaneous read/write handling
- Directed and randomized verification

## Default Configuration

| Parameter | Value |
|---|---|
| Data width | 8 bits |
| FIFO depth | 16 entries |
| Storage capacity | 128 bits |
| Clock | Single synchronous clock |
| Reset | Active-high, synchronous |
| HDL | Verilog |
| Tool | Xilinx Vivado |

## Repository Structure

```text
parameterized-synchronous-fifo/
├── rtl/
│   └── sync_fifo.v
├── tb/
│   └── sync_fifo_tb.v
├── constraints/
│   └── sync_fifo.xdc
├── screenshots/
├── README.md
└── .gitignore
```

## Verification

A self-checking Verilog testbench compares the FIFO against a reference model.

Test scenarios include:

1. Reset behavior
2. FIFO data ordering
3. Full-capacity operation
4. Overflow protection
5. FIFO draining
6. Underflow protection
7. Pointer wraparound
8. Simultaneous read/write operations
9. Full-boundary behavior
10. Empty-boundary behavior
11. Randomized stress testing

**Simulation results:**
- 653 cycles checked
- 0 reported errors
- All 11 test groups passed

## Synthesis and Implementation Results

| Metric | Observed result |
|---|---:|
| LUTs | 24 |
| Slice registers | 25 |
| Bonded I/O blocks | 27 |
| BUFGCTRL | 1 |
| Distributed RAM LUTs | 8 |
| Logic LUTs | 16 |
| Post-implementation WNS | +6.518 ns |
| Clock period constraint | 10 ns |

The distributed RAM and logic LUT figures are subdivisions of the total LUT count. Results depend on the selected FPGA target and implementation settings.

The positive worst negative slack indicates that the reported constrained timing paths met the specified clock requirement. External input and output delays were not specified, so these results do not constitute complete board-level timing sign-off.

## Tools Used

- Verilog HDL
- Xilinx Vivado
- Vivado Simulator (XSim)
- XDC timing constraints

## Running the Project

1. Open the project in Xilinx Vivado or create a new RTL project.
2. Add `rtl/sync_fifo.v` as a design source.
3. Add `tb/sync_fifo_tb.v` as a simulation source.
4. Set `sync_fifo_tb` as the simulation top.
5. Run behavioral simulation to completion.
6. Confirm the testbench reports zero errors.
7. Set `sync_fifo` as the synthesis top before synthesis and implementation.

Use a supported FPGA part and document the actual device and Vivado version when reproducing the implementation results.

## Future Improvements

- Add SystemVerilog assertions and functional coverage.
- Verify additional FIFO depths and data widths.
- Explore block RAM inference for larger FIFO configurations.
- Compare alternative FIFO architectures and resource utilization.
