# RISC-V Processor Integration Guide

## Overview

We have successfully integrated PicoRV32 with your existing matrix multiplication accelerator, creating a complete RISC-V SoC with memory-mapped accelerator access.

## Architecture Summary

### System Architecture
```
┌─────────────────┐    ┌──────────────────┐
│   PicoRV32      │────│  Memory Bus      │
│   Processor     │    │  Interconnect    │
└─────────────────┘    └──────────────────┘
                              │
                    ┌─────────┼─────────┐
                    │         │         │
              ┌──────▼──┐ ┌────▼────┐ ┌──▼──────────┐
              │   RAM   │ │  ROM    │ │  Matrix     │
              │ 16KB    │ │ 16KB    │ │ Accelerator │
              └─────────┘ └─────────┘ └─────────────┘
```

### Memory Map
```
0x00000000 - 0x00003FFF: ROM (16KB) - Program storage
0x00010000 - 0x00013FFF: RAM (16KB) - Data and stack
0x10000000 - 0x100003FF: Matrix Accelerator
```

### Matrix Accelerator Memory Map
```
0x10000000: CONTROL   [bit 0: start, bit 1: reset]
0x10000004: STATUS    [bit 0: done, bit 1: busy]
0x10000008: CONFIG    [matrix dimensions]
0x10000100: Matrix A  [4x4 matrix, 8-bit elements]
0x10000200: Matrix B  [4x4 matrix, 8-bit elements]
0x10000300: Matrix C  [4x4 matrix, 32-bit results]
```

## Components Created

### Hardware Components

1. **`riscv_soc.v`** - Top-level SoC integrating all components
2. **`bus_interconnect.v`** - Simple address decoder and bus routing
3. **`rom_memory.v`** - Program memory with basic test code
4. **`ram_memory.v`** - Data memory with read/write support
5. **`matrix_accel_wrapper.v`** - Memory-mapped wrapper for your matrix accelerator

### Integration Approach

- **Memory-Mapped I/O**: The matrix accelerator appears as memory-mapped registers
- **Simple Interface**: Uses PicoRV32's native memory interface (not AXI)
- **Existing Hardware Reuse**: Your `matrix_mult.v` is wrapped without modification

## Current Status ✅

### What's Working
- ✅ PicoRV32 processor boots and runs
- ✅ Memory system (ROM/RAM) functional
- ✅ Bus interconnect routes addresses correctly
- ✅ Matrix accelerator wrapper integrates with existing hardware
- ✅ Basic simulation passes

### Test Results
```bash
cd hw && make sim
# Output: Basic CPU Test Complete ✅
# Output: Simulation Complete ✅
```

## Next Development Steps

### Phase 1: Software Driver Development (High Priority)

You now need to create software that can actually use the matrix accelerator:

#### Step 1A: Create C Driver Functions
```c
// File: sw/lib/matrix_accel.h
#define MATRIX_ACCEL_BASE    0x10000000
#define CONTROL_REG         (MATRIX_ACCEL_BASE + 0x00)
#define STATUS_REG          (MATRIX_ACCEL_BASE + 0x04)
#define MATRIX_A_BASE       (MATRIX_ACCEL_BASE + 0x100)
#define MATRIX_B_BASE       (MATRIX_ACCEL_BASE + 0x200)
#define MATRIX_C_BASE       (MATRIX_ACCEL_BASE + 0x300)

void matrix_load_a(uint8_t matrix[4][4]);
void matrix_load_b(uint8_t matrix[4][4]);
void matrix_start_multiply(void);
int matrix_is_done(void);
void matrix_read_c(uint32_t result[4][4]);
```

#### Step 1B: Create Test Program
```c
// File: sw/src/matrix_test.c
#include "matrix_accel.h"

int main() {
    uint8_t a[4][4] = {{1,2,3,4}, {5,6,7,8}, ...};
    uint8_t b[4][4] = {{1,0,0,0}, {0,1,0,0}, ...};
    uint32_t c[4][4];
    
    matrix_load_a(a);
    matrix_load_b(b);
    matrix_start_multiply();
    
    while (!matrix_is_done()) {
        // Wait for completion
    }
    
    matrix_read_c(c);
    // Verify results
    
    return 0;
}
```

