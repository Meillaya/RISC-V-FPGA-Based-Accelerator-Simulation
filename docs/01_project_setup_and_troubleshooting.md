# 1. Project Setup and "Hello, World!"

This document details the initial setup of the RISC-V accelerator simulation project, including toolchain installation, creating a "Hello, World!" program, and the troubleshooting steps required to get it running.

## Initial Project Structure

The project was initialized with the following directory structure to separate hardware, software, documentation, and other components:

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

## Toolchain and Simulator Installation (Arch Linux)

The primary development environment is Arch Linux. The following tools were required:

*   **RISC-V Toolchain**: `riscv64-gnu-toolchain-elf-bin` (from the AUR)
*   **RISC-V Simulator**: `spike` (from the official repositories)

### Installation Steps

1.  **Update System**: The first attempt to install `spike` failed due to outdated package mirrors. This was resolved by synchronizing the package database and upgrading the system:
    ```bash
    sudo pacman -Syu
    ```

2.  **Install Spike**: With the system updated, `spike` was installed from the official repositories:
    ```bash
    sudo pacman -S spike
    ```

3.  **Install AUR Helper**: To install the toolchain from the Arch User Repository (AUR), an AUR helper (`yay`) was used.

4.  **Install RISC-V Toolchain**: The toolchain was installed using `yay`:
    ```bash
    yay -S riscv64-gnu-toolchain-elf-bin
    ```

## "Hello, World!" Bare-Metal Program

A simple "Hello, World!" program was created to verify the toolchain and simulator. Since this is a bare-metal environment, it does not use a standard C library.

### `sw/src/hello.c`

```c
// We are not using the standard library, so we don't include stdio.h
// Instead, we provide a forward declaration of our own puts function.
int puts(const char *s);

int main() {
    puts("Hello, RISC-V!");
    return 0;
}
```

### `sw/src/crt0.s` (Startup Code)

```s
.section .text.init
.globl _start

_start:
    # Initialize stack pointer
    la sp, _stack_top
    # Jump to main C function
    call main

    # Exit via HTIF
    # A non-zero value in tohost signals the simulation to exit.
    # A value of 1 indicates success.
    la t0, tohost
    li t1, 1
    sd t1, 0(t0)

    # Infinite loop to wait for simulation to terminate
1:  j 1b

.section .bss
.align 8
.globl _stack_top
_stack:
    .skip 4096 # 4KB stack
_stack_top:

```

### `sw/lib/syscalls.c` (Custom `puts` implementation)

```c
#include <stddef.h>

// A simple implementation of puts for bare-metal RISC-V using HTIF.

// These symbols are defined in the linker script.
extern volatile long tohost;
extern volatile long fromhost;

int puts(const char *s) {
    int count = 0;
    
    // Simple HTIF console output
    while (*s) {
        // Write character to console (device 1, command 1)
        tohost = 0x0101000000000000UL | (unsigned char)*s;
        while (tohost != 0);
        s++;
        count++;
    }
    
    // Write newline
    tohost = 0x0101000000000000UL | '\n';
    while (tohost != 0);
    count++;
    
    return count;
}
```

### `sw/src/link.ld` (Linker Script)

```ld
OUTPUT_ARCH( "riscv" )
ENTRY( _start )

MEMORY
{
  ram (rwx) : ORIGIN = 0x80000000, LENGTH = 128M
}

SECTIONS
{
  .text : {
    *(.text.init)
    *(.text*)
  } > ram

  .rodata : {
    *(.rodata*)
  } > ram

  .data : {
    *(.data*)
  } > ram

  .bss : {
    *(.bss*)
    . = ALIGN(8);
    _stack = .;
    . += 4096; /* 4k stack */
    _stack_top = .;
  } > ram

  . = ALIGN(0x1000);
  .tohost : {
    tohost = .;
    . += 64;
    fromhost = .;
  } > ram
}
```

### `sw/Makefile`

```makefile
# sw/Makefile

TARGET = hello
RISCV_PREFIX ?= /opt/riscv64-gnu-toolchain-elf-bin/bin/riscv64-unknown-elf-
CC = $(RISCV_PREFIX)gcc
LD = $(RISCV_PREFIX)ld

VPATH = src:lib

SRCS_C = hello.c syscalls.c
SRCS_S = crt0.s
OBJS = $(addprefix build/, $(SRCS_C:.c=.o)) $(addprefix build/, $(SRCS_S:.s=.o))

CFLAGS = -march=rv64gc -mabi=lp64d -O2 -g -mcmodel=medany -Isrc -Ilib
LDFLAGS = -T src/link.ld -nostdlib -nostartfiles

SIMULATOR ?= spike

.PHONY: all clean run

all: build/$(TARGET)

build/$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^

build/%.o: %.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

build/%.o: %.s
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -rf build

run: build/$(TARGET)
	$(SIMULATOR) $<
```

## Troubleshooting Journey

Getting the "Hello, World!" program to run involved several rounds of troubleshooting:

1.  **Compiler Not Found**: Initially, the `Makefile` could not find the `riscv64-unknown-elf-gcc` compiler. We discovered the AUR package installed it to `/opt/riscv64-gnu-toolchain-elf-bin/bin/`, and we had to hardcode this path into the `Makefile`.

2.  **Linker Relocation Error**: The first successful compilation led to a linker error: `relocation truncated to fit: R_RISCV_HI20 against '.LC0'`. This was resolved by adding the `-mcmodel=medany` flag to the compiler flags, which allows for a larger address space.

3.  **Undefined Reference to `puts`**: After fixing the relocation error, we encountered an `undefined reference to 'puts'` linker error. This was because we were not linking against a standard C library. We solved this by writing our own simple `puts` function.

4.  **No Console Output**: Even with a custom `puts` function, we initially saw no output. The first implementation attempted to write directly to a UART memory address, which did not work as expected with Spike.

5.  **HTIF Implementation**: The final and successful solution was to implement `puts` using Spike's Host-Target Interface (HTIF). This required:
    *   Defining `tohost` and `fromhost` symbols in the linker script.
    *   Using the `tohost` symbol in `crt0.s` to properly exit the simulation.
    *   Writing a `puts` function that sends characters to the console via the `tohost` memory-mapped register.

After these steps, the "Hello, World!" program successfully compiled and ran, printing the expected output to the console. 