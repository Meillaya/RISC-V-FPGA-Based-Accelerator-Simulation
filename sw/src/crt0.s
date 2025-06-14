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
    sw t1, 0(t0)

    # Infinite loop to wait for simulation to terminate
1:  j 1b

.section .bss
.align 8
.globl _stack_top
_stack:
    .skip 4096 # 4KB stack
_stack_top:

.section .htif
.align 8
.globl tohost
tohost:
    .skip 8 