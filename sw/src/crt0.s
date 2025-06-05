.section .text.init
.globl _start

_start:
    # Initialize stack pointer
    la sp, _stack_top
    # Jump to main C function
    call main
    # Exit
    li a7, 93 # exit system call
    li a0, 0  # exit code
    ecall

.section .bss
.align 8
.globl _stack_top
_stack:
    .skip 4096 # 4KB stack
_stack_top: 