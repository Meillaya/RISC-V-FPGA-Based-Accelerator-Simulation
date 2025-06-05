# sw/Makefile

TARGET = hello
RISCV_PREFIX ?= /opt/riscv64-gnu-toolchain-elf-bin/bin/riscv64-unknown-elf-
CC = $(RISCV_PREFIX)gcc
LD = $(RISCV_PREFIX)ld

SRCS_C = src/hello.c lib/syscalls.c
SRCS_S = src/crt0.s
OBJS = $(patsubst src/%.c, build/%.o, $(SRCS_C)) $(patsubst src/%.s, build/%.o, $(SRCS_S))

CFLAGS = -march=rv64gc -mabi=lp64d -O2 -g -mcmodel=medany
LDFLAGS = -T src/link.ld -nostdlib -nostartfiles

SIMULATOR ?= spike

.PHONY: all clean run

all: build/$(TARGET)

build/$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^

build/%.o: src/%.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

build/%.o: lib/%.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

build/%.o: src/%.s
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -rf build

run: build/$(TARGET)
	$(SIMULATOR) $< 