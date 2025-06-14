/**
 * @file simple_printf.c
 * @brief Simple printf implementation for embedded RISC-V environment
 * 
 * This provides basic printf functionality without requiring a full C library.
 * It supports basic format specifiers needed for our matrix test application.
 */

#include <stdarg.h>
#include <stdint.h>

// Forward declarations
extern int putchar(int c);

// Simple string length function
static int strlen_simple(const char* str) {
    int len = 0;
    while (str[len]) len++;
    return len;
}

// Convert unsigned integer to string
static int uint_to_str(uint32_t value, char* buffer, int base) {
    if (value == 0) {
        buffer[0] = '0';
        buffer[1] = '\0';
        return 1;
    }
    
    char digits[] = "0123456789ABCDEF";
    char temp[32];
    int i = 0;
    
    while (value > 0) {
        temp[i++] = digits[value % base];
        value /= base;
    }
    
    // Reverse the string
    int j;
    for (j = 0; j < i; j++) {
        buffer[j] = temp[i - 1 - j];
    }
    buffer[j] = '\0';
    
    return i;
}

// Convert signed integer to string
static int int_to_str(int32_t value, char* buffer, int base) {
    if (value < 0) {
        buffer[0] = '-';
        return 1 + uint_to_str(-value, buffer + 1, base);
    } else {
        return uint_to_str(value, buffer, base);
    }
}

// Simple printf implementation
int printf(const char* format, ...) {
    va_list args;
    va_start(args, format);
    
    int count = 0;
    char buffer[32];
    
    while (*format) {
        if (*format == '%') {
            format++;
            switch (*format) {
                case 'd': {
                    int value = va_arg(args, int);
                    int len = int_to_str(value, buffer, 10);
                    for (int i = 0; i < len; i++) {
                        putchar(buffer[i]);
                        count++;
                    }
                    break;
                }
                case 'u': {
                    unsigned int value = va_arg(args, unsigned int);
                    int len = uint_to_str(value, buffer, 10);
                    for (int i = 0; i < len; i++) {
                        putchar(buffer[i]);
                        count++;
                    }
                    break;
                }
                case 'x': {
                    unsigned int value = va_arg(args, unsigned int);
                    int len = uint_to_str(value, buffer, 16);
                    for (int i = 0; i < len; i++) {
                        putchar(buffer[i]);
                        count++;
                    }
                    break;
                }
                case 's': {
                    char* str = va_arg(args, char*);
                    while (*str) {
                        putchar(*str);
                        str++;
                        count++;
                    }
                    break;
                }
                case 'c': {
                    int c = va_arg(args, int);
                    putchar(c);
                    count++;
                    break;
                }
                case '.': {
                    // Handle %.1f format for simple float printing
                    if (format[1] == '1' && format[2] == 'f') {
                        format += 2; // Skip "1f"
                        double value = va_arg(args, double);
                        int int_part = (int)value;
                        int frac_part = (int)((value - int_part) * 10);
                        
                        int len = int_to_str(int_part, buffer, 10);
                        for (int i = 0; i < len; i++) {
                            putchar(buffer[i]);
                            count++;
                        }
                        putchar('.');
                        putchar('0' + frac_part);
                        count += 2;
                    }
                    break;
                }
                case '%': {
                    putchar('%');
                    count++;
                    break;
                }
                default: {
                    // Unknown format specifier, just print it
                    putchar('%');
                    putchar(*format);
                    count += 2;
                    break;
                }
            }
        } else {
            putchar(*format);
            count++;
        }
        format++;
    }
    
    va_end(args);
    return count;
} 