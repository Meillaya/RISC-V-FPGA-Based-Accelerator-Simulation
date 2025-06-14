# sw/Makefile

TARGET = matrix_test
RISCV_PREFIX ?= /opt/riscv64-gnu-toolchain-elf-bin/bin/riscv64-unknown-elf-
CC = $(RISCV_PREFIX)gcc
LD = $(RISCV_PREFIX)ld

VPATH = src:lib

SRCS_C = matrix_test.c matrix_accel_driver.c simple_printf.c syscalls.c
SRCS_S = crt0.s
OBJS = $(addprefix build/, $(SRCS_C:.c=.o)) $(addprefix build/, $(SRCS_S:.s=.o))

CFLAGS = -march=rv32i -mabi=ilp32 -O2 -g -mcmodel=medany -Isrc -Ilib
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