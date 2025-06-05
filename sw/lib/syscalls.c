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