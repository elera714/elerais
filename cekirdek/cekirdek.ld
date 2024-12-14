OUTPUT_FORMAT("elf32-i386")

SECTIONS
{
  .text 0x100000:
  {
    . = ALIGN(512);
  }
  .data :
  {
	. = ALIGN(512);
  }
  .rodata :
  {
	. = ALIGN(512);
  }  
  .bss :
  {
	. = ALIGN(512);
  }
}