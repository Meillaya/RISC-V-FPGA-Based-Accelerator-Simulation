/* Simple Linker Script for Matrix Accelerator Test */

ENTRY(_start)

MEMORY
{
    ROM (rx)  : ORIGIN = 0x80000000, LENGTH = 16K
    RAM (rwx) : ORIGIN = 0x80004000, LENGTH = 16K
}

SECTIONS
{
    . = 0x80000000;
    
    .text : {
        *(.text*)
    } > ROM
    
    .data : {
        *(.data*)
    } > RAM
    
    .bss : {
        *(.bss*)
    } > RAM
    
    /* Stack grows down from end of RAM */
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
} 