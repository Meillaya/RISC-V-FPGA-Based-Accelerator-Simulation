# RISC-V FPGA-Based Accelerator Simulation

**Status: Phase 1 Complete - Hardware-Software Integration Successful**

This project implements a complete RISC-V SoC with matrix multiplication acceleration capabilities. The system demonstrates end-to-end hardware-software integration with a PicoRV32 processor controlling a custom matrix accelerator via memory-mapped I/O.

## What We've Built

- **RISC-V SoC**: Complete system-on-chip with PicoRV32 processor
- **Matrix Accelerator**: 4x4 matrix multiplication hardware accelerator  
- **Memory Subsystem**: ROM, RAM, and memory-mapped I/O integration
- **Software Toolchain**: Cross-compilation and hardware simulation framework
- **Integration Testing**: Validated hardware-software communication

## Project Structure

```
.
├── hw/                     # Hardware implementation
│   ├── src/               # Verilog source files
│   │   ├── riscv_soc.v           # Main SoC implementation
│   │   ├── matrix_accel_wrapper.v # Matrix accelerator interface
│   │   ├── picorv32.v            # RISC-V processor core
│   │   └── ...
│   ├── tb/                # Testbenches
│   │   └── riscv_soc_tb.v        # Integration test testbench
│   └── Makefile           # Hardware build system
├── sw/                     # Software implementation  
│   ├── src/               # Source programs
│   │   ├── simple_matrix_test.s  # Assembly integration test
│   │   ├── matrix_test.c         # C matrix test program
│   │   └── ...
│   ├── lib/               # Software libraries
│   └── Makefile           # Software build system
├── tools/                  # Build utilities
│   └── bin2rom.py         # Binary to ROM converter
├── docs/                   # Documentation
│   ├── 05_phase1_integration_results.md # Complete technical report
│   ├── 04_c_driver_development_guide.md
│   ├── 03_riscv_integration_guide.md
│   └── 02_hardware_design_theory.md
├── PHASE1_COMPLETION.md    # Project summary and achievements
└── README.md              # This file
```

## Quick Start

### Prerequisites

**Hardware Simulation:**
```bash
# Icarus Verilog for hardware simulation
sudo pacman -S iverilog        # Arch Linux
sudo apt-get install iverilog  # Ubuntu/Debian
```

**Software Cross-Compilation:**
```bash
# RISC-V toolchain
yay -S riscv64-gnu-toolchain-elf-bin    # Arch Linux (AUR)
sudo apt-get install gcc-riscv64-unknown-elf  # Ubuntu/Debian
```

### Running the Integration Test

**1. Hardware-Software Integration Simulation:**
```bash
# Run the complete system simulation
cd hw
make clean && make sim
```

This runs the RISC-V SoC with the matrix accelerator test program, demonstrating:
- CPU boot and initialization
- Matrix data setup and computation start
- Hardware-software communication via memory-mapped I/O
- Real-time monitoring of accelerator operations

**2. Software Compilation:**
```bash
# Compile the assembly test program
cd sw
/opt/riscv64-gnu-toolchain-elf-bin/bin/riscv64-unknown-elf-gcc \
  -march=rv32i -mabi=ilp32 -T src/simple_test.ld \
  -nostdlib -nostartfiles \
  -o build/simple_matrix_test src/simple_matrix_test.s
```

**3. Convert to Hardware ROM:**
```bash
# Convert compiled binary to Verilog ROM format
python3 tools/bin2rom.py sw/build/simple_matrix_test.bin hw/src/rom_memory.v --verilog
```

### System Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   PicoRV32      │    │  Bus Interconnect │    │ Matrix Accel    │
│   RISC-V CPU    │◄──►│                  │◄──►│ 4x4 Multiplier │
│                 │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                               │
                       ┌───────┴───────┐
                       │               │
                ┌──────▼──────┐ ┌──────▼──────┐
                │    ROM      │ │    RAM      │
                │   16KB      │ │   16KB      │
                │ 0x80000000  │ │ 0x80004000  │
                └─────────────┘ └─────────────┘

Memory Map:
- ROM:    0x80000000-0x80003FFF (Program storage)
- RAM:    0x80004000-0x80007FFF (Data/stack)  
- ACCEL:  0x10000000-0x100003FF (Matrix accelerator registers)
```

## Key Test Results

**Successfully Validated:**
- CPU boots correctly and executes RISC-V instructions
- Matrix data written to accelerator via memory-mapped I/O
- Control register starts matrix multiplication
- Status register polling confirms hardware activity
- Complete hardware-software communication verified

**Sample Test Output:**
```
=== RISC-V SoC Matrix Accelerator Integration Test ===
Time: 100000 - Reset released, CPU should start at PC: 0x80000000
Time: 355000 - Matrix accel WRITE: Addr=0x10000000, Data=0x01020304
Time: 465000 - Matrix accel WRITE: Addr=0x10000004, Data=0x05060708
...
Time: 1205000 - Matrix accel WRITE: Addr=0x10000100, Data=0x00000001
Time: 1315000 - Matrix accel read: Addr=0x10000104, Data=0x00000001
STATUS: System Integration SUCCESSFUL
```

## Matrix Accelerator Interface

**Register Map:**
```
0x10000000-0x1000003F: Matrix A Data (4x4, 8-bit elements)
0x10000040-0x1000007F: Matrix B Data (4x4, 8-bit elements)
0x10000080-0x100000BF: Result Matrix C (4x4, 32-bit elements)
0x10000100: Control Register [0]=start, [1]=reset
0x10000104: Status Register [0]=busy, [1]=done
0x10000108: Config Register [7:0]=N, [15:8]=P
```

**Usage Example (Assembly):**
```assembly
# Write matrix data
lui t0, %hi(0x10000000)
li t1, 0x01020304
sw t1, 0(t0)           # Store to Matrix A

# Start computation  
li t1, 0x1
sw t1, 256(t0)         # Write to control register

# Poll for completion
wait_loop:
    lw t1, 260(t0)     # Read status register
    andi t2, t1, 0x2   # Check done bit
    beqz t2, wait_loop
```

## Build System

**Hardware Simulation:**
```bash
cd hw
make clean    # Clean build artifacts
make sim      # Compile and run simulation  
make view     # Open waveform viewer (if GTKWave available)
```

**Software Development:**
```bash
cd sw
make clean    # Clean build artifacts  
make          # Compile software programs
```

**Integration Utilities:**
```bash
# Convert binary to ROM
python3 tools/bin2rom.py <binary_file> <output.v> --verilog

# Check simulation results
tail hw/test_results.log
```

## Performance Characteristics

**Communication Performance:**
- Memory access: ~10ns (zero wait state)
- Accelerator register access: ~80-110ns per operation
- Matrix setup time: ~2.4μs for 4x4 matrices

**System Resources:**
- ROM: 16KB (program storage)
- RAM: 16KB (data/stack)
- Matrix accelerator: 1KB register space
- Test program: 236 bytes compiled assembly

## Next Steps (Phase 2)

- **Performance Optimization**: Accelerator pipeline improvements
- **C Library Development**: High-level matrix operation APIs
- **FPGA Synthesis**: Target real hardware platforms  
- **Benchmarking**: Comprehensive performance analysis
- **Feature Expansion**: Larger matrices, multiple data types

## License

This project is for educational and research purposes, demonstrating RISC-V SoC design with hardware acceleration.

---