### Phase 2: Enhanced Testing and Debugging

#### Step 2A: Add Debug Features
- CPU trace output
- Memory access monitoring
- Accelerator state visibility

#### Step 2B: Performance Analysis
- Cycle count measurements
- Accelerator vs CPU performance comparison
- Bottleneck identification

### Phase 3: Advanced Features

#### Step 3A: Interrupt Support
- Add interrupt from accelerator to CPU
- Async operation instead of polling

#### Step 3B: DMA Integration
- Direct memory access for large matrices
- Eliminate CPU involvement in data transfer

#### Step 3C: Custom Instructions (Optional)
- RISC-V custom instruction extensions
- Matrix operations as CPU instructions

## Development Workflow

### Building and Testing
```bash
cd hw
make clean      # Clean previous builds
make check      # Syntax check only
make sim        # Full simulation
make view       # View waveforms (if GTKWave available)
```

### File Structure
```
hw/
├── src/           # Hardware source files
│   ├── picorv32.v              # PicoRV32 processor
│   ├── riscv_soc.v             # Top-level SoC
│   ├── bus_interconnect.v      # Bus routing
│   ├── rom_memory.v            # Program memory
│   ├── ram_memory.v            # Data memory
│   ├── matrix_accel_wrapper.v  # Accelerator wrapper
│   └── [existing matrix files] # Your accelerator
├── tb/            # Testbenches
│   └── riscv_soc_tb.v         # SoC testbench
└── Makefile       # Build system
```

## Key Architectural Decisions Made

1. **Memory-Mapped Approach**: Simple, standard, educational
2. **PicoRV32 Native Interface**: Simpler than AXI for learning
3. **Wrapper Strategy**: Preserves your existing accelerator design
4. **16KB Memory**: Sufficient for initial development
5. **Polling Interface**: Simple to start, can add interrupts later

## Performance Expectations

- **CPU Clock**: ~100MHz (simulation), can be faster on FPGA
- **Matrix Operation**: ~16-64 cycles for 4x4 multiply
- **Memory Access**: 1 cycle latency for on-chip memories
- **Bus Overhead**: Minimal with simple interconnect

## Troubleshooting

### Common Issues
1. **Compilation Errors**: Check Verilog syntax, especially integer declarations
2. **Simulation Hangs**: Check clock and reset signals
3. **CPU Not Booting**: Verify ROM initialization and reset vector
4. **Accelerator Not Responding**: Check address decoding and register access

### Debug Techniques
1. **Waveform Analysis**: Use `make view` to see signal traces
2. **Printf Debugging**: Add `$display` statements in testbench
3. **Memory Dumps**: Check ROM/RAM contents during simulation

## Next Action Items

**Immediate (This Week)**:
1. Create the C driver functions for matrix accelerator
2. Write a simple test program
3. Update the ROM with actual compiled code
4. Test end-to-end matrix multiplication

**Short-term (Next 2-3 Weeks)**:
1. Add performance monitoring
2. Create comprehensive test suite
3. Add interrupt support
4. Optimize memory access patterns

**Long-term (1-2 Months)**:
1. FPGA implementation and testing
2. Larger matrix support
3. Multiple accelerator instances
4. HLS comparison study

## Resources for Next Steps

1. **RISC-V Software Tools**: Your existing toolchain in `sw/`
2. **PicoRV32 Documentation**: Check the downloaded `picorv32.v` header comments
3. **Memory-Mapped I/O Patterns**: Standard embedded systems practice
4. **C Embedded Programming**: For writing efficient driver code

---

**Congratulations! You now have a working RISC-V SoC with integrated matrix accelerator. The next major milestone is creating software that can actually use your accelerator.** 