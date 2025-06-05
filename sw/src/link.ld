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
} 