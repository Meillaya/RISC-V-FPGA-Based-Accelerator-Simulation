#include <stddef.h>

// A simple implementation of puts for bare-metal RISC-V
// This writes to the Spike default UART address.
#define UART_BASE 0x10000000

void puts(const char *s) {
    volatile char *uart = (char *)UART_BASE;
    while (*s) {
        *uart = *s++;
    }
    *uart = '\n';
} 