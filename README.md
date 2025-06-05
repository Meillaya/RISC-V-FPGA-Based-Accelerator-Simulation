# RISC-V FPGA-Based Accelerator Simulation

This project is a simulation of a simple AI accelerator (e.g., for matrix operations) using RISC-V.

## Goal

- Simulate a simple AI accelerator for matrix operations.
- Understand hardware-software interfaces.
- Gain experience with High-Level Synthesis (HLS) tools.
- Model performance (latency, throughput).

## Project Structure

```
.
├── benchmarks/
├── docs/
├── hw/
│   ├── src/
│   └── tb/
├── sim/
├── sw/
│   ├── src/
│   └── lib/
└── tools/
```

## Getting Started

We will start by setting up a RISC-V toolchain and a simulator.

### Prerequisites

You will need to install a RISC-V toolchain and the Spike simulator.

#### For Debian/Ubuntu

On Debian/Ubuntu, you can do this with:

```bash
sudo apt-get install build-essential git
# For the toolchain
sudo apt-get install gcc-riscv64-unknown-elf
# For the simulator
sudo apt-get install spike
```

#### For Arch Linux

On Arch Linux, you can install Spike from the official repositories. The RISC-V toolchain is available from the Arch User Repository (AUR). You will need an AUR helper (e.g., `yay`) to install it.

```bash
# For the simulator
sudo pacman -S spike
# For the toolchain from the AUR
yay -S riscv64-gnu-toolchain-elf-bin
```

For other operating systems, please refer to the official installation guides for the [RISC-V GNU Toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain) and [Spike](https://github.com/riscv-software-src/riscv-isa-sim).

### Running the "Hello, World!" example

To compile and run the simple "Hello, World!" example, navigate to the `sw` directory and run `make`:

```bash
cd sw
make run
```

You should see the output "Hello, RISC-V!". This confirms that your toolchain and simulator are set up correctly. 