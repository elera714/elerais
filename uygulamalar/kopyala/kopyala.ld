OUTPUT_FORMAT("elf32-i386")

SECTIONS
{
  .text 0x100:
  {
    . = ALIGN(32);
  }
  .data :
  {
    . = ALIGN(32);
  }
  .rodata :
  {
    . = ALIGN(32);
  }
  .bss :
  {
    . = ALIGN(32);
  }
}